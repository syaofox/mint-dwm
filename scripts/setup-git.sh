#!/bin/bash

# Git 配置脚本
# 用于在 Linux 环境下配置 Git 的常用设置

set -e

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# 检查 Git 是否已安装
if ! command -v git &> /dev/null; then
    print_error "Git 未安装，请先安装 Git"
    exit 1
fi

echo -e "${BLUE}=== Git 配置脚本 ===${NC}\n"

# 1. 配置用户身份信息
echo -e "${BLUE}1. 配置用户身份信息${NC}"

# 检查是否已有配置
CURRENT_NAME=$(git config --global user.name 2>/dev/null || echo "")
CURRENT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

if [ -n "$CURRENT_NAME" ] && [ -n "$CURRENT_EMAIL" ]; then
    print_info "当前配置："
    echo "  用户名: $CURRENT_NAME"
    echo "  邮箱: $CURRENT_EMAIL"
    read -p "是否要更新？(y/N): " update_identity
    if [[ ! "$update_identity" =~ ^[Yy]$ ]]; then
        print_info "跳过身份信息配置"
    else
        CURRENT_NAME=""
        CURRENT_EMAIL=""
    fi
fi

if [ -z "$CURRENT_NAME" ] || [ -z "$CURRENT_EMAIL" ]; then
    # 从命令行参数获取或提示用户输入
    if [ -n "$1" ] && [ -n "$2" ]; then
        USER_NAME="$1"
        USER_EMAIL="$2"
        print_info "使用命令行参数：$USER_NAME <$USER_EMAIL>"
    else
        read -p "请输入您的姓名: " USER_NAME
        read -p "请输入您的邮箱: " USER_EMAIL
    fi
    
    if [ -z "$USER_NAME" ] || [ -z "$USER_EMAIL" ]; then
        print_error "姓名和邮箱不能为空"
        exit 1
    fi
    
    git config --global user.name "$USER_NAME"
    git config --global user.email "$USER_EMAIL"
    print_success "已配置用户身份信息"
fi

# 2. 配置文本编辑器
echo -e "\n${BLUE}2. 配置文本编辑器${NC}"

CURRENT_EDITOR=$(git config --global core.editor 2>/dev/null || echo "")

if [ -n "$CURRENT_EDITOR" ]; then
    print_info "当前编辑器: $CURRENT_EDITOR"
    read -p "是否要更改？(y/N): " change_editor
    if [[ ! "$change_editor" =~ ^[Yy]$ ]]; then
        print_info "跳过编辑器配置"
    else
        CURRENT_EDITOR=""
    fi
fi

if [ -z "$CURRENT_EDITOR" ]; then
    # 检测可用的编辑器
    if command -v nvim &> /dev/null; then
        DEFAULT_EDITOR="nvim"
    elif command -v vim &> /dev/null; then
        DEFAULT_EDITOR="vim"
    elif command -v nano &> /dev/null; then
        DEFAULT_EDITOR="nano"
    else
        DEFAULT_EDITOR="vi"
    fi
    
    print_info "检测到默认编辑器: $DEFAULT_EDITOR"
    read -p "请输入要使用的编辑器 [$DEFAULT_EDITOR]: " USER_EDITOR
    USER_EDITOR=${USER_EDITOR:-$DEFAULT_EDITOR}
    
    git config --global core.editor "$USER_EDITOR"
    print_success "已配置编辑器: $USER_EDITOR"
fi

# 3. 配置别名
echo -e "\n${BLUE}3. 配置常用别名${NC}"

# 定义别名数组
declare -A ALIASES=(
    ["st"]="status"
    ["co"]="checkout"
    ["br"]="branch"
    ["ci"]="commit"
    ["lg"]="log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
)

for alias in "${!ALIASES[@]}"; do
    cmd="${ALIASES[$alias]}"
    CURRENT_ALIAS=$(git config --global "alias.$alias" 2>/dev/null || echo "")
    
    if [ -n "$CURRENT_ALIAS" ]; then
        if [ "$CURRENT_ALIAS" != "$cmd" ]; then
            print_warning "别名 '$alias' 已存在但不同，跳过"
        else
            print_info "别名 '$alias' 已存在"
        fi
    else
        git config --global "alias.$alias" "$cmd"
        print_success "已配置别名: git $alias -> git $cmd"
    fi
done

# 4. 配置终端颜色
echo -e "\n${BLUE}4. 配置终端颜色${NC}"

CURRENT_COLOR=$(git config --global color.ui 2>/dev/null || echo "")

if [ -z "$CURRENT_COLOR" ] || [ "$CURRENT_COLOR" != "auto" ]; then
    git config --global color.ui auto
    print_success "已启用终端颜色输出"
else
    print_info "终端颜色已配置"
fi

# 5. 配置换行符处理
echo -e "\n${BLUE}5. 配置换行符处理${NC}"

CURRENT_AUTOCRLF=$(git config --global core.autocrlf 2>/dev/null || echo "")

if [ -z "$CURRENT_AUTOCRLF" ] || [ "$CURRENT_AUTOCRLF" != "input" ]; then
    git config --global core.autocrlf input
    print_success "已配置换行符处理 (Linux/macOS 推荐设置)"
else
    print_info "换行符处理已配置"
fi

# 显示配置摘要
echo -e "\n${BLUE}=== 配置摘要 ===${NC}"
echo -e "${GREEN}已完成的配置：${NC}"
echo "  • 用户身份信息"
echo "  • 文本编辑器"
echo "  • 常用别名 (st, co, br, ci, lg)"
echo "  • 终端颜色"
echo "  • 换行符处理"

echo -e "\n${BLUE}当前全局配置：${NC}"
git config --global --list | sed 's/^/  /'

echo -e "\n${GREEN}配置完成！${NC}"
echo -e "\n${BLUE}提示：${NC}"
echo "  • 使用 'git st' 代替 'git status'"
echo "  • 使用 'git lg' 查看美化的提交历史"
echo "  • 使用 'git config --global --list' 查看所有配置"
echo "  • 使用 'git config --global --unset <key>' 删除某个配置"

