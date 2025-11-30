#!/bin/sh

case "$1" in
    copy)
        maim -s -u | xclip -selection clipboard -t image/png && \
        notify-send '截图' '截图已保存到剪贴板'
        ;;
    save)
        DIR="$HOME/Pictures/Screenshots"
        mkdir -p "$DIR"
        maim -s -u | tee "$DIR/Screenshot_$(date +%Y-%m-%d_%H-%M-%S).png" | \
        xclip -selection clipboard -t image/png && \
        notify-send '截图' "已保存到剪贴板和 $DIR/"
        ;;
esac

