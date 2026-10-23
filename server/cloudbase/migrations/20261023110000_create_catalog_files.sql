-- 数据目录（catalog）：按分片（kind）存放客户端可远程更新的 JSON。
--
-- 设计要点：
--   · `body` 用 **text** 而不是 jsonb —— 必须原样保留发布时的字节，
--     客户端拿到的 sha256 才能与 manifest 里的值逐字节对上；
--     jsonb 会重排键序/去空格，哈希必然对不上。
--   · `kind` 是分片标识（`job.artifacts` / `pet.beast_spirits` …），
--     一个分片一行，天然支持「按 feature 分片、按需拉取」。
--   · `schema_version` 是**数据结构**版本（客户端能不能解析），
--     `data_version` 是**内容**版本（要不要更新），两者不要混用。

CREATE TABLE IF NOT EXISTS public.catalog_files (
  kind           text        PRIMARY KEY,
  schema_version integer     NOT NULL CHECK (schema_version >= 1),
  data_version   text        NOT NULL,
  body           text        NOT NULL,
  sha256         text        NOT NULL,
  bytes          integer     NOT NULL CHECK (bytes >= 0),
  updated_at     timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE  public.catalog_files                IS '数据目录：按分片存放可远程更新的 JSON 内容';
COMMENT ON COLUMN public.catalog_files.kind           IS '分片标识，如 job.artifacts / pet.beast_spirits';
COMMENT ON COLUMN public.catalog_files.schema_version IS '数据结构版本：客户端据此判断能否解析';
COMMENT ON COLUMN public.catalog_files.data_version   IS '内容版本：仅用于判断是否需要更新与问题定位';
COMMENT ON COLUMN public.catalog_files.body           IS '分片原始 JSON 文本（按字节原样保存，勿改为 jsonb）';
COMMENT ON COLUMN public.catalog_files.sha256         IS 'body 的 sha256（十六进制），客户端据此校验完整性';
COMMENT ON COLUMN public.catalog_files.bytes          IS 'body 的 UTF-8 字节数';
