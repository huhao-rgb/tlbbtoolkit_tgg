#!/usr/bin/env bash
# 设置/轮换「数据目录写密钥」：把 catalog_files 的 RLS 写策略更新为比对新的 `x-tgg-catalog` 头的值。
#
# 密钥只存在于两处，必须一致：
#   1) 数据库 RLS 策略（本脚本写入）
#   2) 云函数环境变量 TGG_CATALOG_SECRET（控制台 → 云函数 → catalog → 配置 → 环境变量）
#
# 读是公开的（迁移里已建 tgg_catalog_read 策略），本脚本只管写。
#
# 用法：
#   TGG_CATALOG_SECRET='<新密钥>' ./cloudbase/scripts/set-catalog-secret.sh   # 非交互
#   ./cloudbase/scripts/set-catalog-secret.sh                                 # 交互输入（不回显）
set -euo pipefail

cd "$(dirname "$0")/../.."   # 到 server/（cloudbaserc.json 所在目录）

SECRET="${TGG_CATALOG_SECRET:-}"
if [ -z "$SECRET" ]; then
  printf '请输入新的目录写密钥（输入不回显）: '
  read -rs SECRET
  echo
fi
if [ -z "$SECRET" ]; then
  echo "密钥为空，已取消。" >&2
  exit 1
fi

# 基本校验：避免引号/分号破坏 SQL
case "$SECRET" in
  *"'"*|*';'*|*$'\n'*) echo "密钥不能包含单引号、分号或换行。" >&2; exit 1 ;;
esac

# catalog_files：SELECT 由 tgg_catalog_read 放通，写由 tgg_catalog_gate 校验密钥
tcb db execute -s "DROP POLICY IF EXISTS tgg_catalog_gate ON public.catalog_files; CREATE POLICY tgg_catalog_gate ON public.catalog_files FOR ALL TO anon USING (current_setting('request.headers', true)::jsonb->>'x-tgg-catalog' = '$SECRET') WITH CHECK (current_setting('request.headers', true)::jsonb->>'x-tgg-catalog' = '$SECRET')"

# catalog_upload_parts：没有公开读，读写都必须带密钥（大分片上传的暂存表）
tcb db execute -s "DROP POLICY IF EXISTS tgg_catalog_parts_gate ON public.catalog_upload_parts; CREATE POLICY tgg_catalog_parts_gate ON public.catalog_upload_parts FOR ALL TO anon USING (current_setting('request.headers', true)::jsonb->>'x-tgg-catalog' = '$SECRET') WITH CHECK (current_setting('request.headers', true)::jsonb->>'x-tgg-catalog' = '$SECRET')"

echo "✅ 写策略已更新。别忘了把同一个值填进云函数环境变量 TGG_CATALOG_SECRET。"
