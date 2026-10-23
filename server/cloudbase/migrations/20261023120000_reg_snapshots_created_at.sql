-- 给 synced 记录补 created_at：用于「每日创建上限」的防滥用护栏。
--
-- 背景：`/reg` 的创建（PUT rev=0）是唯一不需要任何凭证的写操作，
-- 服务地址公开后可能被脚本刷记录、打满配额。限制「每 24h 全站新建条数」
-- 可以把成本封顶，而正常用户远达不到阈值。
--
-- 为什么不用 updated_at：更新也会刷新它，统计出来的是「写入次数」而不是「新建条数」。
--
-- 先回填历史行再设 NOT NULL，避免迁移期间锁表报错。

ALTER TABLE public.reg_snapshots ADD COLUMN IF NOT EXISTS created_at timestamptz;

UPDATE public.reg_snapshots
   SET created_at = updated_at
 WHERE created_at IS NULL;

ALTER TABLE public.reg_snapshots ALTER COLUMN created_at SET DEFAULT now();
ALTER TABLE public.reg_snapshots ALTER COLUMN created_at SET NOT NULL;

CREATE INDEX IF NOT EXISTS reg_snapshots_created_at_idx
  ON public.reg_snapshots (created_at);

COMMENT ON COLUMN public.reg_snapshots.created_at IS '首次创建时间（用于每日创建上限统计）';
