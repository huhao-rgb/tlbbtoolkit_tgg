-- 数据通道（PostgREST 风格 HTTP 接口 /v1/rdb/rest）访问 reg_snapshots 所需的权限与隔离。
--
-- 背景：云函数不再用连接串直连数据库，而是以「函数自身身份」走平台数据通道。
-- 该通道里请求的数据库角色是 PostgREST 的 `anon`，因此必须：
--   1) 给 anon 授予本表所需的四个权限（否则写操作报 401 permission denied）；
--   2) 开启 RLS 并用策略校验自定义头 `x-tgg-sync`，
--      让**不带该头**的外部匿名请求读到 0 行、写 0 行（实测验证过）。
--
-- 注意：策略里的密钥**不能写进仓库**。本迁移只做「授权 + 开 RLS」，
-- 策略本体由 scripts/set-channel-secret.sh 注入（该脚本从环境变量/交互输入读取密钥）。
-- 表 owner 绕过 RLS，因此运维/CLI 侧不受影响。

GRANT SELECT, INSERT, UPDATE, DELETE ON public.reg_snapshots TO anon;

ALTER TABLE public.reg_snapshots ENABLE ROW LEVEL SECURITY;

-- 没有匹配策略时 anon 读写均为 0 行（fail-closed），
-- 因此先删旧策略，再由 set-channel-secret.sh 建新策略。
DROP POLICY IF EXISTS tgg_sync_gate ON public.reg_snapshots;
