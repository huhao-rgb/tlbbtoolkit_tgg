CREATE TABLE IF NOT EXISTS public.reg_snapshots (
  sync_id    text        PRIMARY KEY,
  rev        integer     NOT NULL DEFAULT 1 CHECK (rev >= 1),
  blob       text        NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE  public.reg_snapshots      IS '卡回归云同步：按 sync_id 存放客户端密文（服务端不解密）';
COMMENT ON COLUMN public.reg_snapshots.blob IS '客户端 AES-256-GCM 密文（Base64Url）';
COMMENT ON COLUMN public.reg_snapshots.rev  IS '乐观并发版本号：创建=1，每次成功写入 +1';
