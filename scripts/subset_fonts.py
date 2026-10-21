#!/usr/bin/env python3
"""生成随应用打包的字体子集（assets/fonts/*.ttf）。

背景：Noto Sans/Serif SC 全量字体每个 8~11 MB，5 个字重合计约 49 MB，
是 APK 体积的最大单项。应用实际用字远少于全集，按「源码用字 + GB2312
全集」裁剪后 5 个文件约 10 MB，省下约 38 MB。

字符集 = lib/ 下所有 Dart 源码出现的字符 ∪ GB2312 一二级汉字（6763 字）
        ∪ ASCII 可打印字符 ∪ 常用中英文标点。

- 源码用字保证「界面上写出来的字」一定有；GB2312 覆盖用户/网络数据
  （玩家名、服务器名、代售平台返回的文本）的绝大部分用字。
- 两者之外的生僻字交给系统字体回退（Flutter 在 Android/iOS 上会做
  fallback），不会出现豆腐块。

原始全量字体放在 tools/fonts/（不参与打包），本脚本从那里裁剪到
assets/fonts/。改了界面文案、且新字超出 GB2312 时需要重跑：

    pip install fonttools
    python3 scripts/subset_fonts.py

CI 用 --check 校验现有子集是否覆盖上述字符集（只查 cmap 覆盖，不比字节，
避免 fontTools 版本差异导致误报）：

    python3 scripts/subset_fonts.py --check
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

try:
    from fontTools import subset
    from fontTools.ttLib import TTFont
except ImportError:  # pragma: no cover
    sys.exit("缺少 fonttools：pip install fonttools")

ROOT = Path(__file__).resolve().parent.parent
SRC_DIR = ROOT / "tools" / "fonts"
OUT_DIR = ROOT / "assets" / "fonts"
SOURCE_DIRS = [ROOT / "lib"]

# 实际打包的字体（必须与 pubspec.yaml 的 fonts: 段一一对应）。
# 衬线只发 500 / 600：设计规范里 serif 只用于标题与强调，无 400 用字，
# 少打一个字体文件省约 2.3 MB。原件仍留在 tools/fonts/，需要时可加回来。
SHIP_FONTS = [
    "NotoSansSC-Regular.ttf",
    "NotoSansSC-Medium.ttf",
    "NotoSerifSC-Medium.ttf",
    "NotoSerifSC-SemiBold.ttf",
]

# 常用标点/符号（中英文），字号阶梯里的 · — … “ ” ‘ ’ ￥ ％ 等都在其中。
EXTRA_CHARS = (
    "".join(chr(c) for c in range(0x20, 0x7F))  # ASCII 可打印
    + "　，。、；：？！“”‘’（）【】《》〈〉「」『』〔〕—…·～￥％°℃±×÷≈≠≤≥←→↑↓"
    + "①②③④⑤⑥⑦⑧⑨⑩"
)


def gb2312_chars() -> str:
    """GB2312 一二级汉字（6763 字），覆盖现代简体中文绝大部分用字。"""
    chars = []
    for b1 in range(0xA1, 0xF8):
        for b2 in range(0xA1, 0xFF):
            try:
                chars.append(bytes([b1, b2]).decode("gb2312"))
            except UnicodeDecodeError:
                continue
    return "".join(chars)


def source_chars() -> str:
    chars: set[str] = set()
    for directory in SOURCE_DIRS:
        for path in directory.rglob("*.dart"):
            chars.update(path.read_text(encoding="utf-8", errors="ignore"))
    return "".join(sorted(chars))


def charset() -> str:
    return "".join(dict.fromkeys(source_chars() + gb2312_chars() + EXTRA_CHARS))


def source_fonts() -> list[Path]:
    missing = [n for n in SHIP_FONTS if not (SRC_DIR / n).exists()]
    if missing:
        sys.exit(f"缺少原始字体：{', '.join(missing)}（应位于 {SRC_DIR}）")
    return [SRC_DIR / n for n in SHIP_FONTS]


def build(text: str) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for src in source_fonts():
        out = OUT_DIR / src.name
        options = subset.Options()
        options.glyph_names = False
        options.layout_features = ["*"]  # 保留 kerning 等排版特性
        options.name_IDs = ["*"]
        options.notdef_outline = True
        options.recalc_bounds = True

        font = TTFont(src)
        subsetter = subset.Subsetter(options=options)
        subsetter.populate(text=text)
        subsetter.subset(font)
        font.save(out)

        src_mb = src.stat().st_size / 1048576
        out_mb = out.stat().st_size / 1048576
        print(f"{src.name:32s} {src_mb:6.2f} MB -> {out_mb:5.2f} MB")


def check(text: str) -> int:
    missing_report: list[str] = []
    for src in source_fonts():
        out = OUT_DIR / src.name
        if not out.exists():
            missing_report.append(f"{src.name}: 子集缺失，请运行 scripts/subset_fonts.py")
            continue
        # 原字体本身没有的字形（如 emoji）由系统字体回退，不算缺失。
        src_cmap = TTFont(src).getBestCmap()
        cmap = TTFont(out).getBestCmap()
        missing = sorted({c for c in text if ord(c) in src_cmap and ord(c) not in cmap})
        if missing:
            sample = "".join(missing[:40])
            missing_report.append(
                f"{src.name}: 缺 {len(missing)} 个字符，例如「{sample}」"
            )

    if missing_report:
        print("字体子集待更新：", file=sys.stderr)
        for line in missing_report:
            print("  " + line, file=sys.stderr)
        print("\n请运行：python3 scripts/subset_fonts.py", file=sys.stderr)
        return 1

    print("字体子集覆盖检查通过")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="生成 / 校验字体子集")
    parser.add_argument(
        "--check",
        action="store_true",
        help="只校验现有子集的字符覆盖，不写文件",
    )
    args = parser.parse_args()

    text = charset()
    print(f"字符集：{len(text)} 个字符")
    if args.check:
        return check(text)
    build(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
