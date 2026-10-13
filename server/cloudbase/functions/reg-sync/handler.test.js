'use strict';

/**
 * handler 的本地单测（不依赖云 SDK、不联网）：
 *   cd server/cloudbase/functions/reg-sync && node --test
 *
 * 内存 store 的 create / compareAndSet 与云端一样是「单文档原子操作」
 * （Node 单线程 + 两个 await 之间没有让出点），因此并发用例能真实反映
 * 云端条件更新的行为。
 */

const test = require('node:test');
const assert = require('node:assert/strict');

const { createHandler, MAX_BLOB_BYTES, SYNC_ID_RE } = require('./handler');

const ID = 'a'.repeat(32);
const ID2 = 'b'.repeat(32);

function memoryStore() {
  const docs = new Map();
  return {
    docs,
    async get(id) {
      const d = docs.get(id);
      return d ? { rev: d.rev, blob: d.blob } : null;
    },
    async create(id, blob) {
      if (docs.has(id)) return null;
      docs.set(id, { rev: 1, blob });
      return 1;
    },
    async compareAndSet(id, expectedRev, blob) {
      const d = docs.get(id);
      if (!d || d.rev !== expectedRev) return null;
      d.blob = blob;
      d.rev = expectedRev + 1;
      return d.rev;
    },
    async remove(id) {
      docs.delete(id);
    },
  };
}

function setup() {
  const store = memoryStore();
  return { store, handle: createHandler({ store }) };
}

const put = (id, rev, blob) => ({ method: 'PUT', syncId: id, body: { rev, blob } });
const get = (id) => ({ method: 'GET', syncId: id, body: null });

test('GET：未创建的记录返回 404（客户端据此走「首次上传」分支）', async () => {
  const { handle } = setup();
  const res = await handle(get(ID));
  assert.equal(res.status, 404);
  assert.equal(res.json.error, 'not_found');
});

test('PUT rev=0 创建；重复创建返回 409 并带出当前 rev', async () => {
  const { handle } = setup();

  const created = await handle(put(ID, 0, 'blob-1'));
  assert.equal(created.status, 200);
  assert.equal(created.json.rev, 1);

  const again = await handle(put(ID, 0, 'blob-2'));
  assert.equal(again.status, 409);
  assert.equal(again.json.rev, 1);

  // 冲突不该改动数据
  const now = await handle(get(ID));
  assert.equal(now.json.blob, 'blob-1');
});

test('PUT 条件更新：rev 匹配则 +1，不匹配返回 409 与真实 rev', async () => {
  const { handle } = setup();
  await handle(put(ID, 0, 'v1'));

  const ok = await handle(put(ID, 1, 'v2'));
  assert.equal(ok.status, 200);
  assert.equal(ok.json.rev, 2);

  // 拿着过期 rev 再来（另一台设备已经写过）
  const stale = await handle(put(ID, 1, 'v3'));
  assert.equal(stale.status, 409);
  assert.equal(stale.json.rev, 2);

  const now = await handle(get(ID));
  assert.deepEqual(now.json, { rev: 2, blob: 'v2' });
});

test('PUT：对不存在的记录用非 0 rev 写入 → 409（而不是凭空创建）', async () => {
  const { handle } = setup();
  const res = await handle(put(ID2, 5, 'x'));
  assert.equal(res.status, 409);
  assert.equal(res.json.rev, 0);
});

test('DELETE：删除后 GET 404；重复删除仍返回 200（幂等）', async () => {
  const { handle } = setup();
  await handle(put(ID, 0, 'v1'));

  assert.equal((await handle({ method: 'DELETE', syncId: ID, body: null })).status, 200);
  assert.equal((await handle(get(ID))).status, 404);
  assert.equal((await handle({ method: 'DELETE', syncId: ID, body: null })).status, 200);
});

test('参数校验：非法 code / rev / blob / 超大 blob / 不支持的方法', async () => {
  const { handle } = setup();

  assert.equal((await handle(get('not-a-hex-id'))).status, 400);
  assert.equal((await handle(get('a'.repeat(31)))).status, 400);
  assert.equal((await handle(put(ID, -1, 'x'))).status, 400);
  assert.equal((await handle(put(ID, 1.5, 'x'))).status, 400);
  assert.equal((await handle(put(ID, 0, ''))).status, 400);
  assert.equal(
    (await handle({ method: 'PUT', syncId: ID, body: null })).status,
    400,
  );
  assert.equal((await handle(put(ID, 0, 'x'.repeat(MAX_BLOB_BYTES + 1)))).status, 413);
  assert.equal((await handle({ method: 'PATCH', syncId: ID, body: null })).status, 405);

  // 大写 code 应被规范化为小写后使用（客户端始终小写，这里只是容错）
  const upper = { method: 'GET', syncId: 'A'.repeat(32), body: null };
  assert.equal((await handle(upper)).status, 404);
  assert.ok(SYNC_ID_RE.test(ID));
});

test('OPTIONS：CORS 预检返回 204（Flutter Web 端必需）', async () => {
  const { handle } = setup();
  const res = await handle({ method: 'OPTIONS', syncId: '', body: null });
  assert.equal(res.status, 204);
  assert.equal(res.json, null);
});

test('并发：10 台设备同时以 rev=0 创建 → 恰好 1 次成功、其余 409', async () => {
  const { handle, store } = setup();
  const results = await Promise.all(
    Array.from({ length: 10 }, (_, i) => handle(put(ID, 0, `blob-${i}`))),
  );

  assert.equal(results.filter((r) => r.status === 200).length, 1);
  assert.equal(results.filter((r) => r.status === 409).length, 9);
  assert.equal(store.docs.get(ID).rev, 1);
});

test('并发：10 次相同 expectedRev 的条件更新 → 恰好 1 次成功（不丢更新）', async () => {
  const { handle, store } = setup();
  await handle(put(ID, 0, 'v1')); // rev 1

  const results = await Promise.all(
    Array.from({ length: 10 }, (_, i) => handle(put(ID, 1, `v1-${i}`))),
  );

  assert.equal(results.filter((r) => r.status === 200 && r.json.rev === 2).length, 1);
  assert.equal(store.docs.get(ID).rev, 2);
});

test('端到端一次完整同步：创建 → 读取 → 更新 → 删除', async () => {
  const { handle } = setup();

  assert.deepEqual((await handle(put(ID, 0, 'cipher-1'))).json, { rev: 1 });
  assert.deepEqual((await handle(get(ID))).json, { rev: 1, blob: 'cipher-1' });
  assert.deepEqual((await handle(put(ID, 1, 'cipher-2'))).json, { rev: 2 });
  assert.deepEqual((await handle(get(ID))).json, { rev: 2, blob: 'cipher-2' });
  assert.equal((await handle({ method: 'DELETE', syncId: ID, body: null })).status, 200);
  assert.equal((await handle(get(ID))).status, 404);
});
