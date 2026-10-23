#!/usr/bin/env node
'use strict';

/**
 * 发布数据目录分片到 cloudbase 的 `catalog` 云函数。
 *
 * 用法：
 *   TGG_CATALOG_SECRET=xxx node server/cloudbase/scripts/publish-catalog.js \
 *     job.artifacts assets/catalog/job/artifacts.json \
 *     pet.beast_spirits assets/catalog/pet/beast_spirits.json
 *
 *   # 只看体积/哈希，不真的发请求
 *   node server/cloudbase/scripts/publish-catalog.js --dry-run job.artifacts assets/catalog/job/artifacts.json
 *
 * 环境变量：
 *   TGG_CATALOG_SECRET  写密钥（必须与云函数环境变量、RLS 策略一致）
 *   CATALOG_BASE_URL    接口根地址；缺省时从 server/cloudbaserc.json 的 envId 推导
 *   CATALOG_PATH        路由前缀，默认 /catalog
 *
 * 分片文件要求顶层包含 `schemaVersion`（>=1 的整数）与 `dataVersion`（字符串）；
 * 服务端按**上传的原始字节**计算 sha256，客户端据此校验，因此不要在这里重新序列化。
 */

const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');

const KIND_RE = /^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*){1,2}$/;

/**
 * 单片字节上限。
 *
 * 平台 HTTP 访问服务对请求体有 100 KiB 硬限制（实测 102400 通过、105 KiB 返回
 * 413 EXCEED_MAX_PAYLOAD_SIZE），这里留出安全余量。
 */
const CHUNK_BYTES = 90 * 1024;

function usage(msg) {
  if (msg) console.error(`✗ ${msg}\n`);
  console.error(
    '用法: publish-catalog.js [--dry-run] [--base-url URL] <kind> <file> [<kind> <file> ...]',
  );
  process.exit(2);
}

function resolveBaseUrl(flagValue) {
  if (flagValue) return flagValue.replace(/\/$/, '');
  if (process.env.CATALOG_BASE_URL) return process.env.CATALOG_BASE_URL.replace(/\/$/, '');
  const rcPath = path.join(__dirname, '..', '..', 'cloudbaserc.json');
  const rc = JSON.parse(fs.readFileSync(rcPath, 'utf8'));
  return `https://${rc.envId}.service.tcloudbase.com`;
}

function formatBytes(n) {
  return n >= 1024 ? `${(n / 1024).toFixed(1)} KB` : `${n} B`;
}

/** 读取并校验本地分片；返回原文与元信息。 */
function loadShard(kind, file) {
  if (!KIND_RE.test(kind)) usage(`非法的 kind：${kind}（形如 job.artifacts）`);

  const abs = path.resolve(process.cwd(), file);
  if (!fs.existsSync(abs)) usage(`文件不存在：${abs}`);

  const raw = fs.readFileSync(abs, 'utf8');
  let doc;
  try {
    doc = JSON.parse(raw);
  } catch (e) {
    usage(`${file} 不是合法 JSON：${e.message}`);
  }
  if (!doc || typeof doc !== 'object' || Array.isArray(doc)) {
    usage(`${file} 顶层必须是对象`);
  }
  if (!Number.isInteger(doc.schemaVersion) || doc.schemaVersion < 1) {
    usage(`${file} 缺少 schemaVersion（>=1 的整数）`);
  }
  if (typeof doc.dataVersion !== 'string' || doc.dataVersion.length === 0) {
    usage(`${file} 缺少 dataVersion（非空字符串）`);
  }

  return {
    kind,
    raw,
    schemaVersion: doc.schemaVersion,
    dataVersion: doc.dataVersion,
    sha256: crypto.createHash('sha256').update(raw, 'utf8').digest('hex'),
    bytes: Buffer.byteLength(raw, 'utf8'),
  };
}

/**
 * 按换行边界切分（不会切断多字节字符，拼回来与原文逐字节一致）。
 * 单行超限时按码点兜底切开。
 */
function splitChunks(text, chunkBytes) {
  const chunks = [];
  let current = '';
  let currentBytes = 0;

  const pushChar = (ch) => {
    const bytes = Buffer.byteLength(ch, 'utf8');
    if (currentBytes + bytes > chunkBytes && current.length > 0) {
      chunks.push(current);
      current = '';
      currentBytes = 0;
    }
    current += ch;
    currentBytes += bytes;
  };

  for (const line of text.split(/(?<=\n)/)) {
    const lineBytes = Buffer.byteLength(line, 'utf8');
    if (currentBytes + lineBytes > chunkBytes && current.length > 0) {
      chunks.push(current);
      current = '';
      currentBytes = 0;
    }
    if (lineBytes > chunkBytes) {
      for (const ch of line) pushChar(ch);
    } else {
      current += line;
      currentBytes += lineBytes;
    }
  }
  if (current.length > 0) chunks.push(current);
  return chunks;
}

async function publish(shard, baseUrl, secret) {
  const url = `${baseUrl}${process.env.CATALOG_PATH || '/catalog'}/${shard.kind}.json`;
  const chunks = splitChunks(shard.raw, CHUNK_BYTES);
  const total = chunks.length;

  let lastEtag = null;
  for (let i = 0; i < total; i += 1) {
    const target = total === 1 ? url : `${url}?part=${i + 1}&total=${total}`;
    const res = await fetch(target, {
      method: 'PUT',
      headers: {
        'content-type': 'application/json; charset=utf-8',
        'x-catalog-token': secret,
      },
      body: chunks[i],
    });

    if (res.status !== 204 && res.status !== 202) {
      const text = (await res.text()).slice(0, 300);
      return { ok: false, url, status: res.status, text, part: i + 1, total };
    }
    if (res.status === 204) lastEtag = res.headers.get('etag');
  }

  if (total > 1) {
    console.log(`   分 ${total} 片上传（平台请求体上限 100 KiB）`);
  }

  // 服务端对「拼接后的原文」算 sha256，与本地一致才说明分片没有错位
  const expected = `"${shard.sha256}"`;
  if (lastEtag && lastEtag !== expected) {
    return {
      ok: false,
      url,
      status: 500,
      text: `服务端 etag ${lastEtag} 与本地 sha256 ${expected} 不一致（分片组装异常）`,
      total,
    };
  }

  return { ok: true, url, etag: lastEtag, total };
}

function explainFailure(status, text) {
  if (status === 401) return '密钥不匹配：检查 TGG_CATALOG_SECRET 是否与云函数环境变量一致';
  if (status === 413) return '分片超过 4MB 上限：请拆分分片';
  if (text.includes('not_configured')) return '云函数缺环境变量 TGG_CATALOG_SECRET';
  if (text.includes('db_error')) return '数据库拒绝写入：RLS 写策略未建或密钥不一致（set-catalog-secret.sh）';
  if (text.includes('db_unreachable')) return '数据通道网络层不通：稍后重试或检查平台状态';
  return text || `HTTP ${status}`;
}

async function main() {
  const args = process.argv.slice(2);
  const dryRun = args.includes('--dry-run');
  const baseFlagIndex = args.indexOf('--base-url');
  const baseFlag = baseFlagIndex >= 0 ? args[baseFlagIndex + 1] : null;

  const pairs = args.filter(
    (a, i) =>
      a !== '--dry-run' &&
      a !== '--base-url' &&
      !(baseFlagIndex >= 0 && i === baseFlagIndex + 1),
  );
  if (pairs.length === 0 || pairs.length % 2 !== 0) usage('需要成对的 <kind> <file>');

  const shards = [];
  for (let i = 0; i < pairs.length; i += 2) {
    shards.push(loadShard(pairs[i], pairs[i + 1]));
  }

  const baseUrl = resolveBaseUrl(baseFlag);
  const secret = process.env.TGG_CATALOG_SECRET;

  if (!dryRun && !secret) {
    console.error('✗ 缺少环境变量 TGG_CATALOG_SECRET（发布是写操作，必须带密钥）');
    process.exit(2);
  }

  let failed = 0;
  for (const shard of shards) {
    console.log(
      `▶ ${shard.kind}  ${formatBytes(shard.bytes)}  dataVersion=${shard.dataVersion}  schema=${shard.schemaVersion}`,
    );
    console.log(`   sha256 ${shard.sha256}`);

    if (dryRun) {
      console.log('   （dry-run：未发送）');
      continue;
    }

    const result = await publish(shard, baseUrl, secret);
    if (result.ok) {
      console.log(`   PUT ${result.url} → 204${result.total > 1 ? `（${result.total} 片）` : ''}`);
      console.log(`   etag ${result.etag || '(未返回)'}`);
    } else {
      failed += 1;
      console.error(`   ✗ PUT ${result.url} → ${result.status}${result.part ? `（第 ${result.part}/${result.total} 片）` : ''}`);
      console.error(`     ${explainFailure(result.status, result.text)}`);
    }
  }

  if (failed > 0) {
    console.error(`\n${failed} 个分片发布失败 ❌`);
    process.exit(1);
  }
  console.log(dryRun ? '\n校验通过（未发布）' : '\n发布完成 ✅');
}

main().catch((e) => {
  console.error('✗ 发布异常:', e.message);
  process.exit(1);
});
