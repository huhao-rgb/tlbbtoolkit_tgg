'use strict';

/**
 * 腾讯云开发（CloudBase）云函数入口：把 HTTP 触发事件归一化后交给 handler。
 *
 * 存储层**不使用数据库连接串**，而是走平台的**数据通道**
 * （PostgREST 风格 HTTP 接口 `/v1/rdb/rest`），以**函数自身身份**访问
 * PostgreSQL：凭据由运行时自动注入（`TENCENTCLOUD_*` + 环境上下文），
 * 无需 PGHOST/账号/密码，也无需把数据库开到公网。
 *
 * 授权模型（重要）：该通道里的请求身份是 PostgREST 的 `anon` 角色，
 * 因此表上同时启用了 **RLS**，策略只放通带 `x-tgg-sync` 密钥头的请求：
 *
 *   anon  → GRANT SELECT/INSERT/UPDATE/DELETE + RLS 策略校验密钥头
 *   无密钥头的外部请求 → 读到 0 行、写 0 行（实测验证过）
 *
 * 部署前需准备：
 *   1. 表 `public.reg_snapshots` + 上述 GRANT / RLS 策略（见
 *      server/cloudbase/migrations/ 与 README「数据通道」一节）；
 *   2. 云函数环境变量 `TGG_SYNC_SECRET`（= RLS 策略里比对的通道密钥，
 *      在控制台填写；**不要把密钥写进代码或仓库**）；
 *   3. HTTP 访问路由 `/reg` 指向本函数（见 server/cloudbase/README.md）。
 */

const { createHandler, JSON_HEADERS } = require('./handler');

/** 数据通道里这张表的路径（schema 由 Accept-Profile 指定）。 */
const TABLE_PATH = '/reg_snapshots';
const TABLE_SCHEMA = 'public';
/** 与 RLS 策略配套的通道密钥头名。 */
const CHANNEL_HEADER = 'x-tgg-sync';
/** 单次请求最长等待，必须小于云函数超时（5s），以便给出可诊断的报错。 */
const REQUEST_TIMEOUT_MS = 3000;

/**
 * 需要的配置；缺任何一个都给出可操作的报错。
 *
 * 现在只需要通道密钥：数据库连接信息由平台注入，不再需要 PGHOST 等。
 */
const REQUIRED_ENV = ['TGG_SYNC_SECRET'];

const tcb = require('@cloudbase/node-sdk');

/** 用「当前环境」初始化：凭据由运行时自动注入，无需任何配置。 */
const cloudbase = tcb.init({
  env: tcb.SYMBOL_CURRENT_ENV || Symbol.for('SYMBOL_CURRENT_ENV'),
});

/** 通道不可达（网络层）：DNS/连接/超时等。 */
class ChannelUnreachableError extends Error {
  constructor(message, code) {
    super(message);
    this.name = 'ChannelUnreachableError';
    this.code = code;
  }
}

/** 连接参数缺失。只在**真正访问数据库**时抛出，见 assertConfigured。 */
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
 * 刻意放在 store 的每个方法里、而不是函数入口：这样 CORS 预检（OPTIONS）
 * 与参数校验（400 分支）不依赖通道配置也能正常工作，
 * 排查问题时「哪些功能已经通了」一目了然。
 */
function assertConfigured() {
  const missing = REQUIRED_ENV.filter((k) => !process.env[k]);
  if (missing.length > 0) throw new DbNotConfiguredError(missing);
}

/**
 * 可注入依赖，便于单测（生产用官方 SDK + 全局 fetch）。
 * 用函数自身身份换 access_token、并取数据通道的 baseUrl。
 */
const deps = {
  getBaseUrl() {
    return cloudbase
      .rdb({ instance: 'default', database: TABLE_SCHEMA })
      .url.replace(/\/$/, '');
  },
  async getAccessToken() {
    const cred = await cloudbase.auth().getClientCredential();
    return {
      token: cred && cred.access_token,
      expiresInSeconds: Number(cred && cred.expires_in) || 0,
    };
  },
  fetchImpl: (url, init) => fetch(url, init),
};

/** 通道凭据缓存：token 有有效期，避免每次请求都去换一次。 */
const channelCache = { baseUrl: null, token: null, expiresAt: 0 };

/** 取通道 baseUrl + 请求头（含密钥头与 token）。 */
async function channelHeaders() {
  assertConfigured();
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
    // 无此头时 RLS 会挡住一切读写（外部匿名请求正是这种情况）
    [CHANNEL_HEADER]: process.env.TGG_SYNC_SECRET,
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
async function request(method, query, body) {
  const headers = await channelHeaders();
  if (method !== 'GET') headers.Prefer = 'return=representation';

  let res;
  try {
    res = await deps.fetchImpl(`${channelCache.baseUrl}${TABLE_PATH}${query}`, {
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

/**
 * PostgreSQL 实现。
 *
 * 并发正确性靠**单条 SQL 的原子性**，不需要先查后写（因此天然免疫竞态）：
 *   create        -> INSERT ... ON CONFLICT DO NOTHING：主键唯一约束保证只有一次成功
 *   compareAndSet -> UPDATE ... WHERE sync_id = $1 AND rev = $2：条件更新不丢更新
 * 两条语句在冲突时都只影响 0 行，据此判断版本冲突。
 */
/**
 * PostgreSQL 实现（走平台数据通道，不用连接串）。
 *
 * 并发正确性仍靠**单条语句的原子性**，与原先的 SQL 语义一一对应：
 *   create        -> POST；主键唯一约束冲突 → 409 → 判定为「已存在」
 *   compareAndSet -> PATCH ...&rev=eq.N；影响 0 行 → 判定为「rev 不匹配」
 * 两者都不需要「先查后写」，因此天然免疫竞态。
 */
const syncIdFilter = (syncId) => `sync_id=eq.${encodeURIComponent(syncId)}`;

const store = {
  async get(syncId) {
    const rows = await request(
      'GET',
      `?select=rev,blob&${syncIdFilter(syncId)}&limit=1`,
    );
    return rows[0] ? { rev: rows[0].rev, blob: rows[0].blob } : null;
  },

  async create(syncId, blob) {
    try {
      await request('POST', '', { sync_id: syncId, rev: 1, blob });
      return 1;
    } catch (e) {
      if (e instanceof ChannelError && e.status === 409) return null; // 主键已存在
      throw e;
    }
  },

  async compareAndSet(syncId, expectedRev, blob) {
    const rows = await request(
      'PATCH',
      `?${syncIdFilter(syncId)}&rev=eq.${expectedRev}`,
      { blob, rev: expectedRev + 1, updated_at: new Date().toISOString() },
    );
    return rows[0] ? rows[0].rev : null; // 0 行 = rev 不匹配
  },

  async remove(syncId) {
    // 幂等：不存在的 sync_id 删除影响 0 行，同样是成功
    await request('DELETE', `?${syncIdFilter(syncId)}`);
  },
};

/**
 * 把云函数的 HTTP 事件归一化为 {@link createHandler} 的入参。
 *
 * 兼容几种常见形态（不同触发器/网关给的字段名不一）：
 * - `httpMethod` / `method` / `requestContext.httpMethod`
 * - `queryStringParameters` / `query`
 * - `body` 为字符串、base64、或已解析的对象
 * - 也容忍把 syncId 直接写在路径里（`/reg/<32hex>`）
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
  let syncId = qs.code || qs.syncId || qs.syncid || '';
  if (!syncId && typeof e.path === 'string') {
    const m = e.path.match(/([0-9a-fA-F]{32})\s*$/);
    if (m) syncId = m[1];
  }

  let body = null;
  if (typeof e.body === 'string' && e.body.length > 0) {
    const raw = e.isBase64Encoded
      ? Buffer.from(e.body, 'base64').toString('utf8')
      : e.body;
    try {
      const parsed = JSON.parse(raw);
      body = parsed && typeof parsed === 'object' ? parsed : null;
    } catch (_) {
      body = null; // 交给 handler 报 400 invalid_body
    }
  } else if (e.body && typeof e.body === 'object') {
    body = e.body;
  }

  return { method, syncId: String(syncId), body };
}

/** 连接层错误码（node-postgres 在 socket 层抛出）。 */
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
 * 把数据库错误归类成「可诊断但不泄密」的响应：**只回错误码，不回主机名/账号/密码**。
 *
 * 刻意不参与控制流（不影响是否写数据），只解决「哪一层坏了」不可见的问题：
 * 此前连接挂到函数超时，外部只看到一个 504，与「SQL 写错」无法区分。
 * 详细错误仍只进云函数日志（私有），公开响应只给码。
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
    // 通道/网络层不通：查网络与平台状态，与「SQL 被拒」区分开
    return {
      statusCode: 503,
      body: { error: 'db_unreachable', code: code || 'CHANNEL_UNREACHABLE' },
    };
  }
  if (e instanceof ChannelError) {
    // 通道到达了数据库并被拒（如 DATABASE_23505 / 42501 权限不足）
    return { statusCode: 500, body: { error: 'db_error', code } };
  }
  return null;
}

const handle = createHandler({ store });

exports.main = async (event) => {
  // 注意：不要把 event 整段打进日志——虽然没有密钥，但密文长度/访问模式也是元数据。
  let result;
  try {
    result = await handle(normalizeHttpEvent(event));
  } catch (e) {
    if (e instanceof DbNotConfiguredError) {
      // 比「连接 localhost 失败」好排查得多：直接列出还缺哪些环境变量
      console.error('reg-sync 缺少数据库连接环境变量:', e.missing.join(', '));
      return {
        statusCode: 500,
        headers: JSON_HEADERS,
        body: JSON.stringify({ error: 'db_not_configured', missing: e.missing }),
      };
    }
    const classified = classifyDbError(e);
    if (classified) {
      console.error(
        'reg-sync 数据库错误:',
        classified.body.error,
        classified.body.code,
        e.message,
      );
      return {
        statusCode: classified.statusCode,
        headers: JSON_HEADERS,
        body: JSON.stringify(classified.body),
      };
    }
    console.error('reg-sync 处理失败:', e);
    return {
      statusCode: 500,
      headers: JSON_HEADERS,
      body: JSON.stringify({ error: 'internal_error' }),
    };
  }
  return {
    statusCode: result.status,
    headers: JSON_HEADERS,
    body: result.json === null ? '' : JSON.stringify(result.json),
  };
};

// 便于本地复用/测试
exports.normalizeHttpEvent = normalizeHttpEvent;
exports.classifyDbError = classifyDbError;
exports._store = store;
exports.DbNotConfiguredError = DbNotConfiguredError;
exports.ChannelError = ChannelError;
exports.ChannelUnreachableError = ChannelUnreachableError;
exports._deps = deps;
