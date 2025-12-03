#!/bin/bash

# 如果没有参数，退出
if [ $# -eq 0 ]; then
    exit 0
fi

# 选择条件：
# - 至少选中一个文件夹，或者
# - 选中多个（>=2）文件或文件夹
items=("$@")
count=${#items[@]}

has_dir=0
for p in "${items[@]}"; do
    if [ -d "$p" ]; then
        has_dir=1
        break
    fi
done

if [ "$has_dir" -eq 0 ] && [ "$count" -lt 2 ]; then
    zenity --error --title="重复文件清理" --text="请至少选中一个文件夹，或者选中多个文件/文件夹后再运行“删除重复项”。" --width=360
    exit 0
fi

# 将选中的路径展开成“要检查的文件列表”：
# - 普通文件：直接加入
# - 目录：递归 find 目录下的所有普通文件
files_to_check=()
for p in "${items[@]}"; do
    if [ -f "$p" ]; then
        files_to_check+=("$p")
    elif [ -d "$p" ]; then
        while IFS= read -r -d '' f; do
            files_to_check+=("$f")
        done < <(find "$p" -type f -print0)
    fi
done

# 如果最终没有可检查的文件，给出提示后退出
if [ ${#files_to_check[@]} -eq 0 ]; then
    zenity --info --title="重复文件清理" --text="选中的项目中没有可用的普通文件可供检查。" --width=360
    exit 0
fi

# 临时文件
HASH_FILE=$(mktemp)
DUPLICATES_FILE=$(mktemp)

# 标题
TITLE="重复文件清理"

# 进度条处理
(
    count=0
    total=${#files_to_check[@]}
    current_progress=0

    for file in "${files_to_check[@]}"; do
        if [ -f "$file" ]; then
            # 计算MD5，只取哈希值
            sum=$(md5sum "$file" | cut -d ' ' -f 1)
            
            # 检查哈希是否已记录
            if grep -q "^$sum$" "$HASH_FILE"; then
                # 已存在 -> 是重复文件
                echo "$file" >> "$DUPLICATES_FILE"
            else
                # 不存在 -> 记录哈希
                echo "$sum" >> "$HASH_FILE"
            fi
        fi
        
        # 更新进度条
        # 这里简单估算
        echo "# 正在检查: $(basename "$file")"
        # 由于 shell 浮点运算麻烦，这里使用脉冲模式其实更好，但为了展示进度用了 bc
        # 简单起见，不显示具体百分比数字，让 zenity 处理脉冲
    done
) | zenity --progress --pulsate --title="$TITLE" --text="正在分析文件指纹..." --auto-close

# 检查是否有重复文件
if [ ! -s "$DUPLICATES_FILE" ]; then
    zenity --info --title="$TITLE" --text="在选中的文件中未发现内容重复的项目。" --width=300
    rm -f "$HASH_FILE" "$DUPLICATES_FILE"
    exit 0
fi

# 统计重复数量
DUP_COUNT=$(wc -l < "$DUPLICATES_FILE")

# 确认对话框
# 使用 text-info 显示列表供用户最后确认
zenity --text-info \
    --title="确认删除重复项" \
    --text="检测到 $DUP_COUNT 个重复文件。\n\n点击 [确定] 将 PERMANENTLY DELETE (永久删除) 以下副本，只保留一份 originals：\n" \
    --filename="$DUPLICATES_FILE" \
    --width=600 --height=400 \
    --ok-label="确认删除" \
    --cancel-label="取消"

if [ $? -eq 0 ]; then
    # 执行删除
    # 逐行读取并删除
    # 再次显示进度条
    (
        while IFS= read -r file; do
            echo "# 删除: $(basename "$file")"
            rm -f "$file"
        done < "$DUPLICATES_FILE"
    ) | zenity --progress --pulsate --title="$TITLE" --text="正在删除..." --auto-close
fi

# 清理
rm -f "$HASH_FILE" "$DUPLICATES_FILE"

