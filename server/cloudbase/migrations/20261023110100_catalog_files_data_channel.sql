-- 数据通道（PostgREST 风格 HTTP 接口 /v1/rdb/rest）访问 catalog_files 所需权限与隔离。
--
-- 与 reg_snapshots 的差异（重要）：
--   · **读是公开的**：数据目录是公开的游戏资料，客户端匿名 GET 即可，
--     因此 SELECT 策略直接放通（USING (true)）。
--   · **写要密钥**：INSERT/UPDATE/DELETE 的策略校验自定义头 `x-tgg-catalog`，
--     该头只由云函数（持有环境变量 TGG_CATALOG_SECRET）附加。
--     策略本体由 scripts/set-catalog-secret.sh 注入，**不写进仓库**。
--
-- 多条 permissive 策略之间是 OR 关系，所以「SELECT 放通 + FOR ALL 校验密钥」
-- 的组合结果是：读不带头也能读，写必须带头。

GRANT SELECT, INSERT, UPDATE, DELETE ON public.catalog_files TO anon;

ALTER TABLE public.catalog_files ENABLE ROW LEVEL SECURITY;

-- 公开只读：任何匿名请求都能读（fail-open 仅限 SELECT）
DROP POLICY IF EXISTS tgg_catalog_read ON public.catalog_files;
CREATE POLICY tgg_catalog_read ON public.catalog_files
  FOR SELECT TO anon USING (true);

-- 写策略先删掉，等到注入密钥时再建（没有匹配策略 = 写 0 行，fail-closed）
DROP POLICY IF EXISTS tgg_catalog_gate ON public.catalog_files;
