# 第三方组件与素材声明

本仓库的原创代码以根目录 [LICENSE](LICENSE)（MIT）授权。以下第三方内容遵循各自的许可条款。

## 字体

`assets/fonts/` 与 `installer/assets/fonts/` 中的 Noto 字体是 **Google Noto** 的子集
（按「源码用字 ∪ GB2312」裁剪），遵循 **SIL Open Font License 1.1**：

| 文件 | 来源 | 许可 |
| --- | --- | --- |
| `NotoSansSC-Regular.ttf` / `NotoSansSC-Medium.ttf` | Noto Sans SC | SIL OFL 1.1 |
| `NotoSerifSC-Medium.ttf` / `NotoSerifSC-SemiBold.ttf` | Noto Serif SC | SIL OFL 1.1 |

OFL 1.1 允许打包、嵌入与再分发（含子集化），要求保留版权声明、不得单独售卖字体本身。
完整文本见 <https://openfontlicense.org/open-font-license-official-text/>。

## Dart / Flutter 依赖

`pubspec.yaml` 与 `installer/pubspec.yaml` 中声明的依赖各自遵循其许可（MIT / BSD / Apache-2.0 等），
可用 `fvm dart pub deps` 或 <https://pub.dev> 查证。Flutter SDK 本身为 BSD-3-Clause。

## 游戏相关素材

`assets/beast_soul/`、`assets/skill_icons/`、`assets/wudao_icons/`、`assets/pet_suit/`、
`assets/splash/`、`assets/logo/` 以及 `lib/features/**/domain/` 下的数据表，包含
《天龙八部》相关的名称、图标与数值信息。

- 上述内容的著作权归原著权利方与游戏运营方所有，**不在本仓库 MIT 授权范围内**；
- 本仓库与游戏官方无隶属关系，仅作非商业性的玩家工具用途；
- 如需商用或再分发这些素材，请自行取得权利方许可。

## 安装器

`installer/` 是本仓库的一部分，同样适用 MIT 许可；其运行时依赖见
`installer/pubspec.yaml`。安装器内置的 NSIS 脚本（`installer/tool/setup_sfx.nsi`）在构建时
使用 NSIS（zlib/libpng 许可）编译，NSIS 本身不随本仓库分发。
