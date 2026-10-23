'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const {
  classifyDbError,
  normalizeHttpEvent,
  parsePathKind,
  DbNotConfiguredError,
  ChannelError,
  ChannelUnreachableError,
  _store,
  _deps,
} = require('./index.js');

const SECRET = 'test-catalog-secret';

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

function setup(script) {
  const { fn, calls } = fakeFetch(script);
  _deps.getBaseUrl = () => 'https://example.invalid/v1/rdb/rest';
  _deps.getAccessToken = async () => ({ token: 'tok', expiresInSeconds: 3600 });
  _deps.fetchImpl = fn;
  process.env.TGG_CATALOG_SECRET = SECRET;
  return calls;
}

const row = (over = {}) =>
  Object.assign(
    {
      kind: 'job.artifacts',
      schema_version: 1,
      data_version: '2026.10.23.1',
      sha256: 'f'.repeat(64),
      bytes: 42,
      updated_at: '2026-10-23T00:00:00.000Z',
    },
    over,
  );

test('list：GET 全部列并按 kind 排序，字段转为驼峰', async () => {
  const calls = setup(() => ({ status: 200, text: JSON.stringify([row()]) }));

  const items = await _store.list();
  assert.equal(calls[0].method, 'GET');
  assert.ok(calls[0].url.includes('/catalog_files?select='));
  assert.ok(calls[0].url.includes('order=kind.asc'));
  assert.deepEqual(items[0], {
    kind: 'job.artifacts',
    schemaVersion: 1,
    dataVersion: '2026.10.23.1',
    sha256: 'f'.repeat(64),
    bytes: 42,
    updatedAt: '2026-10-23T00:00:00.000Z',
  });
});

test('get：按 kind 过滤，未命中返回 null；命中返回原文', async () => {
  setup(() => ({ status: 200, text: '[]' }));
  assert.equal(await _store.get('job.artifacts'), null);

  const calls = setup(() => ({
    status: 200,
    text: JSON.stringify([{ body: '{"a":1}', sha256: 'abc' }]),
  }));
  const rec = await _store.get('job.artifacts');
  assert.deepEqual(rec, { body: '{"a":1}', sha256: 'abc' });
  assert.ok(calls[0].url.includes('kind=eq.job.artifacts'));
});

test('put：先 PATCH，命中行则不再 INSERT', async () => {
  const calls = setup(() => ({ status: 200, text: JSON.stringify([row()]) }));

  await _store.put('job.artifacts', {
    schemaVersion: 2,
    dataVersion: '2026.10.24.1',
    body: '{"x":1}',
    sha256: 'a'.repeat(64),
    bytes: 7,
  });

  assert.equal(calls.length, 1);
  assert.equal(calls[0].method, 'PATCH');
  assert.ok(calls[0].url.includes('kind=eq.job.artifacts'));
  assert.equal(calls[0].body.schema_version, 2);
  assert.equal(calls[0].body.data_version, '2026.10.24.1');
  assert.equal(calls[0].body.body, '{"x":1}');
  assert.equal(calls[0].headers['x-tgg-catalog'], SECRET);
});

test('put：PATCH 0 行时 INSERT 新分片', async () => {
  const calls = setup((i) =>
    i === 0 ? { status: 200, text: '[]' } : { status: 201, text: JSON.stringify([row()]) },
  );

  await _store.put('job.artifacts', {
    schemaVersion: 1,
    dataVersion: 'v1',
    body: '{}',
    sha256: 'b'.repeat(64),
    bytes: 2,
  });

  assert.equal(calls.length, 2);
  assert.equal(calls[1].method, 'POST');
  assert.equal(calls[1].body.kind, 'job.artifacts');
});

test('put：INSERT 撞主键（409）时退化为一次 PATCH', async () => {
  const calls = setup((i) => {
    if (i === 0) return { status: 200, text: '[]' };
    if (i === 1) return { status: 409, text: '{"code":"DATABASE_23505","message":"dup"}' };
    return { status: 200, text: JSON.stringify([row()]) };
  });

  await _store.put('job.artifacts', {
    schemaVersion: 1,
    dataVersion: 'v1',
    body: '{}',
    sha256: 'c'.repeat(64),
    bytes: 2,
  });

  assert.equal(calls.length, 3);
  assert.equal(calls[2].method, 'PATCH');
});

test('remove：DELETE 且幂等（0 行也算成功）', async () => {
  const calls = setup(() => ({ status: 200, text: '[]' }));
  await _store.remove('pet.beast_spirits');
  assert.equal(calls[0].method, 'DELETE');
  assert.ok(calls[0].url.includes('kind=eq.pet.beast_spirits'));
});

test('未配置通道密钥：读仍然可用，写才抛 DbNotConfiguredError', async () => {
  setup(() => ({ status: 200, text: '[]' }));
  delete process.env.TGG_CATALOG_SECRET;

  await assert.doesNotReject(() => _store.list());
  await assert.doesNotReject(() => _store.get('job.artifacts'));
  await assert.rejects(
    () => _store.put('job.artifacts', {
      schemaVersion: 1,
      dataVersion: 'v1',
      body: '{}',
      sha256: 'd'.repeat(64),
      bytes: 2,
    }),
    DbNotConfiguredError,
  );
});

test('网络异常：包装成 ChannelUnreachableError 并保留底层错误码', async () => {
  setup(() => {
    const err = new TypeError('fetch failed');
    err.cause = { code: 'ECONNREFUSED' };
    return err;
  });

  await assert.rejects(
    () => _store.list(),
    (e) => e instanceof ChannelUnreachableError && e.code === 'ECONNREFUSED',
  );
});

test('classifyDbError：通道不可达 → 503，数据库拒绝 → 500，未知 → null', () => {
  const unreachable = classifyDbError(new ChannelUnreachableError('x', 'ETIMEDOUT'));
  assert.equal(unreachable.statusCode, 503);
  assert.equal(unreachable.body.error, 'db_unreachable');

  const rejected = classifyDbError(new ChannelError(403, 'DATABASE_42501', 'denied'));
  assert.equal(rejected.statusCode, 500);
  assert.equal(rejected.body.error, 'db_error');

  assert.equal(classifyDbError(new Error('boom')), null);
  assert.equal(classifyDbError(new DbNotConfiguredError(['X'])), null);
});

test('parsePathKind：支持 /catalog/x.json、省略后缀、以及 manifest/catalog 自身', () => {
  assert.equal(parsePathKind('/catalog/job.artifacts.json'), 'job.artifacts');
  assert.equal(parsePathKind('/catalog/job.artifacts'), 'job.artifacts');
  assert.equal(parsePathKind('/job.artifacts.json?x=1'), 'job.artifacts');
  assert.equal(parsePathKind('/catalog'), null);
  assert.equal(parsePathKind('/catalog/manifest.json'), 'manifest');
  assert.equal(parsePathKind(''), null);
  assert.equal(parsePathKind(undefined), null);
});

test('normalizeHttpEvent：路径取 kind、头大小写不敏感、base64 体可解码', async () => {
  const raw = '{"schemaVersion":1,"dataVersion":"v1"}';
  const ev = normalizeHttpEvent({
    httpMethod: 'put',
    path: '/catalog/job.artifacts.json',
    headers: { 'X-Catalog-Token': SECRET, 'If-None-Match': '"abc"' },
    body: Buffer.from(raw, 'utf8').toString('base64'),
    isBase64Encoded: true,
  });

  assert.equal(ev.method, 'PUT');
  assert.equal(ev.kind, 'job.artifacts');
  assert.equal(ev.token, SECRET);
  assert.equal(ev.ifNoneMatch, '"abc"');
  assert.equal(ev.raw, raw);
  assert.equal(ev.doc.schemaVersion, 1);
});

test('normalizeHttpEvent：query 参数 kind 也可用，坏 JSON 交给 handler 报 400', () => {
  const ev = normalizeHttpEvent({
    method: 'PUT',
    path: '/catalog',
    queryStringParameters: { kind: 'pet.beast_spirits' },
    body: '{bad json',
  });
  assert.equal(ev.kind, 'pet.beast_spirits');
  assert.equal(ev.doc, null);
  assert.equal(ev.raw, '{bad json');
});
