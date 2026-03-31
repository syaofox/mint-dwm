#!/bin/sh

if command -v rofi >/dev/null 2>&1; then
    exec rofi -show drun -theme "$HOME/.config/mint-dwm/config/rofi-theme.rasi" -theme-str "listview { columns: 4; } window { width: 40%; height: 60%; }"
else
    exec /usr/bin/xfce4-appfinder
fi
