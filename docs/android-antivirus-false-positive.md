# Android 发行包被手机管家报毒：判定、自助校验与申诉

> 面向两类读者：**装包的用户**（会不会中毒、怎么放行）与**维护者**（怎么根治、怎么申诉）。
> 本文所有数字均来自 2026-11 对 v1.2.1 正式发行包的实测，可逐条复现。

---

## 1. 一句话结论

`Android.Virus.Gray.BulimiaTGen.F.EYXW.Malware` 是**腾讯病毒库的启发式灰色软件标签**，
由「个人自签证书 + 未上架应用商店 + 从 GitHub 侧载分发」这类**结构性特征**触发，
不是扫描到了恶意代码。使用腾讯病毒库的厂商（华为、荣耀、小米、OPPO、vivo）会同时报，
所以换一台手机也照样弹窗。

## 2. 检出名怎么读

| 片段 | 含义 |
| --- | --- |
| `Gray` | **灰色软件**（grayware）：介于正常软件与恶意软件之间的"来源不明"档 |
| `BulimiaTGen` | 腾讯移动安全实验室的**泛化特征家族**，`TGen` = 通用生成特征，靠聚类判定 |
| `.F` / `EYXW` | 变种编号、厂商内部流水号 |
| `.Malware` | 展示层统一附加的"恶意"字样 |

`a.gray.*` 家族还常出现在自编译的 Firefox、个人开发者小工具、甚至用了加固的 App 上。
详情页里"占用系统资源 / 捆绑安装 / 修改系统配置 / 频繁发送骚扰信息"是**家族通用模板文案**，
不是对某个包的实测结论。

## 3. 本包的实际能力（对 v1.2.1 发行包实测）

| 检查项 | 结果 |
| --- | --- |
| 申请权限 | 只有 `INTERNET`，外加 androidx 自动生成的 `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`（自定义、非系统权限） |
| 未申请 | 无障碍、通知监听、短信、通讯录、位置、悬浮窗、开机自启、安装未知应用 —— **一条都没有** |
| dex 动态加载 / 执行 | `DexClassLoader` / `Runtime.exec` / `PathClassLoader` 检索 **0 命中** |
| 广告 / 统计 SDK | 无。依赖为 Riverpod、go_router、dio、shared_preferences、share_plus 等常规包 |
| 应用内安装 APK 能力 | 无（不下载、不调 PackageInstaller） |

复现命令：

```bash
# 1) 权限
aapt2 dump badging TiangongGe-<版本>-arm64.apk | grep uses-permission

# 2) dex 里的动态加载痕迹（应为 0）
unzip -o -q TiangongGe-<版本>-arm64.apk -d /tmp/apkx 'classes*.dex'
for f in /tmp/apkx/classes*.dex; do strings "$f" | grep -cE 'DexClassLoader|Runtime;->exec'; done
```

## 4. 用户侧：装之前核对，被拦了怎么放行

### 4.1 核对下载是否完整、签名是否为本项目

每个 Release 页面底部都附有该版本的 **SHA-256** 与**证书指纹**，由 CI 在打包后当场输出
（见 `.github/workflows/release.yml` 的「记录校验信息」步骤）。

```powershell
# Windows PowerShell
Get-FileHash .\TiangongGe-<版本>-arm64.apk -Algorithm SHA256
```

```bash
# macOS / Linux
shasum -a 256 TiangongGe-<版本>-arm64.apk
```

证书指纹（APK 签名的 SHA-256）应恒为：

```
50:80:19:30:1B:E0:1B:A5:2B:56:E4:A7:A8:85:E7:B0:B5:A2:65:6C:9E:0A:88:40:29:FE:13:22:11:DB:59:94
```

签名主体：`CN=TLBB Toolkit, OU=Mobile, O=HuHao, L=Beijing, ST=Beijing, C=CN`

```bash
# 自行验证（需 Android SDK build-tools）
apksigner verify --print-certs TiangongGe-<版本>-arm64.apk
```

> ⚠️ 自行用源码重建的包，哈希**必然**与发行包不同（CI 注入了 `--dart-define`、
> 构建环境也不同），指纹则应完全一致。请以 Release 页数值为唯一基准。
> **不要从第三方转存链接下载**——那类包随时可能被替换，哈希校验是唯一防线。

### 4.2 被拦截时怎么点

在拦截详情页点 **「加入白名单」/「信任」/「忽略」**（不同厂商叫法不同），即可正常使用。

**不要点「卸载」**：本地数据（卡回归账号名单、导入的音乐等）存在应用私有目录，
且 `allowBackup="false"`，卸载后无法恢复，只能从头录入。

另外注意：华为 / 荣耀在"风险未处理"状态下，可能连带拦截银行、支付类 App 的启动，
所以别放着不管，白名单点掉即可。

## 5. 维护者侧：怎么让它不再报

按性价比排序：

1. **误报申诉**（最快见效）：腾讯手机管家 / 腾讯安全实验室的误报申诉入口提交原 APK 与
   材料（见下方模板）。受理后约一周病毒库更新，各厂商随同步周期跟进（通常再延几天）。
2. **上架正规商店**：华为 AppGallery Connect、小米开放平台、OPPO / vivo 开放平台。
   这是权重最高的一条——上架即脱离"未上架侧载"这一触发特征。
3. **稳住签名**：继续使用同一个 keystore。换证书 = 换 App 身份，老用户无法覆盖安装，
   且重新进入"新样本"观察期。
4. **不要为了消警报去做加固/混淆**：有大量实证显示 360 / 腾讯加固反而更容易撞上
   `a.gray.*` 泛化特征。本项目「权限极简 + 无 APK 安装能力」已是正确姿势。
5. **把校验信息前置**：CI 已把证书指纹与 APK SHA-256 写进 Actions 的 Job Summary、
   Release 正文，并附 `SHA256SUMS.txt`，用户与厂商都可查。

> 想进一步收紧：在仓库 Settings → Variables 配 `ANDROID_CERT_SHA256`（值见 4.1），
> CI 会在发布前比对证书指纹，防止 Secrets 里被换成另一把 keystore 而静默发出不兼容的包。

## 6. 附：误报申诉材料模板

> 提交处：腾讯手机管家 / 腾讯安全（移动安全检测与误报申诉入口）。
> 提交时**附上原 APK 文件**，正文可直接套用下面内容，把尖括号替换成实际值。

```text
应用名称：天工阁（TiangongGe）
包名：me.huhao.tools.tlbbtoolkit
版本：1.2.1（versionCode 12）
APK：TiangongGe-1.2.1-arm64.apk，20,216,417 字节
SHA-256：f0e989cbfd6175cc8b6bb0996cd3b74d6eb98d6db6d1e4203360c97d6dbd8288
签名证书：CN=TLBB Toolkit, OU=Mobile, O=HuHao, L=Beijing, ST=Beijing, C=CN
证书 SHA-256：50:80:19:30:1B:E0:1B:A5:2B:56:E4:A7:A8:85:E7:B0:B5:A2:65:6C:9E:0A:88:40:29:FE:13:22:11:DB:59:94
开源仓库：https://github.com/huhao-rgb/tlbbtoolkit_tgg
分发渠道：GitHub Releases（无应用商店上架，个人开发者）

检出结果：Android.Virus.Gray.BulimiaTGen.F.EYXW.Malware（风险等级：高）

申诉说明：
1. 该应用为天龙八部辅助查询工具（离线数据查询、计算器、音乐播放），不含任何广告、
   统计或第三方 SDK，未接入任何支付与账号体系。
2. AndroidManifest 仅申请 android.permission.INTERNET 一项系统权限；未申请无障碍服务、
   通知监听、短信、通讯录、位置、悬浮窗、开机自启、REQUEST_INSTALL_PACKAGES 等敏感权限，
   客观上不具备"修改系统配置""捆绑安装""频繁发送骚扰信息"的能力。
3. 应用内不存在 APK 下载与安装逻辑，不调用 PackageInstaller；dex 中检索
   DexClassLoader / Runtime.exec / PathClassLoader 均为 0 命中。
4. 全部源码公开可审计，构建由 GitHub Actions 完成（.github/workflows/release.yml），
   签名证书指纹自首个版本起未变更。
5. 应用因未上架应用商店且使用个人自签证书，被 a.gray.BulimiaTGen 泛化特征命中，
   属结构性误报。

请求：请复核该样本并解除上述检出标记。如需补充材料（源码片段、构建日志、
原始密钥所有权证明）可随时提供。
```
