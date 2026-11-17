#!/usr/bin/env bash
# ============================================================
#  build.sh —— 一键构建脚本（演示 Shell 自动化的几个核心点）
#     set -euo pipefail   出错就停、未定义变量报错、管道错误可见
#     trap               退出时自动清理临时文件
#     case               处理子命令
# ============================================================
set -euo pipefail

# 脚本所在目录的上一级 = 工程根目录（不依赖你在哪执行）
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

BUILD_DIR="${BUILD_DIR:-build}"
TMP_FILE=""

cleanup() {
    [[ -n "$TMP_FILE" && -f "$TMP_FILE" ]] && rm -f "$TMP_FILE"
}
trap cleanup EXIT

usage() {
    cat <<EOF
用法: $0 <命令>
  make     用 Makefile 构建
  cmake    用 CMake 构建（输出到 $BUILD_DIR/）
  run      构建后运行示例
  clean    清理所有产物
EOF
}

build_make() {
    echo ">>> make 构建"
    make -j"$(nproc)"
}

build_cmake() {
    echo ">>> cmake 构建（$BUILD_DIR/）"
    cmake -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release >/dev/null
    cmake --build "$BUILD_DIR" -j"$(nproc)"
}

run_demo() {
    echo ">>> 运行示例"
    ./"$BUILD_DIR"/logstat tests/sample.log ERROR
}

clean_all() {
    echo ">>> 清理"
    make clean
    rm -rf "$BUILD_DIR"
}

case "${1:-help}" in
    make)  build_make ;;
    cmake) build_cmake ;;
    run)   build_make; run_demo ;;
    clean) clean_all ;;
    *)     usage ;;
esac
