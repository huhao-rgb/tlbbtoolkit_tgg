#!/usr/bin/env python3
"""架构边界检查（CI 用）。

对应 `docs/ARCHITECTURE.md` 的单向依赖约定：

1. `lib/features/<a>/` 不得 import `lib/features/<b>/`（a != b）；
2. `lib/core` 与 `lib/shared` 不得 import 任何 `lib/features/...`；
3. `lib/features/<x>/domain/` 不得 import 同 feature 的 `data/` 或 `presentation/`。

生成文件（`*.g.dart` / `*.freezed.dart`）不参与检查。
用法：`python3 scripts/check_feature_boundaries.py`
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"
FEATURES = LIB / "features"

FEATURE_IMPORT = re.compile(
    r"""import\s+['"]package:tlbbtoolkit/features/([a-z_]+)/([^'"]*)['"]"""
)
SKIP_SUFFIXES = (".g.dart", ".freezed.dart")


def dart_files(base: Path):
    for path in base.rglob("*.dart"):
        if path.name.endswith(SKIP_SUFFIXES):
            continue
        yield path


def main() -> int:
    problems: list[str] = []

    for path in dart_files(FEATURES):
        rel = path.relative_to(FEATURES)
        owner = rel.parts[0]
        source = path.read_text(encoding="utf-8")
        for match in FEATURE_IMPORT.finditer(source):
            target, tail = match.group(1), match.group(2)
            if target != owner:
                problems.append(
                    f"{path.relative_to(ROOT)} 跨 feature 引用 features/{target}/{tail}"
                )
        if len(rel.parts) >= 3 and rel.parts[1] == "domain":
            if re.search(
                r"""import\s+['"]package:tlbbtoolkit/features/[a-z_]+/(data|presentation)/""",
                source,
            ):
                problems.append(
                    f"{path.relative_to(ROOT)} domain 反向依赖 data/presentation"
                )

    for layer in (LIB / "core", LIB / "shared"):
        for path in dart_files(layer):
            source = path.read_text(encoding="utf-8")
            if FEATURE_IMPORT.search(source):
                problems.append(
                    f"{path.relative_to(ROOT)} {layer.name}/ 反向依赖 features/"
                )

    if problems:
        print("架构边界检查失败：", file=sys.stderr)
        for item in problems:
            print(f"  - {item}", file=sys.stderr)
        return 1

    print("架构边界检查通过（feature 隔离 / core・shared 无反向依赖 / domain 无反向依赖）")
    return 0


if __name__ == "__main__":
    sys.exit(main())
