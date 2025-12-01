#!/bin/bash

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

log_info "开始安装 Mint DWM 配置..."

# 1. 更新并安装依赖
log_info "正在更新系统并安装依赖..."
sudo apt update

log_info "安装编译依赖..."
sudo apt install -y build-essential python3-dev libx11-dev libxinerama-dev libxft-dev libxrandr-dev

log_info "安装运行依赖..."
sudo apt install -y dunst feh pasystray picom wireplumber xfce4-clipman xdotool maim xclip rofi ffmpeg zenity x11-xserver-utils bulky catfish vim nemo lxappearance fcitx5 fcitx5-chinese-addons fcitx5-frontend-gtk3 fcitx5-frontend-gtk4 fcitx5-frontend-qt5 fcitx5-material-color

# 2. 安装字体
log_info "安装 JetBrainsMono Nerd Font..."
FONT_DIR="/usr/share/fonts/JetBrainsMono"
if [ ! -d "$FONT_DIR" ]; then
    mkdir -p /tmp/nerdfonts
    cd /tmp/nerdfonts
    curl -L -o JetBrainsMono.tar.xz https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.tar.xz
    tar -xf JetBrainsMono.tar.xz
    sudo mkdir -p "$FONT_DIR"
    sudo cp *.ttf "$FONT_DIR/"
    sudo fc-cache -f -v
    rm -rf /tmp/nerdfonts
    log_success "字体安装完成。"
else
    log_info "字体目录已存在，跳过安装。"
fi

# 3. 安装 GTK 主题（自动识别 gtk-themes 下所有压缩包）
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
                find "$TMP_THEME_DIR" -mindepth 1 -maxdepth 1 -type d -print0 | while IFS= read -r -d '' dir; do
                    THEME_NAME="$(basename "$dir")"
                    # 覆盖已有同名目录
                    rm -rf "$THEME_TARGET_DIR/$THEME_NAME"
                    mv "$dir" "$THEME_TARGET_DIR/"
                    log_success "GTK 主题已安装: $THEME_TARGET_DIR/$THEME_NAME"
                done
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

# 4. 安装 GTK 图标主题（自动识别 gtk-icons 下所有压缩包）
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
                find "$TMP_ICON_DIR" -mindepth 1 -maxdepth 1 -type d -print0 | while IFS= read -r -d '' dir; do
                    ICON_NAME="$(basename "$dir")"
                    # 覆盖已有同名目录
                    rm -rf "$ICON_TARGET_DIR/$ICON_NAME"
                    mv "$dir" "$ICON_TARGET_DIR/"
                    log_success "GTK 图标主题已安装: $ICON_TARGET_DIR/$ICON_NAME"
                done
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

# 3. 配置软链接
log_info "配置软链接..."

# Xresources
ln -sf "$REPO_DIR/config/.Xresources" "$HOME/.Xresources"
xrdb -merge "$HOME/.Xresources"
log_success "Xresources 已链接并合并。"

# File Manager Actions (Nemo)
mkdir -p "$HOME/.local/share/nemo"
rm -rf "$HOME/.local/share/nemo/actions"
ln -s "$REPO_DIR/config/nemo/actions" "$HOME/.local/share/nemo/actions"
log_success "Nemo 文件管理器动作已链接。"



# 4. 编译组件
compile_component() {
    local component=$1
    log_info "正在编译安装 $component..."
    cd "$REPO_DIR/suckless/$component"
    # 清理并编译安装
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
compile_component "st"

# 5. 创建会话入口
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

# 6. 设置脚本权限
log_info "设置脚本执行权限..."
chmod +x "$REPO_DIR/scripts/"*.sh
chmod +x "$REPO_DIR/scripts/"*.py
chmod +x "$REPO_DIR/scripts/dwm-start" # Ensure this one specifically if it lacks extension

# 7. 创建必要的用户目录
log_info "创建必要的用户目录..."
mkdir -p "$HOME/Pictures/Screenshots"
mkdir -p "$HOME/.cache"
log_success "用户目录已创建 (Pictures/Screenshots, .cache)。"

# 8. 设置 Nemo 终端为 st（依赖 Cinnamon 的 gsettings 配置）
log_info "将 Nemo/桌面默认终端设置为 st..."
if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.cinnamon.desktop.default-applications.terminal exec 'st'
    log_success "Nemo 默认终端已设置为 st。"
else
    log_error "未找到 gsettings 命令，无法自动设置 Nemo 默认终端。"
fi

log_success "Mint DWM 安装完成！请注销并选择 Dwm 会话登录。"

