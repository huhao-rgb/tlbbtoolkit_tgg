-- 分片上传的暂存表：HTTP 访问服务对**请求体**有 100 KiB 硬限制
-- （实测 102400 字节通过、105 KiB 返回 413 EXCEED_MAX_PAYLOAD_SIZE），
-- 而 pet.beast_spirits 之类的分片有 200+ KB，只能拆成多片上传。
--
-- 拆分只发生在**传输层**：云函数把各片按顺序拼回原文再写入 catalog_files，
-- 因此对客户端来说仍然是「一个 kind = 一个 JSON 文件」，契约不变。
--
-- 组装完成后立即删除对应分片，表里只会有短暂的中间态。

CREATE TABLE IF NOT EXISTS public.catalog_upload_parts (
  kind       text        NOT NULL,
  part       integer     NOT NULL CHECK (part >= 1),
  total      integer     NOT NULL CHECK (total >= 1),
  body       text        NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (kind, part)
);

COMMENT ON TABLE  public.catalog_upload_parts       IS '数据目录分片上传暂存（组装成功后即删除）';
COMMENT ON COLUMN public.catalog_upload_parts.part  IS '分片序号，从 1 开始';
COMMENT ON COLUMN public.catalog_upload_parts.total IS '本次上传的总片数';
