'use strict';

/**
 * 数据目录（catalog）—— 纯请求处理逻辑（不依赖任何云 SDK，可本地单测）。
 *
 * 服务端是**哑存储**：按分片（kind）存取一段 JSON 原文，不理解业务语义。
 * 分片内容由客户端解析，服务端只保证「原样返回 + 哈希一致」。
 *
 * 路由（HTTP 访问服务会把 `/catalog` 前缀留在 path 里，解析见 index.js）：
 *   GET    /catalog/manifest.json   → 全部分片的版本与哈希清单
 *   GET    /catalog/{kind}.json     → 分片原文（支持 If-None-Match → 304）
 *   PUT    /catalog/{kind}.json     → 发布/覆盖（需 x-catalog-token）
 *   DELETE /catalog/{kind}.json     → 下线（需 x-catalog-token，幂等）
 *   OPTIONS                         → 204（Web 端跨域预检）
 */

const crypto = require('node:crypto');

/** 客户端可解析的 schema 主版本；结构不兼容地升级时递增。 */
const SCHEMA_VERSION = 1;

/** 单分片上限：云函数 HTTP 响应体上限约 6MB，留足余量。 */
const MAX_BODY_BYTES = 4 * 1024 * 1024;

/**
 * 分片上传的最大片数。
 *
 * 平台 HTTP 访问服务对**请求体**有 100 KiB 硬限制（实测 102400 通过、105 KiB 返回
 * 413 EXCEED_MAX_PAYLOAD_SIZE），大分片只能拆开传。48 片 × 90KiB 已覆盖 4MB 上限。
 */
const MAX_PARTS = 48;

/** 分片标识：`job.artifacts` / `pet.beast_spirits`（全小写，避免大小写歧义）。 */
const KIND_RE = /^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*){1,2}$/;
const KIND_MAX_LEN = 64;

/** 内容版本：只做形状约束，便于客户端日志与排查。 */
const DATA_VERSION_RE = /^[A-Za-z0-9._+-]{1,64}$/;

/** 管理写接口的请求头（值 = 云函数环境变量 TGG_CATALOG_SECRET）。 */
const TOKEN_HEADER = 'x-catalog-token';

const BASE_HEADERS = {
  'content-type': 'application/json; charset=utf-8',
  // 公开只读数据，允许任意来源（Web 端必需）
  'access-control-allow-origin': '*',
  'access-control-allow-methods': 'GET,PUT,DELETE,OPTIONS',
  'access-control-allow-headers': `content-type,${TOKEN_HEADER}`,
  // 浏览器默认读不到 ETag，必须显式暴露，否则 Web 端无法做 304 协商
  'access-control-expose-headers': 'etag',
};

/**
 * @param {{store: {
 *   list(): Promise<Array<{kind: string, schemaVersion: number, dataVersion: string, sha256: string, bytes: number, updatedAt: string}>>,
 *   get(kind: string): Promise<{body: string, sha256: string}|null>,
 *   put(kind: string, rec: {schemaVersion: number, dataVersion: string, body: string, sha256: string, bytes: number}): Promise<void>,
 *   remove(kind: string): Promise<void>,
 * }, secret?: () => string|undefined, maxBytes?: number}} deps
 * @returns {(req: {method?: string, kind?: string|null, ifNoneMatch?: string|null,
 *   token?: string|null, raw?: string|null, doc?: object|null}) =>
 *   Promise<{status: number, headers: object, text: string|null}>}
 */
function createHandler({ store, secret, maxBytes = MAX_BODY_BYTES }) {
  const readSecret = secret || (() => process.env.TGG_CATALOG_SECRET);

  return async function handle(req) {
    const r = req || {};
    const method = String(r.method || 'GET').toUpperCase();

    if (method === 'OPTIONS') return { status: 204, headers: BASE_HEADERS, text: null };

    const target = parseTarget(r.kind);
    if (target.invalid) {
      return fail(400, 'invalid_kind', 'kind 形如 job.artifacts（小写，1~3 段，用点分隔）');
    }

    if (method === 'GET') {
      return target.kind === null
        ? getManifest(store, r.ifNoneMatch)
        : getFile(store, target.kind, r.ifNoneMatch);
    }

    if (method === 'PUT' || method === 'DELETE') {
      const denied = authorize(r.token, readSecret());
      if (denied) return denied;
      if (target.kind === null) {
        return fail(400, 'invalid_kind', '写操作必须指定具体分片，例如 /catalog/job.artifacts.json');
      }
      return method === 'PUT'
        ? putFile(store, target.kind, r, maxBytes)
        : removeFile(store, target.kind);
    }

    return fail(405, 'method_not_allowed', `不支持的方法：${method}`);
  };
}

/** 把 `manifest` / `manifest.json` / 空 都归一化为「无分片」。 */
function parseTarget(kind) {
  if (kind === null || kind === undefined) return { kind: null };
  const k = String(kind).trim();
  if (k === '') return { kind: null };
  const lower = k.toLowerCase();
  if (lower === 'manifest' || lower === 'manifest.json') return { kind: null };
  if (lower.length > KIND_MAX_LEN || !KIND_RE.test(lower)) return { kind: null, invalid: true };
  return { kind: lower };
}

async function getManifest(store, ifNoneMatch) {
  const rows = await store.list();
  const files = rows
    .map((r) => ({
      kind: r.kind,
      schemaVersion: r.schemaVersion,
      dataVersion: r.dataVersion,
      sha256: r.sha256,
      bytes: r.bytes,
      updatedAt: r.updatedAt,
    }))
    .sort((a, b) => (a.kind < b.kind ? -1 : a.kind > b.kind ? 1 : 0));

  const dataVersion = files.reduce((m, f) => (f.dataVersion > m ? f.dataVersion : m), '');
  const etag = manifestEtag(files);
  const headers = { ...BASE_HEADERS, 'cache-control': 'public, max-age=300', etag };

  if (etagMatches(ifNoneMatch, etag)) return { status: 304, headers, text: null };

  return {
    status: 200,
    headers,
    text: JSON.stringify({ schemaVersion: SCHEMA_VERSION, dataVersion, files }, null, 2),
  };
}

async function getFile(store, kind, ifNoneMatch) {
  const rec = await store.get(kind);
  if (!rec) return fail(404, 'not_found', `分片 ${kind} 尚未发布`);

  const etag = `"${rec.sha256}"`;
  const headers = { ...BASE_HEADERS, 'cache-control': 'public, max-age=86400', etag };

  if (etagMatches(ifNoneMatch, etag)) return { status: 304, headers, text: null };

  // 原文返回：sha256 由同一段字节算出，客户端校验才能逐字节对上
  return { status: 200, headers, text: rec.body };
}

async function putFile(store, kind, req, maxBytes) {
  const raw = req.raw;
  if (typeof raw !== 'string' || raw.trim() === '') {
    return fail(400, 'invalid_body', '请求体必须是非空 JSON 文本');
  }

  const bytes = Buffer.byteLength(raw, 'utf8');
  if (bytes > maxBytes) {
    return fail(413, 'payload_too_large', `分片超过 ${maxBytes} 字节（当前 ${bytes}）`);
  }

  // 带 part/total 就是「分片上传」：中间片只落暂存表，最后一片才组装成完整文档
  if (req.part != null || req.total != null) {
    return putPart(store, kind, raw, req.part, req.total, maxBytes);
  }

  const doc = req.doc;
  const invalid = validateDoc(doc);
  if (invalid) return invalid;

  return commitFile(store, kind, raw, doc);
}

/**
 * 分片上传（大分片专用）：
 *   PUT /catalog/{kind}.json?part=1&total=3   ← 依次上传
 * 每片仍是纯文本片段，**按顺序直接拼接即为原文**（发布脚本按换行边界切分，
 * 不会切断多字节字符），因此 sha256 与单次上传完全一致。
 */
async function putPart(store, kind, raw, part, total, maxBytes) {
  const partNo = Number(part);
  const partTotal = Number(total);
  if (
    !Number.isInteger(partNo) ||
    !Number.isInteger(partTotal) ||
    partNo < 1 ||
    partTotal < 1 ||
    partNo > partTotal ||
    partTotal > MAX_PARTS
  ) {
    return fail(
      400,
      'invalid_part',
      `part/total 必须是整数且 1 <= part <= total <= ${MAX_PARTS}`,
    );
  }

  const assembled = await store.putPart(kind, partNo, partTotal, raw);
  if (assembled === null) {
    // 还没集齐：202 + 进度头，客户端据此继续传下一片
    return {
      status: 202,
      headers: { ...BASE_HEADERS, 'cache-control': 'no-store', 'x-catalog-complete': '0' },
      text: null,
    };
  }

  const bytes = Buffer.byteLength(assembled, 'utf8');
  if (bytes > maxBytes) {
    await store.clearParts(kind);
    return fail(413, 'payload_too_large', `拼接后超过 ${maxBytes} 字节（当前 ${bytes}）`);
  }

  let doc = null;
  try {
    doc = JSON.parse(assembled);
  } catch (_) {
    doc = null;
  }
  const invalid = validateDoc(doc);
  if (invalid) {
    await store.clearParts(kind);
    return invalid;
  }

  const result = await commitFile(store, kind, assembled, doc);
  await store.clearParts(kind);
  return result;
}

/** 校验文档元信息；合法返回 null，否则返回错误响应。 */
function validateDoc(doc) {
  if (!doc || typeof doc !== 'object' || Array.isArray(doc)) {
    return fail(400, 'invalid_body', '请求体必须是 JSON 对象');
  }
  const schemaVersion = Number(doc.schemaVersion);
  if (!Number.isInteger(schemaVersion) || schemaVersion < 1) {
    return fail(400, 'invalid_schema_version', 'schemaVersion 必须是 >= 1 的整数');
  }
  const dataVersion = doc.dataVersion;
  if (typeof dataVersion !== 'string' || !DATA_VERSION_RE.test(dataVersion)) {
    return fail(400, 'invalid_data_version', 'dataVersion 必须是 1~64 位的 [A-Za-z0-9._+-]');
  }
  return null;
}

async function commitFile(store, kind, raw, doc) {
  const sha256 = sha256Of(raw);
  await store.put(kind, {
    schemaVersion: Number(doc.schemaVersion),
    dataVersion: doc.dataVersion,
    body: raw,
    sha256,
    bytes: Buffer.byteLength(raw, 'utf8'),
  });

  return {
    status: 204,
    headers: { ...BASE_HEADERS, 'cache-control': 'no-store', etag: `"${sha256}"` },
    text: null,
  };
}

async function removeFile(store, kind) {
  await store.remove(kind);
  return { status: 204, headers: { ...BASE_HEADERS, 'cache-control': 'no-store' }, text: null };
}

/** 密钥来自云函数环境变量；缺失时明确报错而不是默默放行。 */
function authorize(token, expected) {
  if (!expected) {
    return fail(500, 'not_configured', '云函数缺少环境变量 TGG_CATALOG_SECRET', {
      missing: ['TGG_CATALOG_SECRET'],
    });
  }
  if (typeof token !== 'string' || !safeEqual(token, expected)) {
    return fail(401, 'unauthorized', `缺少或错误的 ${TOKEN_HEADER} 请求头`);
  }
  return null;
}

/** 定长比较，避免逐位短路泄露长度/前缀信息。 */
function safeEqual(a, b) {
  const ba = Buffer.from(String(a), 'utf8');
  const bb = Buffer.from(String(b), 'utf8');
  return ba.length === bb.length && crypto.timingSafeEqual(ba, bb);
}

function sha256Of(text) {
  return crypto.createHash('sha256').update(text, 'utf8').digest('hex');
}

/**
 * manifest 的 ETag：只由各分片的 kind + schemaVersion + 哈希决定。
 * 这样「换了哪个分片」才变，「重新发布同样内容」不变（客户端拿 304，零流量）。
 */
function manifestEtag(files) {
  const h = crypto.createHash('sha256');
  for (const f of files) h.update(`${f.kind}:${f.schemaVersion}:${f.sha256};`, 'utf8');
  return `"${h.digest('hex').slice(0, 32)}"`;
}

/** 支持 `If-None-Match: "x"` / `W/"x"` / 逗号列表 / `*`。 */
function etagMatches(header, etag) {
  if (!header) return false;
  const wanted = String(etag).replace(/^W\//, '');
  return String(header)
    .split(',')
    .map((t) => t.trim().replace(/^W\//, ''))
    .some((t) => t === '*' || t === wanted);
}

function fail(status, error, message, extra) {
  return {
    status,
    headers: { ...BASE_HEADERS, 'cache-control': 'no-store' },
    text: JSON.stringify(Object.assign({ error, message }, extra || {})),
  };
}

module.exports = {
  createHandler,
  parseTarget,
  etagMatches,
  manifestEtag,
  sha256Of,
  MAX_BODY_BYTES,
  MAX_PARTS,
  KIND_RE,
  TOKEN_HEADER,
  BASE_HEADERS,
};
