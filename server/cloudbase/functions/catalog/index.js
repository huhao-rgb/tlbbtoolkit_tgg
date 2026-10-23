'use strict';

/**
 * 腾讯云开发（CloudBase）云函数入口：把 HTTP 触发事件归一化后交给 handler。
 *
 * 存储层与 `reg-sync` 一致：**不使用数据库连接串**，而是走平台的**数据通道**
 * （PostgREST 风格 HTTP 接口 `/v1/rdb/rest`），以函数自身身份访问 PostgreSQL。
 *
 * 授权模型：
 *   · 读：公开。RLS 上有 `tgg_catalog_read`（USING true），匿名也能 SELECT；
 *   · 写：云函数先校验请求头 `x-catalog-token`，再带 `x-tgg-catalog` 访问数据通道，
 *     由 `tgg_catalog_gate` 策略放行。两个值都是环境变量 `TGG_CATALOG_SECRET`。
 *
 * 部署前需准备：
 *   1. 表 `public.catalog_files` + GRANT/RLS（见 server/cloudbase/migrations/）；
 *   2. 云函数环境变量 `TGG_CATALOG_SECRET`；
 *   3. RLS 写策略（scripts/set-catalog-secret.sh 注入，**密钥不进仓库**）；
 *   4. HTTP 访问路由 `/catalog` 指向本函数。
 */

const { createHandler, BASE_HEADERS } = require('./handler');

/** 数据通道里这张表的路径（schema 由 Accept-Profile 指定）。 */
const TABLE_PATH = '/catalog_files';
/** 分片上传暂存表。 */
const PARTS_TABLE_PATH = '/catalog_upload_parts';
const TABLE_SCHEMA = 'public';
/** 与 RLS 写策略配套的通道密钥头名。 */
const CHANNEL_HEADER = 'x-tgg-catalog';
/** 单次请求最长等待，必须小于云函数超时（5s），以便给出可诊断的报错。 */
const REQUEST_TIMEOUT_MS = 3000;
const REQUIRED_ENV = ['TGG_CATALOG_SECRET'];

/**
 * 云 SDK 延迟加载：本地单测会替换掉 [_deps]，不需要（也不应该要求）
 * 安装 `@cloudbase/node-sdk`；云端由 `installDependency: true` 负责安装。
 */
let _cloudbase = null;
function cloudbaseClient() {
  if (!_cloudbase) {
    // eslint-disable-next-line global-require
    const tcb = require('@cloudbase/node-sdk');
    // 用「当前环境」初始化：凭据由运行时自动注入，无需任何配置
    _cloudbase = tcb.init({
      env: tcb.SYMBOL_CURRENT_ENV || Symbol.for('SYMBOL_CURRENT_ENV'),
    });
  }
  return _cloudbase;
}

/** 通道不可达（网络层）：DNS/连接/超时等。 */
class ChannelUnreachableError extends Error {
  constructor(message, code) {
    super(message);
    this.name = 'ChannelUnreachableError';
    this.code = code;
  }
}

/** 连接参数缺失。只在**真正访问数据库**时抛出。 */
class DbNotConfiguredError extends Error {
  constructor(missing) {
    super(`缺少数据库连接环境变量: ${missing.join(', ')}`);
    this.name = 'DbNotConfiguredError';
    this.missing = missing;
  }
}

/**
 * 校验配置。
 *
 * 放在 store 里而不是函数入口：这样 OPTIONS 预检、参数校验（400）、
 * 鉴权失败（401）都不依赖数据库配置也能给出正确状态码。
 *
 * **读操作不需要密钥**：RLS 的 SELECT 策略是公开的，只要平台身份能换到
 * access_token 就能读。密钥只在写操作（PATCH/POST/DELETE）时用于通过
 * `tgg_catalog_gate` 策略 —— 因此未配置密钥时「读能用、写报错」，
 * 而不是整个接口全挂。
 */
function assertConfigured({ write = false } = {}) {
  const required = write ? REQUIRED_ENV : [];
  const missing = required.filter((k) => !process.env[k]);
  if (missing.length > 0) throw new DbNotConfiguredError(missing);
}

/** 可注入依赖，便于单测（生产用官方 SDK + 全局 fetch）。 */
const deps = {
  getBaseUrl() {
    return cloudbaseClient()
      .rdb({ instance: 'default', database: TABLE_SCHEMA })
      .url.replace(/\/$/, '');
  },
  async getAccessToken() {
    const cred = await cloudbaseClient().auth().getClientCredential();
    return {
      token: cred && cred.access_token,
      expiresInSeconds: Number(cred && cred.expires_in) || 0,
    };
  },
  fetchImpl: (url, init) => fetch(url, init),
};

/** 通道凭据缓存：token 有有效期，避免每次请求都去换一次。 */
const channelCache = { baseUrl: null, token: null, expiresAt: 0 };

async function channelHeaders({ write = false } = {}) {
  assertConfigured({ write });
  const now = Date.now();
  if (!channelCache.baseUrl) channelCache.baseUrl = deps.getBaseUrl();
  if (!channelCache.token || now >= channelCache.expiresAt) {
    const { token, expiresInSeconds } = await deps.getAccessToken();
    channelCache.token = token;
    // 提前 60s 过期，避免踩到边界
    channelCache.expiresAt =
      expiresInSeconds > 60 ? now + (expiresInSeconds - 60) * 1000 : now;
  }
  return {
    Authorization: `Bearer ${channelCache.token}`,
    'Content-Type': 'application/json',
    'Accept-Profile': TABLE_SCHEMA,
    'Content-Profile': TABLE_SCHEMA,
    // 无此头时 RLS 的写策略不匹配 → 写 0 行
    [CHANNEL_HEADER]: process.env.TGG_CATALOG_SECRET,
  };
}

/** 通道返回的错误码（如 DATABASE_23505），便于归类与排查。 */
class ChannelError extends Error {
  constructor(status, code, message) {
    super(`通道返回 ${status} ${code}: ${message}`);
    this.name = 'ChannelError';
    this.code = code || `HTTP_${status}`;
    this.status = status;
  }
}

/** 解析响应体里的行数组（PostgREST 返回数组；错误返回对象）。 */
function parseRows(text) {
  try {
    const data = JSON.parse(text);
    return Array.isArray(data) ? data : [];
  } catch (_) {
    return [];
  }
}

/**
 * 发一次数据通道请求。
 *
 * 用 `AbortSignal.timeout` 限时：超时（网络被黑洞吞掉时）必须能在函数
 * 超时前抛出来，否则外部只能看到一个不透明的 504，无法定位。
 */
async function request(method, query, body, options = {}) {
  // 默认只有写操作需要密钥；`catalog_upload_parts` 没有公开读策略，
  // 它的 GET 也要带头（options.secret = true）。
  const needsSecret = options.secret !== undefined ? options.secret : method !== 'GET';
  const headers = await channelHeaders({ write: needsSecret });
  if (method !== 'GET') headers.Prefer = 'return=representation';

  let res;
  try {
    const tablePath = options.table || TABLE_PATH;
    res = await deps.fetchImpl(`${channelCache.baseUrl}${tablePath}${query}`, {
      method,
      headers,
      body: body === undefined ? undefined : JSON.stringify(body),
      signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
    });
  } catch (e) {
    throw new ChannelUnreachableError(
      `数据通道不可达: ${e.message}`,
      (e && e.cause && e.cause.code) || e.code || 'CHANNEL_UNREACHABLE',
    );
  }

  const text = await res.text();
  if (res.status >= 400) {
    let code = null;
    let message = text.slice(0, 200);
    try {
      const parsed = JSON.parse(text);
      code = parsed.code || null;
      message = parsed.message || message;
    } catch (_) {
      /* 非 JSON 错误体，保留原文 */
    }
    throw new ChannelError(res.status, code, message);
  }
  return parseRows(text);
}

const kindFilter = (kind) => `kind=eq.${encodeURIComponent(kind)}`;
const COLUMNS = 'kind,schema_version,data_version,sha256,bytes,updated_at';

const toItem = (r) => ({
  kind: r.kind,
  schemaVersion: r.schema_version,
  dataVersion: r.data_version,
  sha256: r.sha256,
  bytes: r.bytes,
  updatedAt: r.updated_at,
});

/**
 * PostgreSQL 实现（走平台数据通道，不用连接串）。
 *
 * put 用「先 PATCH，0 行再 POST」实现 upsert：PostgREST 的
 * `on_conflict + resolution=merge-duplicates` 依赖表上暴露的唯一约束，
 * 两步法在所有版本上都成立，且发布是低频人工操作，多一次往返无所谓。
 */
const store = {
  async list() {
    const rows = await request('GET', `?select=${COLUMNS}&order=kind.asc`);
    return rows.map(toItem);
  },

  async get(kind) {
    const rows = await request(
      'GET',
      `?select=body,sha256&${kindFilter(kind)}&limit=1`,
    );
    return rows[0] ? { body: rows[0].body, sha256: rows[0].sha256 } : null;
  },

  async put(kind, rec) {
    const row = {
      schema_version: rec.schemaVersion,
      data_version: rec.dataVersion,
      body: rec.body,
      sha256: rec.sha256,
      bytes: rec.bytes,
      updated_at: new Date().toISOString(),
    };
    const updated = await request('PATCH', `?${kindFilter(kind)}`, row);
    if (updated.length > 0) return;

    try {
      await request('POST', '', Object.assign({ kind }, row));
    } catch (e) {
      // 并发发布撞上主键：退化为一次更新即可
      if (e instanceof ChannelError && e.status === 409) {
        await request('PATCH', `?${kindFilter(kind)}`, row);
        return;
      }
      throw e;
    }
  },

  async remove(kind) {
    // 幂等：不存在的分片删除影响 0 行，同样是成功
    await request('DELETE', `?${kindFilter(kind)}`);
  },

  /**
   * 保存一个上传分片；集齐后返回**按序拼接**的完整原文，否则返回 null。
   *
   * 拼接发生在服务端：客户端只负责按换行边界切开，因此拼回来的字节与
   * 单次上传完全一致，sha256 不受影响。
   */
  async putPart(kind, part, total, body) {
    const row = { total, body, updated_at: new Date().toISOString() };
    const updated = await request(
      'PATCH',
      `?${kindFilter(kind)}&part=eq.${part}`,
      row,
      { table: PARTS_TABLE_PATH, secret: true },
    );
    if (updated.length === 0) {
      try {
        await request(
          'POST',
          '',
          Object.assign({ kind, part }, row),
          { table: PARTS_TABLE_PATH, secret: true },
        );
      } catch (e) {
        // 并发/重传撞主键：退化为一次更新
        if (e instanceof ChannelError && e.status === 409) {
          await request(
            'PATCH',
            `?${kindFilter(kind)}&part=eq.${part}`,
            row,
            { table: PARTS_TABLE_PATH, secret: true },
          );
        } else {
          throw e;
        }
      }
    }

    const rows = await request(
      'GET',
      `?select=part,body&${kindFilter(kind)}&order=part.asc`,
      undefined,
      { table: PARTS_TABLE_PATH, secret: true },
    );
    if (rows.length !== total) return null;
    for (let i = 0; i < rows.length; i += 1) {
      if (Number(rows[i].part) !== i + 1) return null; // 序号不连续，等下一片
    }
    return rows.map((r) => r.body).join('');
  },

  /** 清掉某 kind 的暂存分片（组装成功或校验失败后调用）。 */
  async clearParts(kind) {
    await request('DELETE', `?${kindFilter(kind)}`, undefined, {
      table: PARTS_TABLE_PATH,
      secret: true,
    });
  },
};

/** 从路径里取分片标识：`/catalog/job.artifacts.json` → `job.artifacts`。 */
function parsePathKind(path) {
  if (typeof path !== 'string' || path === '') return null;
  const clean = path.split('?')[0];
  const m = clean.match(/\/([A-Za-z0-9_.-]+)\.json$/);
  if (m) return m[1];
  const seg = clean.split('/').filter(Boolean).pop();
  if (!seg || seg === 'catalog' || seg === 'manifest') return null;
  return seg;
}

/** 大小写不敏感地取请求头。 */
function headerValue(headers, name) {
  if (!headers || typeof headers !== 'object') return null;
  const lower = name.toLowerCase();
  for (const k of Object.keys(headers)) {
    if (k.toLowerCase() === lower) return headers[k];
  }
  return null;
}

/**
 * 把云函数的 HTTP 事件归一化为 {@link createHandler} 的入参。
 *
 * 兼容几种常见形态（不同触发器/网关给的字段名不一）：
 * - `httpMethod` / `method` / `requestContext.httpMethod`
 * - `path` / `pathParameters.kind` / `queryStringParameters.kind`
 * - `body` 为字符串、base64、或已解析的对象
 */
function normalizeHttpEvent(event) {
  const e = event || {};
  const method = String(
    e.httpMethod ||
      e.method ||
      (e.requestContext && e.requestContext.httpMethod) ||
      'GET',
  ).toUpperCase();

  const qs = e.queryStringParameters || e.query || {};
  const kind =
    (e.pathParameters && e.pathParameters.kind) ||
    qs.kind ||
    parsePathKind(e.path);

  const headers = e.headers || {};
  const token = headerValue(headers, 'x-catalog-token');
  const part = toInt(qs.part);
  const total = toInt(qs.total);

  let raw = null;
  if (typeof e.body === 'string' && e.body.length > 0) {
    raw = e.isBase64Encoded ? Buffer.from(e.body, 'base64').toString('utf8') : e.body;
  } else if (e.body && typeof e.body === 'object') {
    raw = JSON.stringify(e.body);
  }

  let doc = null;
  if (raw !== null) {
    try {
      const parsed = JSON.parse(raw);
      doc = parsed && typeof parsed === 'object' ? parsed : null;
    } catch (_) {
      doc = null; // 交给 handler 报 400 invalid_body
    }
  }

  return {
    method,
    kind: kind || null,
    ifNoneMatch: headerValue(headers, 'if-none-match'),
    token: token || null,
    part,
    total,
    raw,
    doc,
  };
}

/** query 参数可能是字符串或数组；非数字一律返回 null。 */
function toInt(value) {
  if (Array.isArray(value)) value = value[0];
  if (typeof value === 'number' && Number.isInteger(value)) return value;
  if (typeof value !== 'string' || value.trim() === '') return null;
  const n = Number(value);
  return Number.isInteger(n) ? n : null;
}

/** 连接层错误码（fetch 在 socket 层抛出）。 */
const CONNECT_ERROR_CODES = new Set([
  'ETIMEDOUT',
  'ECONNREFUSED',
  'ENOTFOUND',
  'EAI_AGAIN',
  'EHOSTUNREACH',
  'ENETUNREACH',
  'ECONNRESET',
  'EPIPE',
  'UND_ERR_CONNECT_TIMEOUT',
  'UND_ERR_SOCKET',
  'TimeoutError',
  'ABORT_ERR',
]);

/**
 * 把数据库错误归类成「可诊断但不泄密」的响应：**只回错误码**。
 * 详细错误仍只进云函数日志（私有）。
 */
function classifyDbError(e) {
  if (e instanceof DbNotConfiguredError) return null;
  const code = (e && e.code) || '';
  const message = String((e && e.message) || '');
  if (
    e instanceof ChannelUnreachableError ||
    CONNECT_ERROR_CODES.has(code) ||
    /fetch failed|aborted/i.test(`${code} ${message}`)
  ) {
    return {
      statusCode: 503,
      body: { error: 'db_unreachable', code: code || 'CHANNEL_UNREACHABLE' },
    };
  }
  if (e instanceof ChannelError) {
    return { statusCode: 500, body: { error: 'db_error', code } };
  }
  return null;
}

const handle = createHandler({ store });

exports.main = async (event) => {
  let result;
  try {
    result = await handle(normalizeHttpEvent(event));
  } catch (e) {
    if (e instanceof DbNotConfiguredError) {
      console.error('catalog 缺少数据库连接环境变量:', e.missing.join(', '));
      return respond(500, { error: 'db_not_configured', missing: e.missing }, BASE_HEADERS);
    }
    const classified = classifyDbError(e);
    if (classified) {
      console.error(
        'catalog 数据库错误:',
        classified.body.error,
        classified.body.code,
        e.message,
      );
      return respond(classified.statusCode, classified.body, BASE_HEADERS);
    }
    console.error('catalog 处理失败:', e);
    return respond(500, { error: 'internal_error' }, BASE_HEADERS);
  }

  return {
    statusCode: result.status,
    headers: result.headers,
    body: result.text === null ? '' : result.text,
  };
};

function respond(statusCode, body, headers) {
  return { statusCode, headers, body: JSON.stringify(body) };
}

// 便于本地复用/测试
exports.normalizeHttpEvent = normalizeHttpEvent;
exports.parsePathKind = parsePathKind;
exports.classifyDbError = classifyDbError;
exports._store = store;
exports._deps = deps;
exports.DbNotConfiguredError = DbNotConfiguredError;
exports.ChannelError = ChannelError;
exports.ChannelUnreachableError = ChannelUnreachableError;
