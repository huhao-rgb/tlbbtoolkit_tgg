# 卡回归云同步 · 云函数（CloudBase）

「哑存储 + 乐观并发」的云同步后端。服务端**只见密文**：载荷由客户端用
AES-256-GCM 加密，密钥只存在用户设备的安全存储里，从不上传。

- 云函数 `reg-sync` 提供 4 个接口（GET/PUT/DELETE + OPTIONS 预检）；
- 数据存在 PostgreSQL 表 `public.reg_snapshots`；
- 访问数据库**不用连接串、不开公网**，走平台的**数据通道**（见下）。

## 当前部署状态

| 项 | 值 |
| --- | --- |
| 环境 ID | `tgg-account-d8gd8q1mc16b81044`（ap-shanghai，体验版） |
| 接口地址 | `https://tgg-account-d8gd8q1mc16b81044.service.tcloudbase.com/reg` |
| 云函数 | `reg-sync` · Nodejs20.19 · 256MB · 5s · **云端安装依赖** |
| 数据表 | `public.reg_snapshots`（owner = `cloudbase_postgres_postgres_dkwh6dfq`） |
| 数据库 | PostgreSQL 17.11 · 共享集群（**无内网地址**，也**不需要**开外网） |
| 数据库访问 | 平台数据通道 `/v1/rdb/rest`（PostgREST 风格），函数自身身份 + `x-tgg-sync` 密钥头 |
| 授权 | `anon` 授予 SELECT/INSERT/UPDATE/DELETE + **RLS 策略**校验密钥头 |
| 函数环境变量 | `TGG_SYNC_SECRET`（通道密钥；**已配置**） |
| HTTP 路由 | `*` `/reg` → SCF `reg-sync` · 匿名访问 · 限流 100 QPS / 单 IP 20 QPS |
| 契约验收 | `scripts/verify-deployment.sh` → **21/21 通过** |

## 接口契约

```
GET    {path}?code=<syncId>              → 200 {rev, blob} | 404 {error:not_found}
PUT    {path}?code=<syncId>  {rev, blob} → 200 {rev}       | 409 {error:conflict, rev}
DELETE {path}?code=<syncId>              → 200 {ok:true}
```

失败响应**只回错误码，不回主机名/账号/密钥**（详细错误只进云函数日志）：

| 响应 | 含义 |
| --- | --- |
| `400` `invalid_sync_id` / `invalid_rev` / `invalid_blob` | 请求参数不合法（不依赖配置） |
| `409` `conflict` | `rev` 不匹配，客户端重拉 → 合并 → 重试 |
| `413` `blob_too_large` | 密文超过 256KB |
| `500` `db_not_configured` + `missing[]` | 缺 `TGG_SYNC_SECRET`（通道密钥没配） |
| `503` `db_unreachable` + `code` | 数据通道网络层不通（超时/DNS/连接被拒） |
| `500` `db_error` + `code` | 通道通了但被数据库拒绝（如 `DATABASE_42501` 权限不足） |
| `500` `internal_error` | 兜底，细节看云函数日志 |

## 目录结构

```
server/
├── cloudbaserc.json                       # CLI 配置（envId / functionRoot / 函数参数）
└── cloudbase/
    ├── functions/reg-sync/
    │   ├── handler.js                     # 纯请求逻辑（零云依赖，可本地单测）
    │   ├── handler.test.js
    │   ├── index.js                       # CloudBase 适配层 + 数据通道存储 + 错误归类
    │   ├── index.test.js                  # 存储映射与错误归类单测
    │   └── package.json                   # 依赖仅 @cloudbase/node-sdk
    ├── migrations/
    │   ├── 20261012080638_create_reg_snapshots.sql
    │   └── 20261012100113_reg_snapshots_data_channel.sql   # 授权 + 开 RLS
    └── scripts/
        ├── deploy.sh                      # 单测 → 部署 → **字节校验** → 契约验收
        ├── set-channel-secret.sh          # 设置/轮换通道密钥（写入 RLS 策略）
        └── verify-deployment.sh           # 21 项契约验收
```

## 数据通道：为什么不用连接串、不开公网

本环境的数据库是 **共享集群**，控制台「网络配置」里**内网地址是 `-`**，
而云函数也**没有配 VPC** —— 两条路都不通，直连就必须开公网（付费）。

但云函数本来就有**平台身份**，可以走平台自己的数据接口：

| 事实 | 实测依据 |
| --- | --- |
| 运行时自动注入凭据 | `TENCENTCLOUD_SECRETID/SECRETKEY/SESSIONTOKEN` 出现在函数环境变量里 |
| 换 token 成功 | `app.auth().getClientCredential()` 返回 `access_token` |
| 数据接口可用 | 请求 `https://<envId>.api.tcloudbasegateway.com/v1/rdb/rest/reg_snapshots` 返回 200 |
| 反直觉点 | 该 SDK 的 `database` 参数实际是 PostgREST 的 **schema**：必须传 `database: 'public'`，否则报 `406 Invalid schema: <envId>` |
| 请求身份 | PostgREST 里是 `anon` 角色（`current_user = anon`），所以需要授权 + RLS |
| 自定义头可穿过网关 | 临时回声函数里读到 `request.headers->>'x-tgg-sync'` = 我们发出去的值 |
| 不带密钥头被隔离 | 同一张表：带密钥头 select=1 行 / 不带=0 行；不带密钥头 DELETE 影响 0 行 |

因此：**0 成本、不开公网、函数里没有数据库密码**，只需要一个通道密钥。

## 一次性配置：通道密钥

密钥只存在于**两处**，必须一致：

1. **数据库 RLS 策略**（`scripts/set-channel-secret.sh` 写入）
2. **云函数环境变量 `TGG_SYNC_SECRET`**（控制台 → 云函数 → reg-sync → 配置 → 环境变量）

设置或轮换（两条命令要一起改，改完立刻生效，无需重新部署）：

```sh
cd server

# 1) 写入 RLS 策略（密钥从环境变量或交互输入读取，不落仓库、不进历史命令）
TGG_SYNC_SECRET='<新密钥>' ./cloudbase/scripts/set-channel-secret.sh

# 2) 把同一个值填进函数环境变量（控制台操作；CLI 只能从 cloudbaserc.json 推，
#    而密钥不允许进仓库，所以这一步必须在控制台做）
```

> ⚠️ 密钥是**唯一**的访问闸门：知道它（加上环境网关地址）就能读写这张表。
> 不要贴进聊天记录、issue、截图。若怀疑泄露，按上面两步轮换一次即可。

## 数据库侧改动（随迁移版本化）

`20261012100113_reg_snapshots_data_channel.sql` 做三件事：

```sql
GRANT SELECT, INSERT, UPDATE, DELETE ON public.reg_snapshots TO anon;
ALTER TABLE public.reg_snapshots ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tgg_sync_gate ON public.reg_snapshots;   -- 策略由脚本注入
```

**这个迁移刻意不建策略**，所以应用之后表是 fail-closed（谁都读写不了），
必须紧接着跑 `set-channel-secret.sh` 建策略。顺序：

```sh
tcb db pg migration up                              # 授权 + 开 RLS
TGG_SYNC_SECRET='...' ./cloudbase/scripts/set-channel-secret.sh   # 建策略
tcb fn deploy reg-sync --path /reg --force          # 部署函数
./cloudbase/scripts/verify-deployment.sh https://tgg-account-d8gd8q1mc16b81044.service.tcloudbase.com
```

> 表 owner（`cloudbase_postgres_postgres_dkwh6dfq`）**绕过 RLS**，
> 所以运维侧 `tcb db execute` / 迁移不受策略影响。

## 日常操作

所有 tcb 命令都在 **`server/`** 目录下执行（该目录同时是 `cloudbaserc.json`
与 `cloudbase/migrations` 的基准目录）：

```sh
cd server

# 推荐：一条命令完成「单测 → 部署 → 字节校验 → 契约验收」
./cloudbase/scripts/deploy.sh
./cloudbase/scripts/deploy.sh --skip-tests    # 只跳单测，校验仍然执行

# 原始命令（⚠️ 见下方「部署后必须校验」：它会打印成功但可能没生效）
tcb fn deploy reg-sync --path /reg --force

# 首次部署/搬迁时绑定 HTTP 访问路径（会自动放通并打印访问地址）
# 注意：系统默认域名不允许 `tcb routes add` 手工加路由，必须用这个参数
tcb fn deploy reg-sync --path /reg --force

# 迁移
tcb db pg migration list            # 看本地与远端差异
tcb db pg migration up --dry-run    # 预览
tcb db pg migration up              # 应用
tcb db pg migration new <name>      # 新建迁移

# 管理侧直连跑 SQL（走平台 API，非函数内）
tcb db execute --sql "SELECT count(*) FROM public.reg_snapshots"
tcb db execute --sql "SELECT has_table_privilege('anon','public.reg_snapshots','SELECT')"

# 看 HTTP 路由
tcb routes list
```

### ⚠️ 部署后必须校验（踩过的坑）

实测遇到过一次：`tcb fn deploy` 打印 `Cloud function deployed successfully!`，
但**云端代码根本没更新**（`tcb fn code download` 拉回来仍是旧文件，连旧的 `pg`
依赖都还在），接口继续按旧逻辑报错。当时是通过「响应体列出了早已删除的 `PGHOST`
等变量」才发现的 —— 只看部署输出会被骗。

所以：**措辞不可信，字节可信**。`deploy.sh` 的第 3 步会把云端产物拉回来逐文件比对 md5，
不一致就非 0 退出：

```
▶ 3/4 校验云端代码与本地一致
   ✅ index.js 一致（b27b4eea…）
   ✅ handler.js 一致（405166bc…）
   ✅ package.json 一致（9d5a879a…）
```

手工校验（不想用脚本时）：

```sh
cd server
TMP=$(mktemp -d)
tcb fn code download reg-sync "$TMP"
md5 -q cloudbase/functions/reg-sync/index.js "$TMP/index.js"   # 两行应相同
```

另外**部署不会动环境变量**（`cloudbaserc.json` 里没有 `envVariables` 时保持云端原值），
但配置变更后建议顺手确认一次：

```sh
tcb fn detail reg-sync | grep -c TGG_SYNC_SECRET    # 期望 ≥1
```

### 新增迁移的约定

迁移文件放在 `server/cloudbase/migrations/`（CLI 生成时间戳前缀），随仓库提交。
**不要**在生产库上手工改表——否则本地与远端迁移历史会漂移。

## 本地测试

纯逻辑与存储映射都不依赖云 SDK 真实凭据，也**不需要 Postgres**：

```sh
cd server/cloudbase/functions/reg-sync && npm test   # 25 passed（handler 10 + index 15）
```

覆盖：404/409 语义、条件更新不丢更新、参数校验、超大 blob、DELETE 幂等、CORS、
存储映射（`create` 的 409→冲突、`compareAndSet` 必须带 `rev=eq.N` 过滤）、
**请求必须带密钥头**（RLS 依赖）、错误归类（`db_unreachable` vs `db_error`）、
**响应不得回显密钥/主机名**。

## 正确性依据

并发正确性靠**单条语句的原子性**，不需要「先查后写」，因此天然免疫竞态：

| 操作 | 通道语句 | 判定 |
| --- | --- | --- |
| `create` | `POST /reg_snapshots`（`sync_id` 是主键） | 201 → 成功（rev=1）；**409 `duplicate key` → 已存在** |
| `compareAndSet` | `PATCH /reg_snapshots?sync_id=eq.X&rev=eq.N` | 返回 1 行 → 新 rev；**返回 0 行 → rev 不匹配** |
| `remove` | `DELETE /reg_snapshots?sync_id=eq.X` | 幂等，0 行也算成功 |

PATCH 的 `rev=eq.N` 过滤条件本身就是 CAS —— 单测里专门断言了这个条件存在
（漏了它就会退化成「无条件覆盖」，是最危险的回归）。

## 安全与边界

- **端到端加密**：服务端只见密文，拖库/内网取证也拿不到账号名单；
- **匿名接口**：安全模型是「128 位随机 syncId + 客户端加密」，猜中概率可忽略（2^128）；
- **数据通道默认关闭**：RLS 策略要求 `x-tgg-sync` 头，实测**不带该头时
  select 返回 0 行、delete 影响 0 行**，外部匿名请求拿不到任何东西；
- **网关限流**：100 QPS 总 / 单 IP 20 QPS（`tcb routes edit` 配置）；
- **载荷上限**：单条密文 256KB（`handler.js` 的 `MAX_BLOB_BYTES`）；
- **密钥管理**：`TGG_SYNC_SECRET` 只在函数环境变量与 RLS 策略里，
   **不进仓库、不进代码**；轮换见「一次性配置」；
- ⚠️ **`tcb fn detail <fn>` 会明文打印环境变量（含 `TGG_SYNC_SECRET`、以及当年配过的 `PGPASSWORD`）**。
  截图/贴日志前先过滤，例如：
  `tcb fn detail reg-sync | grep -oE "TGG_SYNC_SECRET=.*" >/dev/null && echo "已配置"`。
  密钥一旦出现在聊天记录或 issue 里，按「一次性配置」轮换一次。
  另注：`tcb fn env pull` 会把整套环境变量落到本地文件，**不要**在仓库目录里执行；
- **不再需要的旧变量**：`PGHOST`/`PGPORT`/`PGDATABASE`/`PGUSER`/`PGPASSWORD`/`PGSSL`
  在本方案里已废弃，建议在控制台删掉（尤其 `PGPASSWORD`）。
- **无账号体系**：没有针对性的用户级配额，滥用者只能污染自己的记录，代价是消耗函数额度；
  若日后开放更敏感的数据，应加上鉴权与按用户配额。
