'use strict';

/**
 * handler 的本地单测（不依赖云 SDK、不联网）：
 *   cd server/cloudbase/functions/catalog && node --test
 *
 * 重点验证「客户端能依赖的契约」：
 *   · 原文逐字节返回（sha256 必须对得上）
 *   · ETag / If-None-Match → 304
 *   · 写操作必须有密钥，读操作不需要
 */

const test = require('node:test');
const assert = require('node:assert/strict');

const { createHandler, sha256Of, parseTarget, etagMatches } = require('./handler');

const SECRET = 'test-catalog-secret';

function memoryStore() {
  const files = new Map();
  const parts = new Map(); // kind -> Map<part, {total, body}>
  return {
    files,
    parts,
    async list() {
      return [...files.values()].map((f) => ({
        kind: f.kind,
        schemaVersion: f.schemaVersion,
        dataVersion: f.dataVersion,
        sha256: f.sha256,
        bytes: f.bytes,
        updatedAt: '2026-10-23T00:00:00.000Z',
      }));
    },
    async get(kind) {
      const f = files.get(kind);
      return f ? { body: f.body, sha256: f.sha256 } : null;
    },
    async put(kind, rec) {
      files.set(kind, Object.assign({ kind }, rec));
    },
    async remove(kind) {
      files.delete(kind);
    },
    async putPart(kind, part, total, body) {
      const bucket = parts.get(kind) || new Map();
      bucket.set(part, { total, body });
      parts.set(kind, bucket);
      if (bucket.size !== total) return null;
      const texts = [];
      for (let i = 1; i <= total; i += 1) {
        const item = bucket.get(i);
        if (!item) return null;
        texts.push(item.body);
      }
      return texts.join('');
    },
    async clearParts(kind) {
      parts.delete(kind);
    },
  };
}

function setup({ secret = SECRET, maxBytes } = {}) {
  const store = memoryStore();
  const readSecret = () => secret || undefined;
  return { store, handle: createHandler({ store, secret: readSecret, maxBytes }) };
}

/** 构造一个分片文档（缩进刻意不规整，用来验证「原文返回」）。 */
const doc = (dataVersion = '2026.10.23.1') =>
  `{"schemaVersion":1,"dataVersion":"${dataVersion}","items":{"shaolin":[1,2,3]}}`;

const putReq = (kind, raw, extra = {}) => ({
  method: 'PUT',
  kind,
  token: SECRET,
  raw,
  doc: JSON.parse(raw),
  ...extra,
});

test('OPTIONS：204，且不需要配置密钥（Web 预检先于一切）', async () => {
  const { handle } = setup({ secret: null });
  const res = await handle({ method: 'OPTIONS' });
  assert.equal(res.status, 204);
  assert.equal(res.headers['access-control-allow-origin'], '*');
  assert.ok(res.headers['access-control-expose-headers'].includes('etag'));
});

test('GET manifest：空库返回 200 与空 files', async () => {
  const { handle } = setup();
  const res = await handle({ method: 'GET', kind: null });
  assert.equal(res.status, 200);
  const body = JSON.parse(res.text);
  assert.equal(body.schemaVersion, 1);
  assert.deepEqual(body.files, []);
  assert.ok(res.headers.etag);
});

test('GET 未发布的分片 → 404 not_found', async () => {
  const { handle } = setup();
  const res = await handle({ method: 'GET', kind: 'job.artifacts' });
  assert.equal(res.status, 404);
  assert.equal(JSON.parse(res.text).error, 'not_found');
});

test('PUT 无密钥 → 401；密钥错误 → 401；未配置 → 500 not_configured', async () => {
  const { handle } = setup();
  const noToken = await handle({ ...putReq('job.artifacts', doc()), token: null });
  assert.equal(noToken.status, 401);

  const wrong = await handle({ ...putReq('job.artifacts', doc()), token: 'nope' });
  assert.equal(wrong.status, 401);

  const { handle: unconfigured } = setup({ secret: null });
  const res = await unconfigured(putReq('job.artifacts', doc()));
  assert.equal(res.status, 500);
  assert.deepEqual(JSON.parse(res.text).missing, ['TGG_CATALOG_SECRET']);
});

test('PUT → 204，随后 GET 逐字节返回原文，且 hash 与 manifest 一致', async () => {
  const { handle } = setup();
  const raw = doc();

  const put = await handle(putReq('job.artifacts', raw));
  assert.equal(put.status, 204);
  assert.equal(put.headers.etag, `"${sha256Of(raw)}"`);

  const got = await handle({ method: 'GET', kind: 'job.artifacts' });
  assert.equal(got.status, 200);
  assert.equal(got.text, raw, '必须原样返回：客户端按 sha256 校验');
  assert.equal(got.headers['cache-control'], 'public, max-age=86400');

  const manifest = JSON.parse((await handle({ method: 'GET', kind: null })).text);
  assert.equal(manifest.files.length, 1);
  assert.equal(manifest.files[0].kind, 'job.artifacts');
  assert.equal(manifest.files[0].sha256, sha256Of(raw));
  assert.equal(manifest.files[0].bytes, Buffer.byteLength(raw));
  assert.equal(manifest.dataVersion, '2026.10.23.1');
});

test('同内容重复发布：hash 不变 → manifest ETag 不变（客户端 304，零流量）', async () => {
  const { handle } = setup();
  const raw = doc();

  await handle(putReq('job.artifacts', raw));
  const first = await handle({ method: 'GET', kind: null });

  await handle(putReq('job.artifacts', raw));
  const second = await handle({ method: 'GET', kind: null });

  assert.equal(first.headers.etag, second.headers.etag);

  await handle(putReq('job.artifacts', doc('2026.10.24.1')));
  const third = await handle({ method: 'GET', kind: null });
  assert.notEqual(second.headers.etag, third.headers.etag);
});

test('If-None-Match 命中 → 304（manifest 与分片都支持）', async () => {
  const { handle } = setup();
  const raw = doc();
  await handle(putReq('job.artifacts', raw));

  const manifest = await handle({ method: 'GET', kind: null });
  const cached = await handle({
    method: 'GET',
    kind: null,
    ifNoneMatch: manifest.headers.etag,
  });
  assert.equal(cached.status, 304);
  assert.equal(cached.text, null);

  const file = await handle({ method: 'GET', kind: 'job.artifacts' });
  const weak = await handle({
    method: 'GET',
    kind: 'job.artifacts',
    ifNoneMatch: `W/${file.headers.etag}`,
  });
  assert.equal(weak.status, 304);
});

test('参数校验：schemaVersion / dataVersion / 非对象 / 空体', async () => {
  const { handle } = setup();

  const badSchema = await handle(
    putReq('job.artifacts', '{"dataVersion":"2026.10.23.1"}'),
  );
  assert.equal(badSchema.status, 400);
  assert.equal(JSON.parse(badSchema.text).error, 'invalid_schema_version');

  const badVersion = await handle(putReq('job.artifacts', '{"schemaVersion":1}'));
  assert.equal(badVersion.status, 400);
  assert.equal(JSON.parse(badVersion.text).error, 'invalid_data_version');

  const notObject = await handle(putReq('job.artifacts', '[1,2,3]'));
  assert.equal(notObject.status, 400);
  assert.equal(JSON.parse(notObject.text).error, 'invalid_body');

  const empty = await handle({ method: 'PUT', kind: 'job.artifacts', token: SECRET, raw: '' });
  assert.equal(empty.status, 400);
});

test('超大分片 → 413', async () => {
  const { handle } = setup({ maxBytes: 64 });
  const res = await handle(putReq('job.artifacts', doc(), {}));
  assert.equal(res.status, 413);
  assert.equal(JSON.parse(res.text).error, 'payload_too_large');
});

test('非法 kind → 400；写 manifest → 400；未知方法 → 405', async () => {
  const { handle } = setup();

  const badKind = await handle({ method: 'GET', kind: 'Job..Artifacts' });
  assert.equal(badKind.status, 400);
  assert.equal(JSON.parse(badKind.text).error, 'invalid_kind');

  const writeManifest = await handle({
    method: 'PUT',
    kind: null,
    token: SECRET,
    raw: doc(),
    doc: JSON.parse(doc()),
  });
  assert.equal(writeManifest.status, 400);

  const patch = await handle({ method: 'PATCH', kind: 'job.artifacts', token: SECRET });
  assert.equal(patch.status, 405);
});

test('DELETE：幂等，删掉后 GET 变 404', async () => {
  const { handle } = setup();
  await handle(putReq('job.artifacts', doc()));

  const del = await handle({ method: 'DELETE', kind: 'job.artifacts', token: SECRET });
  assert.equal(del.status, 204);
  assert.equal((await handle({ method: 'GET', kind: 'job.artifacts' })).status, 404);

  const again = await handle({ method: 'DELETE', kind: 'job.artifacts', token: SECRET });
  assert.equal(again.status, 204);
});

test('parseTarget：manifest / 空 → 无分片；大写归一为小写；非法形状算 invalid', () => {
  assert.equal(parseTarget(null).kind, null);
  assert.equal(parseTarget('manifest.json').kind, null);
  assert.equal(parseTarget('Job.Artifacts').kind, 'job.artifacts');
  assert.equal(parseTarget('Job..Artifacts').invalid, true);
  assert.equal(parseTarget('a'.repeat(65)).invalid, true);
});

test('etagMatches：支持列表、W/ 前缀与 *', () => {
  assert.equal(etagMatches('"a"', '"a"'), true);
  assert.equal(etagMatches('W/"a"', '"a"'), true);
  assert.equal(etagMatches('"x", "a"', '"a"'), true);
  assert.equal(etagMatches('*', '"a"'), true);
  assert.equal(etagMatches(null, '"a"'), false);
  assert.equal(etagMatches('"b"', '"a"'), false);
});

test('分片上传：中间片 202，最后一片 204，GET 得到拼接原文', async () => {
  const { handle } = setup();
  const full = doc();
  const cut = 20;
  const first = full.slice(0, cut);
  const second = full.slice(cut);

  const r1 = await handle({
    method: 'PUT',
    kind: 'job.artifacts',
    token: SECRET,
    raw: first,
    part: 1,
    total: 2,
  });
  assert.equal(r1.status, 202);
  assert.equal(r1.headers['x-catalog-complete'], '0');
  // 未集齐前不可读
  assert.equal((await handle({ method: 'GET', kind: 'job.artifacts' })).status, 404);

  const r2 = await handle({
    method: 'PUT',
    kind: 'job.artifacts',
    token: SECRET,
    raw: second,
    part: 2,
    total: 2,
  });
  assert.equal(r2.status, 204);
  assert.equal(r2.headers.etag, `"${sha256Of(full)}"`);

  const got = await handle({ method: 'GET', kind: 'job.artifacts' });
  assert.equal(got.text, full, '拼接结果必须与原文逐字节一致');
});

test('分片上传：乱序到达也能组装', async () => {
  const { handle } = setup();
  const full = doc();
  const a = full.slice(0, 15);
  const b = full.slice(15);

  await handle({ method: 'PUT', kind: 'job.artifacts', token: SECRET, raw: b, part: 2, total: 2 });
  const last = await handle({
    method: 'PUT',
    kind: 'job.artifacts',
    token: SECRET,
    raw: a,
    part: 1,
    total: 2,
  });
  assert.equal(last.status, 204);
  assert.equal((await handle({ method: 'GET', kind: 'job.artifacts' })).text, full);
});

test('分片上传：参数非法 / 组装后不是 JSON → 400 且清理暂存', async () => {
  const { handle, store } = setup();

  const bad = await handle({
    method: 'PUT',
    kind: 'job.artifacts',
    token: SECRET,
    raw: 'x',
    part: 3,
    total: 2,
  });
  assert.equal(bad.status, 400);
  assert.equal(JSON.parse(bad.text).error, 'invalid_part');

  await handle({ method: 'PUT', kind: 'job.artifacts', token: SECRET, raw: '{bad', part: 1, total: 2 });
  const broken = await handle({
    method: 'PUT',
    kind: 'job.artifacts',
    token: SECRET,
    raw: ' json}',
    part: 2,
    total: 2,
  });
  assert.equal(broken.status, 400);
  assert.equal(store.parts.has('job.artifacts'), false);
});
