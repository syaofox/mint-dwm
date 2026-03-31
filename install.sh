#!/bin/bash

set -euo pipefail

DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            echo "用法: $0 [选项] [操作]"
            echo ""
            echo "选项:"
            echo "  --dry-run    仅显示将要执行的操作，不实际执行"
            echo "  --help, -h   显示此帮助信息"
            echo ""
            echo "操作:"
            echo "  themes   - 仅安装 GTK 主题"
            echo "  icons    - 仅安装 GTK 图标主题"
            echo "  links    - 仅检查并设置配置文件软链接"
            exit 0
            ;;
        *)
            break
            ;;
    esac
done

check_network() {
    if ! curl -s --max-time 5 https://github.com > /dev/null 2>&1; then
        log_error "无法连接到网络，请检查网络连接"
        exit 1
    fi
}

check_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        log_error "缺少必要命令: $1"
        return 1
    fi
    return 0
}

run_apt() {
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] sudo apt $*"
        return 0
    fi
    if ! sudo apt "$@"; then
        log_error "apt 命令执行失败: apt $*"
        return 1
    fi
    return 0
}

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 辅助函数
log_info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

log_success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

log_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# 安装 GTK 主题（自动识别 gtk-themes 下所有压缩包）
install_gtk_themes() {
    THEME_DIR_SRC="$REPO_DIR/gtk-themes"
    THEME_TARGET_DIR="$HOME/.themes"
    if [ -d "$THEME_DIR_SRC" ]; then
        mkdir -p "$THEME_TARGET_DIR"
        shopt -s nullglob
        THEME_ARCHIVES=("$THEME_DIR_SRC"/*.tar "$THEME_DIR_SRC"/*.tar.gz "$THEME_DIR_SRC"/*.tar.xz "$THEME_DIR_SRC"/*.tgz)
        if [ ${#THEME_ARCHIVES[@]} -eq 0 ]; then
            log_info "gtk-themes 目录中没有找到任何主题压缩包，跳过 GTK 主题安装。"
        else
            for THEME_ARCHIVE in "${THEME_ARCHIVES[@]}"; do
                BASENAME="$(basename "$THEME_ARCHIVE")"
                log_info "安装 GTK 主题包: $BASENAME 到用户主题目录 ($THEME_TARGET_DIR)..."
                TMP_THEME_DIR="$(mktemp -d)"
                if tar -xf "$THEME_ARCHIVE" -C "$TMP_THEME_DIR"; then
                    # 解压后可能包含一个或多个目录，这里全部移动到 ~/.themes
                    while IFS= read -r -d '' dir; do
                        THEME_NAME="$(basename "$dir")"
                        # 覆盖已有同名目录
                        rm -rf "${THEME_TARGET_DIR:?}/$THEME_NAME"
                        mv "$dir" "$THEME_TARGET_DIR/"
                        log_success "GTK 主题已安装: $THEME_TARGET_DIR/$THEME_NAME"
                    done < <(find "$TMP_THEME_DIR" -mindepth 1 -maxdepth 1 -type d -print0)
                else
                    log_error "解压 GTK 主题包失败: $BASENAME"
                fi
                rm -rf "$TMP_THEME_DIR"
            done
        fi
        shopt -u nullglob
    else
        log_info "未找到 GTK 主题目录 ($THEME_DIR_SRC)，跳过 GTK 主题安装。"
    fi
}

# 安装 GTK 图标主题（自动识别 gtk-icons 下所有压缩包）
install_gtk_icons() {
    ICON_DIR_SRC="$REPO_DIR/gtk-icons"
    ICON_TARGET_DIR="$HOME/.icons"
    if [ -d "$ICON_DIR_SRC" ]; then
        mkdir -p "$ICON_TARGET_DIR"
        shopt -s nullglob
        ICON_ARCHIVES=("$ICON_DIR_SRC"/*.tar "$ICON_DIR_SRC"/*.tar.gz "$ICON_DIR_SRC"/*.tar.xz "$ICON_DIR_SRC"/*.tgz)
        if [ ${#ICON_ARCHIVES[@]} -eq 0 ]; then
            log_info "gtk-icons 目录中没有找到任何图标主题压缩包，跳过 GTK 图标主题安装。"
        else
            for ICON_ARCHIVE in "${ICON_ARCHIVES[@]}"; do
                BASENAME="$(basename "$ICON_ARCHIVE")"
                log_info "安装 GTK 图标主题包: $BASENAME 到用户图标目录 ($ICON_TARGET_DIR)..."
                TMP_ICON_DIR="$(mktemp -d)"
                if tar -xf "$ICON_ARCHIVE" -C "$TMP_ICON_DIR"; then
                    # 解压后可能包含一个或多个目录，这里全部移动到 ~/.icons
                    while IFS= read -r -d '' dir; do
                        ICON_NAME="$(basename "$dir")"
                        # 覆盖已有同名目录
                        rm -rf "${ICON_TARGET_DIR:?}/$ICON_NAME"
                        mv "$dir" "$ICON_TARGET_DIR/"
                        log_success "GTK 图标主题已安装: $ICON_TARGET_DIR/$ICON_NAME"
                    done < <(find "$TMP_ICON_DIR" -mindepth 1 -maxdepth 1 -type d -print0)
                else
                    log_error "解压 GTK 图标主题包失败: $BASENAME"
                fi
                rm -rf "$TMP_ICON_DIR"
            done
        fi
        shopt -u nullglob
    else
        log_info "未找到 GTK 图标主题目录 ($ICON_DIR_SRC)，跳过 GTK 图标主题安装。"
    fi
}

# 设置和检查软链接
setup_symlinks() {
    log_info "检查并设置配置文件软链接..."
    
    local fixed_count=0
    local created_count=0
    local skipped_count=0
    
    local -a symlinks=(
        "$HOME/.Xresources|$REPO_DIR/config/.Xresources|Xresources 配置"
        "$HOME/.local/share/nemo/actions|$REPO_DIR/config/nemo/actions|Nemo 文件管理器动作"
        "$HOME/.config/alacritty/alacritty.toml|$REPO_DIR/config/alacritty.toml|Alacritty 终端配置"
        "$HOME/.config/dunst/dunstrc|$REPO_DIR/config/dunstrc|Dunst 通知配置"
        "$HOME/.config/picom/picom.conf|$REPO_DIR/config/picom.conf|Picom 合成器配置"
        "$HOME/.config/mpv/mpv.conf|$REPO_DIR/config/mpv.conf|MPV 播放器配置"
        "$HOME/.config/rofi/config.rasi|$REPO_DIR/config/rofi-theme.rasi|Rofi 启动器配置"
    )
    
    for symlink_def in "${symlinks[@]}"; do
        IFS='|' read -r target source desc <<< "$symlink_def"
        
        # 检查源文件是否存在
        if [ ! -e "$source" ]; then
            log_info "跳过 $desc: 源文件不存在 ($source)"
            skipped_count=$((skipped_count + 1))
            continue
        fi
        
        # 创建目标目录（如果需要）
        target_dir=$(dirname "$target")
        if [ ! -d "$target_dir" ]; then
            mkdir -p "$target_dir"
        fi
        
        # 检查目标路径是否存在
        if [ -e "$target" ]; then
            # 如果是软链接，检查是否正确
            if [ -L "$target" ]; then
                current_target=$(readlink -f "$target")
                expected_target=$(readlink -f "$source")
                
                if [ "$current_target" = "$expected_target" ]; then
                    log_info "✓ $desc: 软链接已正确设置"
                    continue
                else
                    log_info "修复 $desc: 软链接指向错误位置"
                    rm -f "$target"
                    # 如果是目录，使用 ln -s，否则使用 ln -sf
                    if [ -d "$source" ]; then
                        ln -s "$source" "$target"
                    else
                        ln -sf "$source" "$target"
                    fi
                    log_success "$desc: 已修复软链接"
                    fixed_count=$((fixed_count + 1))
                fi
            else
                # 如果是普通文件或目录，备份后创建软链接
                backup_path="${target}.backup.$(date +%Y%m%d_%H%M%S)"
                log_info "备份现有 $desc 到: $backup_path"
                # 如果是目录，需要递归删除
                if [ -d "$target" ]; then
                    rm -rf "$target"
                else
                    mv "$target" "$backup_path"
                fi
                # 如果是目录，使用 ln -s，否则使用 ln -sf
                if [ -d "$source" ]; then
                    ln -s "$source" "$target"
                else
                    ln -sf "$source" "$target"
                fi
                log_success "$desc: 已备份原文件并创建软链接"
                fixed_count=$((fixed_count + 1))
            fi
        else
            # 目标不存在，直接创建软链接
            # 如果是目录，使用 ln -s，否则使用 ln -sf
            if [ -d "$source" ]; then
                ln -s "$source" "$target"
            else
                ln -sf "$source" "$target"
            fi
            log_success "$desc: 已创建软链接"
            created_count=$((created_count + 1))
        fi
    done
    
    # 特殊处理：Xresources 需要合并到 X 服务器
    if [ -L "$HOME/.Xresources" ] && [ -e "$HOME/.Xresources" ]; then
        if command -v xrdb >/dev/null 2>&1; then
            xrdb -merge "$HOME/.Xresources"
            log_success "Xresources 已合并到 X 服务器"
        else
            log_info "未找到 xrdb 命令，跳过 Xresources 合并"
        fi
    fi
    
    echo ""
    log_info "软链接设置完成:"
    log_info "  - 已创建: $created_count 个"
    log_info "  - 已修复: $fixed_count 个"
    log_info "  - 已跳过: $skipped_count 个"
}

# 检查是否为 root 运行，有些命令需要 sudo
if [ "$EUID" -eq 0 ]; then
  log_error "请不要直接以 root 用户运行此脚本，脚本内部会请求 sudo 权限。"
  exit 1
fi

REPO_DIR="$HOME/.config/mint-dwm"

if [ ! -d "$REPO_DIR" ]; then
    log_error "未找到项目目录: $REPO_DIR"
    log_info "请确保将项目克隆到 ~/.config/mint-dwm"
    exit 1
fi

# 根据参数决定执行范围
ACTION="${1:-}"
if [ -n "$ACTION" ]; then
    case "$ACTION" in
        themes)
            log_info "仅安装 GTK 主题..."
            install_gtk_themes
            exit 0
            ;;
        icons)
            log_info "仅安装 GTK 图标主题..."
            install_gtk_icons
            exit 0
            ;;
        links|symlinks)
            log_info "仅设置配置文件软链接..."
            setup_symlinks
            exit 0
            ;;
        *)
            log_error "未知参数: $ACTION"
            echo "用法: $0 [themes|icons|links]"
            echo ""
            echo "参数说明:"
            echo "  themes   - 仅安装 GTK 主题"
            echo "  icons    - 仅安装 GTK 图标主题"
            echo "  links    - 仅检查并设置配置文件软链接"
            exit 1
            ;;
    esac
fi

if [ "$DRY_RUN" = true ]; then
    log_info "=== 运行在 DRY-RUN 模式，仅显示将要执行的操作 ==="
    echo ""
fi

log_info "开始安装 Mint DWM 配置..."

# 1. 更新并安装依赖
log_info "正在更新系统并安装依赖..."
run_apt update

log_info "安装编译依赖..."
run_apt install -y build-essential python3-dev libx11-dev libxinerama-dev libxft-dev libxrandr-dev git

log_info "安装运行依赖..."
run_apt install -y dunst feh pasystray picom wireplumber xfce4-clipman xdotool maim xclip rofi ffmpeg imagemagick zenity x11-xserver-utils bulky catfish vim nemo lxappearance fcitx5 fcitx5-chinese-addons fcitx5-frontend-gtk3 fcitx5-frontend-gtk4 fcitx5-frontend-qt5 fcitx5-material-color

# 2. 安装字体
log_info "安装 JetBrainsMono Nerd Font..."
FONT_DIR="/usr/share/fonts/JetBrainsMono"
LOCAL_FONT_DIR="$REPO_DIR/fonts"

if [ -d "$FONT_DIR" ]; then
    log_info "系统字体目录已存在，跳过安装。"
else
    if [ -d "$LOCAL_FONT_DIR" ] && [ -n "$(ls -A "$LOCAL_FONT_DIR"/*.ttf 2>/dev/null)" ]; then
        log_info "发现本地字体，使用本地字体..."
        sudo mkdir -p "$FONT_DIR"
        sudo cp "$LOCAL_FONT_DIR"/*.ttf "$FONT_DIR/"
        sudo fc-cache -f -v
        log_success "本地字体安装完成。"
    else
        log_info "未发现本地字体，尝试下载..."
        check_network
        mkdir -p /tmp/nerdfonts
        cd /tmp/nerdfonts || exit
        if ! curl -L -o JetBrainsMono.tar.xz https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.tar.xz; then
            log_error "字体下载失败，请检查网络连接"
            rm -rf /tmp/nerdfonts
            exit 1
        fi
        tar -xf JetBrainsMono.tar.xz
        ttf_files=(./*.ttf)
        if [ ${#ttf_files[@]} -eq 0 ] || [ ! -f "${ttf_files[0]}" ]; then
            log_error "未找到任何 ttf 字体文件，下载可能失败"
            rm -rf /tmp/nerdfonts
            exit 1
        fi
        sudo mkdir -p "$FONT_DIR"
        sudo cp ./*.ttf "$FONT_DIR/"
        sudo fc-cache -f -v
        rm -rf /tmp/nerdfonts
        log_success "下载字体安装完成。"
    fi
fi

# 3. 安装 GTK 主题（自动识别 gtk-themes 下所有压缩包）
install_gtk_themes

# 4. 安装 GTK 图标主题（自动识别 gtk-icons 下所有压缩包）
install_gtk_icons

# 5. 配置软链接
setup_symlinks



# 6. 编译组件
compile_component() {
    local component=$1
    log_info "正在编译安装 $component..."
    cd "$REPO_DIR/suckless/$component" || exit
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] sudo make clean install"
        return 0
    fi
    if sudo make clean install; then
        log_success "$component 安装成功。"
    else
        log_error "$component 安装失败。"
        exit 1
    fi
}

compile_component "dwm"
compile_component "slstatus"
compile_component "slock"
# compile_component "st"

# 7. 创建会话入口
log_info "创建会话入口..."
DESKTOP_FILE="/usr/share/xsessions/dwm.desktop"
sudo bash -c "cat > $DESKTOP_FILE" <<EOF
[Desktop Entry]
Encoding=UTF-8
Name=Dwm
Comment=Dynamic window manager
Exec=$REPO_DIR/scripts/dwm-start
Icon=dwm
Type=XSession
EOF

if [ -f "$DESKTOP_FILE" ]; then
    log_success "会话入口已创建: $DESKTOP_FILE"
else
    log_error "创建会话入口失败。"
fi

# 8. 设置脚本权限
log_info "设置脚本执行权限..."
chmod +x "$REPO_DIR/scripts/"*.sh
chmod +x "$REPO_DIR/scripts/"*.py
chmod +x "$REPO_DIR/scripts/dwm-start" # Ensure this one specifically if it lacks extension

# 9. 创建必要的用户目录
log_info "创建必要的用户目录..."
mkdir -p "$HOME/Pictures/Screenshots"
mkdir -p "$HOME/.cache"
log_success "用户目录已创建 (Pictures/Screenshots, .cache)。"

# # 10. 设置 Nemo 终端为 st（依赖 Cinnamon 的 gsettings 配置）
# log_info "将 Nemo/桌面默认终端设置为 st..."
# if command -v gsettings >/dev/null 2>&1; then
#     gsettings set org.cinnamon.desktop.default-applications.terminal exec 'st'
#     log_success "Nemo 默认终端已设置为 st。"
# else
#     log_error "未找到 gsettings 命令，无法自动设置 Nemo 默认终端。"
# fi

log_success "Mint DWM 安装完成！请注销并选择 Dwm 会话登录。"

