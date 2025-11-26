#!/bin/bash

# 获取音量百分比的辅助函数
get_volume() {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}'
}

# 检查是否静音
is_muted() {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q "MUTED"
}

function send_notification() {
    volume=$(get_volume)
    # 根据是否静音显示不同图标或状态
    if is_muted; then
        dunstify -a "changevolume" -u low -r "9993" -h int:value:"$volume" -i "volume-mute" "Volume: ${volume}% (Muted)" -t 2000
    else
        dunstify -a "changevolume" -u low -r "9993" -h int:value:"$volume" -i "volume-$1" "Volume: ${volume}%" -t 2000
    fi
}

case $1 in
up)
    # 解除静音并增加音量 (限制最大 150%)
    wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
    wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 2%+
    send_notification $1
    ;;
down)
    # 解除静音并减少音量
    wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
    wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-
    send_notification $1
    ;;
mute)
    # 切换静音
    wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    if is_muted; then
        dunstify -i volume-mute -a "changevolume" -t 2000 -r 9993 -u low "Muted"
    else
        send_notification up
    fi
    ;;
esac
