#!/usr/bin/env bash

# 优先使用 apt 安装的 Brave，如果不存在则尝试使用 flatpak 版本

set -e

BRAVE_APT="/usr/bin/brave-browser-stable"
BRAVE_FLATPAK_ID="com.brave.Browser"

# 统一设置中文环境
export LANGUAGE=zh_CN
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8

EXTRA_ARGS=(--unsafely-treat-insecure-origin-as-secure=http://10.10.10.5:8080/)

if [ -x "$BRAVE_APT" ]; then
    exec "$BRAVE_APT" "${EXTRA_ARGS[@]}" "$@"
fi

if command -v flatpak >/dev/null 2>&1 && flatpak info "${BRAVE_FLATPAK_ID}" >/dev/null 2>&1; then
    exec flatpak run "${BRAVE_FLATPAK_ID}" "${EXTRA_ARGS[@]}" "$@"
fi

notify-send "Brave 未安装" "未找到 apt 或 flatpak 版本的 Brave 浏览器" || true
exit 1


