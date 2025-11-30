# Mint DWM Configuration

这是一个适配 Linux Mint 22.2 (基于 XFCE 环境) 的 [dwm](https://dwm.suckless.org/) (dynamic window manager) 配置项目。旨在提供一个轻量、高效且美观的平铺式窗口管理器体验，同时保留 XFCE 的部分便利性（如 Thunar, Polkit 等）。

## 目录

- [简介](#简介)
- [依赖说明](#依赖说明)
- [安装步骤](#安装步骤)
- [快捷键](#快捷键)
- [脚本与功能](#脚本与功能)
- [自定义](#自定义)

## 简介

本项目包含了 dwm 的自定义构建、状态栏 (slstatus)、锁屏工具 (slock) 以及相关的启动和辅助脚本。

**主要特性:**
*   **外观**: 集成 Nerd Fonts 图标，定制配色（深色背景 + 青色强调色）。
*   **布局**: 支持 Tile, Monocle 和浮动布局，配备 VanityGaps (窗口间隙)。
*   **状态栏**: 使用 slstatus 显示系统信息，支持系统托盘 (Systray)。
*   **集成**:
    *   自动启动脚本 (`dwm-start`) 处理壁纸恢复、合成器、通知服务等。
    *   音量控制集成 dunst 通知。
    *   适配 XFCE 工具链 (Thunar, xfce4-appfinder, xfce4-screenshooter)。

## 依赖说明

在编译和运行之前，请确保安装了以下依赖。

### 编译依赖

编译 dwm, slstatus 和 slock 需要 X11 开发库：

```bash
sudo apt update
sudo apt install build-essential python3-dev libx11-dev libxinerama-dev libxft-dev libxrandr-dev 
```

### 运行依赖

为了获得完整的体验，需要安装以下软件：

*   **基础工具**: `dunst` (通知), `feh` (壁纸), `pasystray` (PulseAudio 托盘), `picom` (可选，合成器), `wireplumber` (提供 wpctl 音量控制), `xfce4-clipman` (剪贴板), `xdotool` (模拟按键) `rofi` (应用启动器)
*   **XFCE 组件**: `xfce4-appfinder` (应用启动器), `thunar` (文件管理器)
*   **其他**: `maim` (截图), `xclip` (剪贴板管理), `libpolkit-gnome-1-0` (Polkit 代理), `gnome-keyring` (密码管理), `trash-cli` (垃圾桶) `imagemagick` (图片处理)
*   **浏览器**: `brave-browser` (配置中默认使用，可修改)
*   **搜索工具**: `fsearch` (配置中默认使用 Flatpak 版本)

```bash
sudo apt install dunst feh pasystray picom wireplumber xfce4-clipman xdotool maim xclip rofi
```

### 字体

配置使用了 **JetBrainsMono Nerd Font**。请确保已安装该字体，否则状态栏图标将无法显示。

## 安装步骤

### 1. 克隆仓库

**重要**: 脚本中包含硬编码路径，请务必将项目克隆到 `~/.config/mint-dwm` 目录。

```bash
mkdir -p ~/.config
git clone https://github.com/你的用户名/mint-dwm.git ~/.config/mint-dwm
```

### 2. 编译组件

分别编译并安装 dwm, slstatus 和 slock：

```bash
# 编译安装 dwm
cd ~/.config/mint-dwm/suckless/dwm
sudo make clean install

# 编译安装 slstatus
cd ~/.config/mint-dwm/suckless/slstatus
sudo make clean install

# 编译安装 slock
cd ~/.config/mint-dwm/suckless/slock
sudo make clean install
```

### 3. 添加会话入口

为了在登录管理器 (如 LightDM) 中选择 dwm，需要创建一个 `.desktop` 文件。

创建文件 `/usr/share/xsessions/dwm.desktop` (需要 sudo 权限)：

```ini
[Desktop Entry]
Encoding=UTF-8
Name=Dwm
Comment=Dynamic window manager
Exec=/home/你的用户名/.config/mint-dwm/scripts/dwm-start
Icon=dwm
Type=XSession
```
*注意: 请将 `Exec` 路径中的 `你的用户名` 替换为实际的用户名，或者使用绝对路径。建议检查 `dwm-start` 是否具有执行权限 (`chmod +x ~/.config/mint-dwm/scripts/dwm-start`)。*

## 快捷键

默认 **Mod 键** 为 `Super` (Windows 键)。

### 常用操作

| 快捷键 | 功能 | 对应命令 |
| :--- | :--- | :--- |
| `Mod + Return` | 打开终端 | `x-terminal-emulator` |
| `Mod + Space` | 打开应用菜单 | `xfce4-appfinder` |
| `Mod + e` | 打开文件管理器 | `thunar` |
| `Mod + w` | 打开浏览器 | `brave-browser` |
| `Mod + Shift + w` | 切换壁纸 | `wallpaper-next.sh` |
| `Mod + f` | 文件搜索 | `fsearch` |
| `Mod + a` | 截图 (仅复制) | `maim` |
| `Mod + Shift + a` | 截图 (复制并保存到 ~/Pictures/Screenshots/) | `maim` |
| `Mod + Shift + l` | 锁屏 | `slock` |
| `Mod + Shift + q` | 退出 dwm (注销) | |
| `Ctrl + Alt + Del` | 打开系统电源菜单 (锁屏/挂起/注销/重启/关机) | `sysact.sh` |

### 窗口管理

| 快捷键 | 功能 |
| :--- | :--- |
| `Mod + j / k` | 聚焦下一个/上一个窗口 |
| `Mod + , / .` | 减小/增大主窗口区域大小 |
| `Mod + s` | 切换主窗口 (Zoom) |
| `Mod + q` | 关闭当前窗口 |
| `Mod + m` | 切换布局 (在预设布局间切换) |
| `Mod + b` | 切换状态栏显示/隐藏 |
| `Mod + u` | 增加窗口间隙 |
| `Mod + Shift + u` | 减少窗口间隙 |
| `Mod + 0` | 切换窗口间隙启用/禁用 |
| `Mod + Shift + 0` | 重置窗口间隙为默认值 |
| `Mod + Tab` | 切换到下一个标签 (viewnexttag) |

### 多媒体控制

*   `XF86AudioRaiseVolume`: 音量 + (并显示通知)
*   `XF86AudioLowerVolume`: 音量 - (并显示通知)
*   `XF86AudioMute`: 静音切换

## 脚本与功能

### 启动脚本 (`scripts/dwm-start`)
这是 dwm 的入口点，负责：
1.  设置环境变量 (输入法等)。
2.  重定向日志到 `~/.dwm.log`。
3.  启动守护进程: `gnome-keyring-daemon`, `polkit-gnome-authentication-agent-1`。
4.  启动状态栏组件: `slstatus`, `pasystray`, `dunst`。
5.  恢复上次使用的壁纸。

### 壁纸切换 (`scripts/wallpaper-next.sh`)
*   读取 `$HOME/Pictures/wallpapers` 目录下的图片。
*   使用 `feh` 顺序切换壁纸。
*   状态保存在 `~/.cache/current_wallpaper`。

### 音量控制 (`scripts/volume.sh`)
*   使用 `wpctl` (PipeWire) 控制音量。
*   使用 `dunstify` 发送带有音量进度条和图标的通知。

### 电源菜单 (`scripts/sysact.sh`)
*   提供锁屏、挂起、注销、重启、关机选项。
*   支持 `rofi` 或 `dmenu` 显示。
*   注销功能使用 `xdotool` 模拟按键退出，安全稳妥。

## 自定义

*   **修改配置**: 编辑 `suckless/dwm/config.h` 并重新运行 `sudo make clean install`。
*   **状态栏信息**: 编辑 `suckless/slstatus/config.h` 修改显示的时间、CPU、内存等模块，并重新编译。
*   **壁纸目录**: 默认指向 `~/Pictures/wallpapers`，可在脚本中修改。

