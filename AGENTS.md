# AGENTS.md - Mint DWM Configuration

This is a DWM (Dynamic Window Manager) configuration repository for Linux Mint. It contains C source code (suckless tools), shell scripts, Python scripts, and configuration files.

## Build & Development Commands

### Building Suckless Components

Each suckless component (dwm, st, slock, slstatus, dmenu) has its own Makefile:

```bash
# Build and install a specific component
cd suckless/dwm && sudo make clean install
cd suckless/slstatus && sudo make clean install
cd suckless/slock && sudo make clean install
cd suckless/st && sudo make clean install
cd suckless/dmenu && sudo make clean install

# Build only (no install)
cd suckless/dwm && make
```

### Python Scripts

```bash
# Theme synchronization script
python3 scripts/sync_theme.py
```

### Full Installation

```bash
# Full installation with all dependencies
./install.sh

# Partial operations
./install.sh themes    # Install GTK themes only
./install.sh icons     # Install GTK icon themes only
./install.sh links     # Setup config symlinks only

# Dry-run mode (shows what would be done)
./install.sh --dry-run
```

### Testing

There are **no automated tests** in this repository. Manual testing is required after any changes:
- Restart DWM (Mod+Shift+E) after modifying dwm config
- Reload Xresources: `xrdb ~/.Xresources`
- Restart services: `killall slstatus; slstatus &`

## Code Style Guidelines

### C Code (suckless/*)

- **Formatting**: Follow the suckless style - 4-space indentation, no tabs
- **Naming**: lowercase_with_underscores for variables and functions
- **Headers**: Group includes: system headers, X11 headers, local headers
- **Error Handling**: Return -1 on error, 0 on success; use NULL for pointers
- **No external dependencies**: Stick to X11/libc only (no libconfig, etc.)
- **Configuration**: Only modify `suckless/*/config.h` - never modify `config.def.h`
  - The `config.def.h` files are templates; `config.h` is the active config

### Python Scripts

- **Shebang**: `#!/usr/bin/env python3`
- **Imports**: Standard library first, then third-party
- **Formatting**: Follow PEP 8 (4 spaces, snake_case)
- **Error Handling**: Use try/except with specific exceptions; print error messages to stderr

Example structure:
```python
#!/usr/bin/env python3
import os
import sys

def main():
    pass

if __name__ == "__main__":
    main()
```

### Shell Scripts

- **Shebang**: `#!/bin/bash` or `#!/usr/bin/env bash`
- **Error Handling**: Use `set -euo pipefail`
- **Formatting**: 4 spaces for indentation, not tabs
- **Variables**: Use `${VAR}` for clarity; quote variables with spaces
- **Functions**: Define local variables with `local`
- **Logging**: Use defined color functions (log_info, log_success, log_error)

### Configuration Files

- **Xresources**: Use prefix naming (e.g., `dwm.*`, `st.*`, `rofi.*`)
- **Rofi themes**: Follow therasi format with colon spacing
- **Dunst**: Standard dunstrc format with section headers
- **Alacritty**: TOML format with consistent indentation

## Project Structure

```
mint-dwm/
├── install.sh          # Main installation script
├── suckless/            # C source code (dwm, st, slock, slstatus, dmenu)
│   ├── dwm/
│   ├── st/
│   ├── slock/
│   ├── slstatus/
│   └── dmenu/
├── scripts/             # Shell and Python scripts
├── config/              # Configuration files (symlinked to ~)
├── themes/              # Xresources theme presets
├── tools/               # Helper tools and scripts
└── fonts/               # Local font files
```

## Important Notes

1. **Cursor Rules**: Do NOT modify `suckless/*/config.def.h`. Only modify `suckless/*/config.h` for configuration changes.

2. **Hardcoded Paths**: The repository expects to be at `~/.config/mint-dwm`. Do not move it.

3. **Symlinks**: The install.sh sets up symlinks from `~/` to config files. Do not move these.

4. **Dependencies**: Ensure all build and runtime dependencies are installed before compiling.

5. **Permissions**: Scripts need executable permission (`chmod +x`).

## Common Development Tasks

```bash
# Rebuild dwm after config change
cd suckless/dwm && make clean && make && sudo make install

# Reload DWM config without full restart
# (DWM requires restart for config changes)

# Update theme across all apps
python3 scripts/sync_theme.py

# Reload Xresources
xrdb ~/.Xresources
```