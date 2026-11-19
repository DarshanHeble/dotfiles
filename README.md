# Personal Linux Configurations & Dotfiles

Personal configuration files and environment setup for Arch Linux.

## Highlights
- **Compositor:** Niri (Scrollable-tiling Wayland compositor) & Hyprland
- **Desktop Shell:** Caelestia Shell (QuickShell based desktop UI, drawers, widgets)
- **Terminals:** Ghostty, Kitty, Foot, Alacritty
- **Shell:** Bash (with Starship & Zoxide) and Fish
- **Editors:** Neovim, Zed, Code - OSS
- **Launchers & Controls:** Custom scripts in `.local/bin` for audio, brightness, nightlight, and shortcuts

## Directory Layout
- `.config/`: Application configurations (Caelestia, Niri, Hyprland, terminals, editors)
- `.local/bin/`: Custom helper and launcher scripts
- `home/`: Root dotfiles (.bashrc, .bash_profile, .inputrc, .gitconfig)
- `dconf/`: Exported desktop settings

## Setup
Run the included installation script to link configurations:
```bash
./install.sh
```
Use `./install.sh --dry-run` to preview actions without making changes.
