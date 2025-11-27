#!/bin/bash

# 包装脚本：调用 Python 生成器并显示 Zenity 进度条

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
PYTHON_SCRIPT="$SCRIPT_DIR/gen_pcmanfm_thumbnails.py"
LOG_FILE="/tmp/pcmanfm_thumb_debug.log"

echo "Starting thumbnail generation at $(date)" > "$LOG_FILE"

if [ ! -f "$PYTHON_SCRIPT" ]; then
    msg="错误: 找不到脚本 $PYTHON_SCRIPT"
    echo "$msg" >> "$LOG_FILE"
    zenity --error --text="$msg"
    exit 1
fi

# 检查依赖
if ! command -v python3 &> /dev/null; then
    msg="错误: 未安装 python3。"
    echo "$msg" >> "$LOG_FILE"
    zenity --error --text="$msg"
    exit 1
fi

# 捕获标准错误
exec 2>>"$LOG_FILE"

echo "Targets: $@" >> "$LOG_FILE"

# 执行并显示进度
"$PYTHON_SCRIPT" "$@" | tee -a "$LOG_FILE" | zenity --progress \
    --title="生成 PCManFM 缩略图" \
    --text="准备开始..." \
    --percentage=0 \
    --auto-close \
    --width=400

RET=$?
if [ $RET -eq 0 ]; then
    zenity --notification --text="缩略图生成完成！\n请按 F5 刷新文件夹查看。"
else
    # 如果非正常退出（比如用户取消），这里也会执行
    echo "Script finished with exit code $RET" >> "$LOG_FILE"
fi
