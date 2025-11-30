#!/usr/bin/env bash
# 顺序切换 ~/.config/walls/ 下的壁纸

WALL_DIR="$HOME/.config/mint-dwm/walls"
STATE_DIR="$HOME/.cache"
STATE_FILE="$STATE_DIR/current_wallpaper"

# 确保缓存目录存在
mkdir -p "$STATE_DIR"

# 如果目录不存在或不可读，直接退出
if [ ! -d "$WALL_DIR" ] || [ ! -r "$WALL_DIR" ]; then
  exit 0
fi

# 获取按名称排序的文件列表（只要普通文件和符号链接）
mapfile -t files < <(ls -1 "$WALL_DIR" 2>/dev/null)

if [ "${#files[@]}" -eq 0 ]; then
  exit 0
fi

next="${files[0]}"

# 如果有上一次记录，则找到下一张
if [ -f "$STATE_FILE" ]; then
  last=$(cat "$STATE_FILE")
  for i in "${!files[@]}"; do
    if [ "${files[$i]}" = "$last" ]; then
      idx=$(( (i + 1) % ${#files[@]} ))
      next="${files[$idx]}"
      break
    fi
  done
fi

# 记录当前壁纸
printf '%s\n' "$next" > "$STATE_FILE"

# 设置壁纸
if command -v feh >/dev/null 2>&1; then
  feh --bg-fill "$WALL_DIR/$next" 2>/dev/null &
fi


