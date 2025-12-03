#!/bin/sh

# 优先使用 fsearch，如果失败则使用 catfish 作为备用

FSEARCH_FLATPAK_ID="io.github.cboxdoerfer.FSearch"

# 尝试运行 fsearch (flatpak)
if command -v flatpak >/dev/null 2>&1 && flatpak info "${FSEARCH_FLATPAK_ID}" >/dev/null 2>&1; then
    exec flatpak run --branch=stable --arch=x86_64 --command=fsearch "${FSEARCH_FLATPAK_ID}" "$@"
fi

# 如果 fsearch 不可用，尝试使用 catfish
if command -v catfish >/dev/null 2>&1; then
    exec catfish "$@"
fi

# 如果两者都不可用，显示错误信息
notify-send "文件搜索工具未安装" "未找到 fsearch 或 catfish" || true
exit 1

