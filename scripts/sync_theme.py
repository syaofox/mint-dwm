#!/usr/bin/env python3
import os
import re

# Paths
# Adjust these relative to where the script is located or use absolute paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR) # .config/mint-dwm
CONFIG_DIR = os.path.join(PROJECT_ROOT, "config")

XRESOURCES = os.path.join(CONFIG_DIR, ".Xresources")
DUNSTRC = os.path.join(CONFIG_DIR, "dunstrc")
ROFI_THEME = os.path.join(CONFIG_DIR, "rofi-theme.rasi")

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

def main():
    colors = load_xresources()
    if colors:
        update_dunstrc(colors)
        update_rofi(colors)
        print("Theme sync completed successfully.")
    else:
        print("Failed to load colors.")

if __name__ == "__main__":
    main()

