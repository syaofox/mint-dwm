#!/bin/sh

if command -v alacritty >/dev/null 2>&1; then
    exec alacritty --config-file "$HOME/.config/mint-dwm/config/alacritty.toml" "$@"
else
    exec /usr/bin/x-terminal-emulator "$@"
fi

