#!/bin/bash
# ============================================================
# Docker 镜像下载 + 打包脚本
#   docker pull --platform <platform> <image>
#   docker save <image> | gzip > <safe_name>.tar.gz
# ============================================================

# 严格模式：出错即退出、未定义变量报错、管道任一环失败即失败
set -euo pipefail

usage() {
    cat <<EOF
用法: $0 [镜像] [平台] [输出目录]

参数:
  镜像      要下载的镜像 (默认: nginx:latest)
  平台      目标架构 (默认: linux/amd64)
  输出目录  存档输出位置 (默认: 当前目录)

示例:
  $0 nginx:latest linux/arm64
  $0 docker.1ms.run/library/nginx:latest linux/amd64 ./images

环境变量:
  OUTPUT_DIR   输出目录 (默认: .)
  GZIP_LEVEL   gzip 压缩级别 1-9 (默认: 6)
EOF
}

case "${1:-}" in
    ""|-h|--help)   # 空（无参数）或 -h 或 --help
        usage
        exit 0
        ;;
esac

# ---------- 参数 ----------
IMAGE="${1:-nginx:latest}"
PLATFORM="${2:-linux/amd64}"
OUTPUT_DIR="${3:-${OUTPUT_DIR:-.}}"
GZIP_LEVEL="${GZIP_LEVEL:-6}"

# ---------- 依赖检查 ----------
command -v docker &>/dev/null || { echo "错误: 未找到 docker，请先安装" >&2; exit 1; }
command -v gzip   &>/dev/null || { echo "错误: 未找到 gzip" >&2; exit 1; }

# ---------- 镜像名安全化（等价于 Action 里的 tr '/:' '_'） ----------
SAFE_NAME=$(echo "$IMAGE" | tr '/:' '_')
mkdir -p "$OUTPUT_DIR"
ARCHIVE="$OUTPUT_DIR/${SAFE_NAME}.tar.gz"

echo "================================================"
echo " 镜像:   $IMAGE"
echo " 平台:   $PLATFORM"
echo " 输出:   $ARCHIVE"
echo "================================================"

# ---------- 1. 拉取指定平台镜像 ----------
echo ">>> [1/2] 拉取镜像 ..."
docker pull --platform "$PLATFORM" "$IMAGE"

# ---------- 2. 保存为 tar.gz ----------
echo ">>> [2/2] 打包镜像 ..."
docker save "$IMAGE" \
    | gzip "-$GZIP_LEVEL" > "$ARCHIVE"

echo ">>> 完成: $ARCHIVE"
ls -lh "$ARCHIVE"
