-- 分片上传暂存表的权限与隔离（与 catalog_files 同策略：读不需要，写要密钥）。
--
-- 这张表**不对外暴露**：没有公开读策略，只有携带 `x-tgg-catalog` 的写操作能被放行，
-- 且读操作同样受 RLS 约束（无策略 = 读 0 行），函数自身可读是因为它带密钥头。

GRANT SELECT, INSERT, UPDATE, DELETE ON public.catalog_upload_parts TO anon;

ALTER TABLE public.catalog_upload_parts ENABLE ROW LEVEL SECURITY;

-- 策略本体由 scripts/set-catalog-secret.sh 注入（密钥不进仓库）
DROP POLICY IF EXISTS tgg_catalog_parts_gate ON public.catalog_upload_parts;
