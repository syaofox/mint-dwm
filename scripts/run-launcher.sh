#!/bin/sh

if command -v rofi >/dev/null 2>&1; then
    exec rofi -show drun -theme "$HOME/.config/mint-dwm/config/rofi-theme.rasi"
else
    exec /usr/bin/xfce4-appfinder
fi

