'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const {
  classifyDbError,
  DbNotConfiguredError,
  ChannelError,
  ChannelUnreachableError,
  _store,
  _deps,
} = require('./index.js');

const SECRET = 'test-secret-value';

/** 记录调用并按脚本返回响应；返回 Error 则模拟网络异常。 */
function fakeFetch(script) {
  const calls = [];
  const fn = async (url, init) => {
    calls.push({
      url,
      method: init.method,
      headers: init.headers,
      body: init.body ? JSON.parse(init.body) : undefined,
    });
    const next = script(calls.length - 1);
    if (next instanceof Error) throw next;
    return { status: next.status, text: async () => next.text };
  };
  return { fn, calls };
}

/** 每个用例前把依赖与密钥接到可控实现上。 */
function setup(script) {
  const { fn, calls } = fakeFetch(script);
  _deps.getBaseUrl = () => 'https://example.invalid/v1/rdb/rest';
  _deps.getAccessToken = async () => ({ token: 'tok', expiresInSeconds: 3600 });
  _deps.fetchImpl = fn;
  return calls;
}

test.afterEach(() => {
  delete process.env.TGG_SYNC_SECRET;
});

// ---------- 错误归类 ----------

test('通道不可达：归类为 db_unreachable(503) 并保留错误码', () => {
  const e = new ChannelUnreachableError('数据通道不可达', 'ENOTFOUND');
  assert.deepEqual(classifyDbError(e), {
    statusCode: 503,
    body: { error: 'db_unreachable', code: 'ENOTFOUND' },
  });
});

test('超时（AbortSignal）也归类为 db_unreachable', () => {
  const e = new ChannelUnreachableError('数据通道不可达', 'TimeoutError');
  assert.equal(classifyDbError(e).statusCode, 503);
});

test('通道到达数据库后被拒：归类为 db_error 并保留平台错误码', () => {
  const e = new ChannelError(409, 'DATABASE_23505', 'duplicate key');
  assert.deepEqual(classifyDbError(e), {
    statusCode: 500,
    body: { error: 'db_error', code: 'DATABASE_23505' },
  });
});

test('未配置错误交给调用方单独处理，不走归类', () => {
  assert.equal(classifyDbError(new DbNotConfiguredError(['TGG_SYNC_SECRET'])), null);
});

test('无法归类的错误返回 null（保持 internal_error 兜底）', () => {
  assert.equal(classifyDbError(new TypeError('store is not a function')), null);
});

test('响应体不得回显密钥/主机名等信息', () => {
  const e = new ChannelError(500, 'DATABASE_42501', `permission denied; secret=${SECRET}`);
  const serialized = JSON.stringify(classifyDbError(e));
  assert.ok(!serialized.includes(SECRET), '不应回显密钥');
  assert.ok(serialized.includes('DATABASE_42501'));
});

// ---------- 存储语义（channel -> PostgREST 映射） ----------

test('get：无记录返回 null；有记录返回 {rev, blob}', async () => {
  setup((i) => (i === 0 ? { status: 200, text: '[]' } : { status: 200, text: '[{"rev":3,"blob":"CIPHER"}]' }));
  process.env.TGG_SYNC_SECRET = SECRET;

  assert.equal(await _store.get('a'.repeat(32)), null);
  assert.deepEqual(await _store.get('a'.repeat(32)), { rev: 3, blob: 'CIPHER' });
});

test('get：请求必须带上通道密钥头（RLS 依赖它，漏了就读不到数据）', async () => {
  const calls = setup(() => ({ status: 200, text: '[]' }));
  process.env.TGG_SYNC_SECRET = SECRET;

  await _store.get('a'.repeat(32));
  assert.equal(calls[0].headers['x-tgg-sync'], SECRET);
  assert.equal(calls[0].headers['Accept-Profile'], 'public');
});

test('create：成功返回 1', async () => {
  const calls = setup(() => ({ status: 201, text: '' }));
  process.env.TGG_SYNC_SECRET = SECRET;

  assert.equal(await _store.create('b'.repeat(32), 'C1'), 1);
  assert.equal(calls[0].method, 'POST');
  assert.deepEqual(calls[0].body, { sync_id: 'b'.repeat(32), rev: 1, blob: 'C1' });
});

test('create：主键冲突（409）判定为已存在 → 返回 null（交给 handler 报 409）', async () => {
  setup(() => ({ status: 409, text: '{"code":"DATABASE_23505","message":"duplicate key"}' }));
  process.env.TGG_SYNC_SECRET = SECRET;

  assert.equal(await _store.create('b'.repeat(32), 'C1'), null);
});

test('compareAndSet：PATCH 必须带上 rev 过滤条件（这就是 CAS 本身）', async () => {
  const calls = setup(() => ({ status: 200, text: '[{"rev":8}]' }));
  process.env.TGG_SYNC_SECRET = SECRET;

  const rev = await _store.compareAndSet('c'.repeat(32), 7, 'C2');
  assert.equal(rev, 8);
  assert.equal(calls[0].method, 'PATCH');
  assert.ok(calls[0].url.includes(`sync_id=eq.${'c'.repeat(32)}`), 'URL 应带 sync_id 过滤');
  assert.ok(calls[0].url.includes('rev=eq.7'), 'URL 应带 rev 过滤（缺了就不是 CAS）');
  assert.deepEqual(calls[0].body, { blob: 'C2', rev: 8, updated_at: calls[0].body.updated_at });
});

test('compareAndSet：影响 0 行 → 返回 null（rev 不匹配 → 409）', async () => {
  setup(() => ({ status: 200, text: '[]' }));
  process.env.TGG_SYNC_SECRET = SECRET;

  assert.equal(await _store.compareAndSet('c'.repeat(32), 7, 'C2'), null);
});

test('remove：DELETE 且幂等（0 行也算成功）', async () => {
  const calls = setup(() => ({ status: 200, text: '[]' }));
  process.env.TGG_SYNC_SECRET = SECRET;

  await _store.remove('d'.repeat(32));
  assert.equal(calls[0].method, 'DELETE');
  assert.ok(calls[0].url.includes(`sync_id=eq.${'d'.repeat(32)}`));
});

test('未配置通道密钥：抛 DbNotConfiguredError（OPTIONS/400 不受影响，因为只在 store 内校验）', async () => {
  setup(() => ({ status: 200, text: '[]' }));
  await assert.rejects(() => _store.get('e'.repeat(32)), DbNotConfiguredError);
});

test('网络异常：包装成 ChannelUnreachableError，保留底层错误码', async () => {
  setup(() => {
    const err = new TypeError('fetch failed');
    err.cause = { code: 'ECONNREFUSED' };
    return err;
  });
  process.env.TGG_SYNC_SECRET = SECRET;

  await assert.rejects(
    () => _store.get('f'.repeat(32)),
    (e) => e instanceof ChannelUnreachableError && e.code === 'ECONNREFUSED',
  );
});

test('countRecentCreates：从 Content-Range 读总数，并请求 count=exact', async () => {
  const calls = [];
  _deps.getBaseUrl = () => 'https://example.invalid/v1/rdb/rest';
  _deps.getAccessToken = async () => ({ token: 'tok', expiresInSeconds: 3600 });
  _deps.fetchImpl = async (url, init) => {
    calls.push({ url, headers: init.headers });
    return {
      status: 200,
      text: async () => '[]',
      headers: { get: (k) => (k === 'content-range' ? '0-0/42' : null) },
    };
  };
  process.env.TGG_SYNC_SECRET = SECRET;

  const count = await _store.countRecentCreates(24 * 60 * 60 * 1000);
  assert.equal(count, 42);
  assert.equal(calls[0].headers.Prefer, 'count=exact');
  assert.ok(calls[0].url.includes('created_at=gte.'));
});

test('countRecentCreates：响应没有 Content-Range 时返回 null（调用方放行）', async () => {
  _deps.getBaseUrl = () => 'https://example.invalid/v1/rdb/rest';
  _deps.getAccessToken = async () => ({ token: 'tok', expiresInSeconds: 3600 });
  _deps.fetchImpl = async () => ({ status: 200, text: async () => '[]' });
  process.env.TGG_SYNC_SECRET = SECRET;

  assert.equal(await _store.countRecentCreates(1000), null);
});
