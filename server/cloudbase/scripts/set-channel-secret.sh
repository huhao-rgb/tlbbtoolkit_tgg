#!/usr/bin/env bash
# 设置/轮换「数据通道密钥」：把 reg_snapshots 的 RLS 策略更新为比对新的 `x-tgg-sync` 头的值。
#
# 密钥只存在于两处，必须一致：
#   1) 数据库 RLS 策略（本脚本写入）
#   2) 云函数环境变量 TGG_SYNC_SECRET（控制台 → 云函数 → reg-sync → 配置 → 环境变量）
#
# 用法：
#   TGG_SYNC_SECRET='<新密钥>' ./cloudbase/scripts/set-channel-secret.sh   # 非交互
#   ./cloudbase/scripts/set-channel-secret.sh                              # 交互输入（不回显）
set -euo pipefail

cd "$(dirname "$0")/../.."   # 到 server/（cloudbaserc.json 所在目录）

SECRET="${TGG_SYNC_SECRET:-}"
if [ -z "$SECRET" ]; then
  printf '请输入新的通道密钥（输入不回显）: '
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

tcb db execute -s "DROP POLICY IF EXISTS tgg_sync_gate ON public.reg_snapshots; CREATE POLICY tgg_sync_gate ON public.reg_snapshots FOR ALL TO anon USING (current_setting('request.headers', true)::jsonb->>'x-tgg-sync' = '$SECRET') WITH CHECK (current_setting('request.headers', true)::jsonb->>'x-tgg-sync' = '$SECRET')"

echo "✅ RLS 策略已更新。别忘了把同一个值填进云函数环境变量 TGG_SYNC_SECRET。"
