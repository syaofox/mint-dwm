#!/usr/bin/env python3
import os
import re
import shutil

# Paths
# Adjust these relative to where the script is located or use absolute paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR) # .config/mint-dwm
CONFIG_DIR = os.path.join(PROJECT_ROOT, "config")
THEMES_DIR = os.path.join(PROJECT_ROOT, "themes")

XRESOURCES = os.path.join(CONFIG_DIR, ".Xresources")
DUNSTRC = os.path.join(CONFIG_DIR, "dunstrc")
ROFI_THEME = os.path.join(CONFIG_DIR, "rofi-theme.rasi")
ALACRITTY = os.path.join(CONFIG_DIR, "alacritty.toml")


def list_themes():
    """列出 themes 目录下的主题预设文件（*.Xresources 或 *.xresources）"""
    if not os.path.isdir(THEMES_DIR):
        print(f"Error: 主题目录不存在: {THEMES_DIR}")
        return []

    theme_files = []
    for name in sorted(os.listdir(THEMES_DIR)):
        lower = name.lower()
        if lower.endswith(".xresources"):
            theme_files.append(os.path.join(THEMES_DIR, name))
    return theme_files


def choose_theme(theme_files):
    """让用户从主题列表中选择一个"""
    if not theme_files:
        return None

    print("可用主题预设:")
    for idx, path in enumerate(theme_files, start=1):
        base = os.path.basename(path)
        # 去掉扩展名作为显示名称
        name = os.path.splitext(base)[0]
        print(f"  {idx}) {name}")

    while True:
        choice = input("请输入要应用的主题编号 (回车取消): ").strip()
        if choice == "":
            print("取消选择主题。")
            return None
        if not choice.isdigit():
            print("请输入有效的数字编号。")
            continue
        idx = int(choice)
        if not (1 <= idx <= len(theme_files)):
            print("编号超出范围，请重新输入。")
            continue
        return theme_files[idx - 1]


def apply_theme_xresources(theme_path):
    """将选中的主题 .Xresources 复制为当前 config/.Xresources"""
    if not os.path.exists(theme_path):
        print(f"Error: 主题文件不存在: {theme_path}")
        return False

    os.makedirs(CONFIG_DIR, exist_ok=True)
    print(f"应用主题 Xresources: {theme_path}")
    shutil.copyfile(theme_path, XRESOURCES)
    return True

def load_xresources():
    colors = {}
    if not os.path.exists(XRESOURCES):
        print(f"Error: {XRESOURCES} not found.")
        return None
    
    print(f"Reading colors from {XRESOURCES}...")
    with open(XRESOURCES, 'r') as f:
        for line in f:
            line = line.strip()
            if line.startswith('!'): continue
            if ':' in line:
                parts = line.split(':', 1)
                key = parts[0].strip()
                value = parts[1].strip()
                colors[key] = value
    return colors

def update_dunstrc(colors):
    if not os.path.exists(DUNSTRC):
        print(f"Error: {DUNSTRC} not found.")
        return

    print(f"Updating {DUNSTRC}...")

    # Mappings based on analysis
    # [urgency_low]
    low_bg = colors.get('dwm.normbgcolor', '#0d1416')
    low_fg = colors.get('dwm.selfgcolor', '#c5d9dc')
    low_frame = colors.get('dwm.accentcolor', '#60DEEC')
    
    # [urgency_normal] - Use border color for bg to distinguish slightly, or same as low
    norm_bg = colors.get('dwm.normbordercolor', '#1a2529') 
    norm_fg = colors.get('dwm.selfgcolor', '#c5d9dc')
    norm_frame = colors.get('dwm.accentcolor', '#60DEEC')
    
    with open(DUNSTRC, 'r') as f:
        lines = f.readlines()

    new_lines = []
    section = None
    
    for line in lines:
        original_line = line
        stripped = line.strip()
        
        # Track section
        if stripped.startswith('[') and stripped.endswith(']'):
            section = stripped[1:-1]
            new_lines.append(line)
            continue
            
        if section == 'urgency_low':
            if stripped.startswith('background'):
                line = re.sub(r'background\s*=.*', f'background = "{low_bg}"', line)
            elif stripped.startswith('foreground'):
                line = re.sub(r'foreground\s*=.*', f'foreground = "{low_fg}"', line)
            elif stripped.startswith('frame_color'):
                line = re.sub(r'frame_color\s*=.*', f'frame_color = "{low_frame}"', line)
            elif stripped.startswith('highlight'):
                line = re.sub(r'highlight\s*=.*', f'highlight = "{low_frame}"', line)
                
        elif section == 'urgency_normal':
            if stripped.startswith('background'):
                line = re.sub(r'background\s*=.*', f'background = "{norm_bg}"', line)
            elif stripped.startswith('foreground'):
                line = re.sub(r'foreground\s*=.*', f'foreground = "{norm_fg}"', line)
            elif stripped.startswith('frame_color'):
                line = re.sub(r'frame_color\s*=.*', f'frame_color = "{norm_frame}"', line)
            elif stripped.startswith('highlight'):
                line = re.sub(r'highlight\s*=.*', f'highlight = "{norm_frame}"', line)

        new_lines.append(line)
        
    with open(DUNSTRC, 'w') as f:
        f.writelines(new_lines)

def update_rofi(colors):
    if not os.path.exists(ROFI_THEME):
        print(f"Error: {ROFI_THEME} not found.")
        return

    print(f"Updating {ROFI_THEME}...")

    # Colors from Xresources
    bg = colors.get('dwm.normbgcolor', '#0d1416')
    fg = colors.get('dwm.selfgcolor', '#c5d9dc')
    sel_bg = colors.get('dwm.accentcolor', '#60DEEC')
    sel_fg = colors.get('dwm.normbgcolor', '#0d1416') # Text on accent should be dark usually
    border = colors.get('dwm.selbordercolor', '#60DEEC')
    
    # We only want to replace the variable definitions inside * { ... }
    # Regex strategy: look for specific property definitions
    
    replacements = {
        r'(^\s*background:\s*)([^;]+)(;.*)': f'\\1{bg}\\3',
        r'(^\s*foreground:\s*)([^;]+)(;.*)': f'\\1{fg}\\3',
        r'(^\s*selected-normal-background:\s*)([^;]+)(;.*)': f'\\1{sel_bg}\\3',
        r'(^\s*selected-normal-foreground:\s*)([^;]+)(;.*)': f'\\1{sel_fg}\\3',
        r'(^\s*border-color:\s*)([^;]+)(;.*)': f'\\1{border}\\3',
        # Also update 'active-foreground' to match accent if desired
        r'(^\s*active-foreground:\s*)([^;]+)(;.*)': f'\\1{sel_bg}\\3',
        r'(^\s*selected-active-foreground:\s*)([^;]+)(;.*)': f'\\1{sel_bg}\\3',
    }

    with open(ROFI_THEME, 'r') as f:
        lines = f.readlines()

    new_lines = []
    in_star_block = False
    
    for line in lines:
        stripped = line.strip()
        if stripped.startswith('* {') or stripped.startswith('*{'):
            in_star_block = True
        
        if in_star_block:
            for pattern, replacement in replacements.items():
                if re.search(pattern, line):
                    # Only replace if it looks like a color definition (contains rgba or #)
                    # This prevents replacing other things if any
                    if 'rgba' in line or '#' in line:
                        line = re.sub(pattern, replacement, line)
                        break
        
        if stripped.startswith('}') and in_star_block:
            in_star_block = False
            
        new_lines.append(line)

    with open(ROFI_THEME, 'w') as f:
        f.writelines(new_lines)


def update_alacritty(colors):
    """根据 Xresources 颜色更新 alacritty.toml"""
    if not os.path.exists(ALACRITTY):
        print(f"Error: {ALACRITTY} not found.")
        return

    print(f"Updating {ALACRITTY}...")

    # 从 Xresources 取色，提供合理默认值
    bg = colors.get('st.background', '#0d1416')
    fg = colors.get('st.foreground', '#c5d9dc')

    # normal 颜色
    n0 = colors.get('st.color0', '#0d1416')
    n1 = colors.get('st.color1', '#ff5555')
    n2 = colors.get('st.color2', '#50fa7b')
    n3 = colors.get('st.color3', '#f1fa8c')
    n4 = colors.get('st.color4', '#bd93f9')
    n5 = colors.get('st.color5', '#ff79c6')
    n6 = colors.get('st.color6', '#60DEEC')
    n7 = colors.get('st.color7', '#bbbbbb')

    # bright 颜色
    b0 = colors.get('st.color8', '#44475a')
    b1 = colors.get('st.color9', '#ff5555')
    b2 = colors.get('st.color10', '#50fa7b')
    b3 = colors.get('st.color11', '#f1fa8c')
    b4 = colors.get('st.color12', '#bd93f9')
    b5 = colors.get('st.color13', '#ff79c6')
    b6 = colors.get('st.color14', '#60DEEC')
    b7 = colors.get('st.color15', '#ffffff')

    with open(ALACRITTY, 'r') as f:
        lines = f.readlines()

    new_lines = []
    section = None

    for line in lines:
        stripped = line.strip()

        # 追踪当前 section
        if stripped.startswith('[') and stripped.endswith(']'):
            section = stripped.strip('[]').strip()
            new_lines.append(line)
            continue

        # [colors.primary]
        if section == 'colors.primary':
            if stripped.startswith('background'):
                line = re.sub(r'(^\s*background\s*=\s*)"[^"]*"(.*)',
                              f'\\1"{bg}"\\2', line)
            elif stripped.startswith('foreground'):
                line = re.sub(r'(^\s*foreground\s*=\s*)"[^"]*"(.*)',
                              f'\\1"{fg}"\\2', line)

        # [colors.normal]
        elif section == 'colors.normal':
            if stripped.startswith('black'):
                line = re.sub(r'(^\s*black\s*=\s*)"[^"]*"(.*)',
                              f'\\1"{n0}"\\2', line)
            elif stripped.startswith('red'):
                line = re.sub(r'(^\s*red\s*=\s*)"[^"]*"(.*)',
                              f'\\1"{n1}"\\2', line)
            elif stripped.startswith('green'):
                line = re.sub(r'(^\s*green\s*=\s*)"[^"]*"(.*)',
                              f'\\1"{n2}"\\2', line)
            elif stripped.startswith('yellow'):
                line = re.sub(r'(^\s*yellow\s*=\s*)"[^"]*"(.*)',
                              f'\\1"{n3}"\\2', line)
            elif stripped.startswith('blue'):
                line = re.sub(r'(^\s*blue\s*=\s*)"[^"]*"(.*)',
                              f'\\1"{n4}"\\2', line)
            elif stripped.startswith('magenta'):
                line = re.sub(r'(^\s*magenta\s*=\s*)"[^"]*"(.*)',
                              f'\\1"{n5}"\\2', line)
            elif stripped.startswith('cyan'):
                line = re.sub(r'(^\s*cyan\s*=\s*)"[^"]*"(.*)',
                              f'\\1"{n6}"\\2', line)
            elif stripped.startswith('white'):
                line = re.sub(r'(^\s*white\s*=\s*)"[^"]*"(.*)',
                              f'\\1"{n7}"\\2', line)

        # [colors.bright]
        elif section == 'colors.bright':
            if stripped.startswith('black'):
                line = re.sub(r'(^\s*black\s*=\s*)"[^"]*"(.*)',
                              f'\\1"{b0}"\\2', line)
            elif stripped.startswith('red'):
                line = re.sub(r'(^\s*red\s*=\s*)"[^"]*"(.*)',
                              f'\\1"{b1}"\\2', line)
            elif stripped.startswith('green'):
                line = re.sub(r'(^\s*green\s*=\s*)"[^"]*"(.*)',
                              f'\\1"{b2}"\\2', line)
            elif stripped.startswith('yellow'):
                line = re.sub(r'(^\s*yellow\s*=\s*)"[^"]*"(.*)',
                              f'\\1"{b3}"\\2', line)
            elif stripped.startswith('blue'):
                line = re.sub(r'(^\s*blue\s*=\s*)"[^"]*"(.*)',
                              f'\\1"{b4}"\\2', line)
            elif stripped.startswith('magenta'):
                line = re.sub(r'(^\s*magenta\s*=\s*)"[^"]*"(.*)',
                              f'\\1"{b5}"\\2', line)
            elif stripped.startswith('cyan'):
                line = re.sub(r'(^\s*cyan\s*=\s*)"[^"]*"(.*)',
                              f'\\1"{b6}"\\2', line)
            elif stripped.startswith('white'):
                line = re.sub(r'(^\s*white\s*=\s*)"[^"]*"(.*)',
                              f'\\1"{b7}"\\2', line)

        new_lines.append(line)

    with open(ALACRITTY, 'w') as f:
        f.writelines(new_lines)

def main():
    theme_files = list_themes()
    if not theme_files:
        print("没有找到任何主题预设文件，请在 themes 目录下添加 *.Xresources 主题。")
        return

    theme_path = choose_theme(theme_files)
    if not theme_path:
        return

    if not apply_theme_xresources(theme_path):
        print("应用主题失败。")
        return

    colors = load_xresources()
    if not colors:
        print("读取 Xresources 失败，无法继续同步。")
        return

    update_dunstrc(colors)
    update_rofi(colors)
    update_alacritty(colors)
    print("Theme sync completed successfully.")

if __name__ == "__main__":
    main()

