#!/usr/bin/env bash
# ============================================================
#  run_tests.sh —— 自动验证程序输出（演示 grep/awk/比较）
#  思路: 用系统工具独立算出"正确答案"，再和程序输出比对
# ============================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

APP="./build/logstat"
LOG="tests/sample.log"
KEY="${1:-ERROR}"

[[ -x "$APP" ]] || { echo "❌ 找不到 $APP，先跑 make"; exit 1; }
[[ -f "$LOG" ]] || { echo "❌ 找不到 $LOG"; exit 1; }

PASS=0
FAIL=0

# 从程序输出里取某个字段的值，例如 "总行数    : 10" -> 10
get_field() {
    local name="$1"
    "$APP" "$LOG" "$KEY" | awk -F: -v n="$name" '$1 ~ n {gsub(/ /,"",$2); print $2}'
}

check() {
    local name="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        printf "  ✅ %-10s 期望=%-6s 实际=%s\n" "$name" "$expected" "$actual"
        PASS=$((PASS + 1))
    else
        printf "  ❌ %-10s 期望=%-6s 实际=%s\n" "$name" "$expected" "$actual"
        FAIL=$((FAIL + 1))
    fi
}

echo "== 测试 $LOG (关键字: $KEY) =="

expect_total=$(grep -c '' "$LOG")            # 空正则 = 统计所有行
expect_match=$(grep -c "$KEY" "$LOG" || true)

expect_max=$(awk '{ if (length > m) m = length } END { print m }' "$LOG")
expect_min=$(awk 'NR == 1 { m = length } length < m { m = length } END { print m }' "$LOG")

check "总行数"   "$expect_total" "$(get_field '总行数')"
check "匹配行数" "$expect_match" "$(get_field '匹配行数' | cut -d'(' -f1)"
check "最长行长" "$expect_max" "$(get_field '最长行长')"
check "最短行长" "$expect_min" "$(get_field '最短行长')"

echo "----------------------------------"
echo "结果: $PASS 通过, $FAIL 失败"
[[ "$FAIL" -eq 0 ]]
