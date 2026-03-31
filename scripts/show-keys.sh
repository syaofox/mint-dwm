#!/bin/bash

# DWM 快捷键帮助脚本
# 使用 rofi 显示快捷键列表

CONFIG_DIR="$HOME/.config/mint-dwm/config"

KEYS=$(cat <<'EOF'
基础操作
Super + Space         启动应用菜单
Super + Return        打开终端
Super + e             打开文件管理器
Super + w             打开浏览器
Super + Shift + w     切换壁纸
Super + f             文件搜索
Super + a             截图 (复制到剪贴板)
Super + Shift + a     截图 (复制并保存)
Super + Shift + l     锁屏
Super + Shift + q     退出 dwm
窗口管理
Super + j / k         聚焦下一个/上一个窗口
Super + , / .         减小/增大主窗口区域
Super + s             交换主窗口 (Zoom)
Super + q             关闭当前窗口
Super + m             循环切换布局
Super + t             强制切换回 Tile 布局
Super + b             切换状态栏显示
间距调整
Super + u             增加窗口间隙
Super + Shift + u     减少窗口间隙
Super + 0             切换间隙启用/禁用
Super + Shift + 0     重置为默认间隙
标签操作
Super + 1-9           切换到指定标签
Super + Ctrl + 1-9   切换显示指定标签
Super + Alt + 1-9    将窗口移动到指定标签
Super + Shift + 1-9  移动窗口并切换到该标签
Super + Tab           切换到下一个标签
鼠标操作
Super + 鼠标左键拖动   移动窗口
Super + 鼠标中键       切换浮动
Super + 鼠标右键拖动  调整窗口大小
多媒体
XF86AudioRaise      音量 +
XF86AudioLower      音量 -
XF86AudioMute       静音切换
系统
Ctrl + Alt + Delete  电源菜单
EOF
)

echo "$KEYS" | rofi -dmenu -i -no-fixed-num-lines -p "快捷键" -theme "$CONFIG_DIR/rofi-theme.rasi" -theme-str "listview { columns: 3; } window { width: 50%; height: 70%; }"

