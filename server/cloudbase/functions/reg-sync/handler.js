'use strict';

/**
 * 卡回归云同步 —— 纯请求处理逻辑（不依赖任何云 SDK，可本地单测）。
 *
 * 服务端是**哑存储**：只按 syncId 存取一段字符串，不理解业务语义。
 * 那段字符串是客户端 AES-GCM 加密后的密文，服务端永远拿不到明文。
 *
 * 并发正确性完全依赖 store 的 create / compareAndSet 是**单文档原子操作**：
 *   create        -> 主键唯一约束保证只有一次成功
 *   compareAndSet -> 条件更新（_id + rev 同时匹配）保证不会丢更新
 */

/** 单条密文上限（客户端载荷通常几 KB，256KB 足够并挡住滥用）。 */
const MAX_BLOB_BYTES = 256 * 1024;

/**
 * 每 24 小时允许的**新建**条数（全站）。
 *
 * 创建（PUT rev=0）是唯一不需要凭证的写操作，服务地址公开后可能被脚本刷记录。
 * 阈值定得远高于真实用量（几百个用户也到不了），只用来把「无限刷」变成
 * 「每天最多 N 条」，从而封顶存储与调用成本。可用环境变量覆盖。
 */
const DEFAULT_MAX_CREATES_PER_DAY = 5000;

/** 统计窗口：滚动 24 小时（避免时区/整点边界问题）。 */
const CREATE_WINDOW_MS = 24 * 60 * 60 * 1000;

/** syncId 必须是 128 位随机十六进制（由客户端 RegPairing 生成）。 */
const SYNC_ID_RE = /^[0-9a-f]{32}$/;

const JSON_HEADERS = {
  'content-type': 'application/json; charset=utf-8',
  // 匿名公开接口（无 Cookie/凭据），Web 端跨域需要；将来若加鉴权应收紧。
  'access-control-allow-origin': '*',
  'access-control-allow-methods': 'GET,PUT,DELETE,OPTIONS',
  'access-control-allow-headers': 'content-type',
  'cache-control': 'no-store',
};

/**
 * @param {{store: {
 *   get(syncId: string): Promise<{rev: number, blob: string}|null>,
 *   create(syncId: string, blob: string): Promise<number|null>,
 *   compareAndSet(syncId: string, expectedRev: number, blob: string): Promise<number|null>,
 *   remove(syncId: string): Promise<void>,
 * }}} deps
 * @returns {(req: {method: string, syncId: string, body: object|null}) =>
 *   Promise<{status: number, json: object|null}>}
 */
function createHandler({
  store,
  maxCreatesPerWindow = DEFAULT_MAX_CREATES_PER_DAY,
  createWindowMs = CREATE_WINDOW_MS,
}) {
  return async function handle(req) {
    const method = (req.method || 'GET').toUpperCase();
    const syncId = (req.syncId || '').toLowerCase();
    const body = req.body;

    if (method === 'OPTIONS') return { status: 204, json: null };

    if (!SYNC_ID_RE.test(syncId)) {
      return fail(400, 'invalid_sync_id', 'code 必须是 32 位十六进制');
    }

    if (method === 'GET') {
      const rec = await store.get(syncId);
      if (!rec) return fail(404, 'not_found', '该同步码尚未在云端创建');
      return { status: 200, json: { rev: rec.rev, blob: rec.blob } };
    }

    if (method === 'PUT') {
      if (!body || typeof body !== 'object') {
        return fail(400, 'invalid_body', '请求体必须是 JSON 对象');
      }
      const expectedRev = Number(body.rev);
      const blob = body.blob;
      if (!Number.isInteger(expectedRev) || expectedRev < 0) {
        return fail(400, 'invalid_rev', 'rev 必须是非负整数');
      }
      if (typeof blob !== 'string' || blob.length === 0) {
        return fail(400, 'invalid_blob', 'blob 必须是非空字符串');
      }
      if (Buffer.byteLength(blob, 'utf8') > MAX_BLOB_BYTES) {
        return fail(413, 'blob_too_large', `blob 超过 ${MAX_BLOB_BYTES} 字节`);
      }

      if (expectedRev === 0) {
        // 防滥用：限制窗口内全站新建条数。统计失败（返回 null）时放行，
        // 宁可少拦一次也不能因为统计异常把正常用户挡在外面。
        const used = await store.countRecentCreates(createWindowMs);
        if (used !== null && used >= maxCreatesPerWindow) {
          return fail(
            429,
            'quota_exceeded',
            `24 小时内新建记录已达上限（${maxCreatesPerWindow}），请稍后再试`,
          );
        }
      }

      const rev =
        expectedRev === 0
          ? await store.create(syncId, blob)
          : await store.compareAndSet(syncId, expectedRev, blob);

      if (rev === null) {
        // 冲突：把当前实际 rev 一并返回，客户端据此重拉合并
        const current = await store.get(syncId);
        return {
          status: 409,
          json: { error: 'conflict', rev: current ? current.rev : 0 },
        };
      }
      return { status: 200, json: { rev } };
    }

    if (method === 'DELETE') {
      await store.remove(syncId);
      return { status: 200, json: { ok: true } };
    }

    return fail(405, 'method_not_allowed', `不支持的方法：${method}`);
  };
}

function fail(status, error, message) {
  return { status, json: { error, message } };
}

module.exports = {
  createHandler,
  MAX_BLOB_BYTES,
  DEFAULT_MAX_CREATES_PER_DAY,
  CREATE_WINDOW_MS,
  SYNC_ID_RE,
  JSON_HEADERS,
};
