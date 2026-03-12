#!/bin/sh

# 優先順序：x-terminal-emulator → st → alacritty

if command -v /usr/bin/x-terminal-emulator >/dev/null 2>&1; then
    exec /usr/bin/x-terminal-emulator "$@"
elif command -v st >/dev/null 2>&1; then
    exec st "$@"
elif command -v alacritty >/dev/null 2>&1; then
    exec alacritty --config-file "$HOME/.config/mint-dwm/config/alacritty.toml" "$@"
else
    # 真的都找不到時的最後手段（通常不會走到這裡）
    echo "Error: No terminal emulator found!" >&2
    exit 1
fi