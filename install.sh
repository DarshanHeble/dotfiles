#!/usr/bin/env bash
# ==============================================================================
# Dotfiles Setup & Symlink Installer
# ==============================================================================

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${HOME}/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
DRY_RUN=false

for arg in "$@"; do
    case "$arg" in
        --dry-run|-d)
            DRY_RUN=true
            ;;
        --help|-h)
            echo "Usage: ./install.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -d, --dry-run    Show actions without modifying files"
            echo "  -h, --help       Show this help message"
            exit 0
            ;;
    esac
done

info() { printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
success() { printf "\033[1;32m[OK]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }

safe_link() {
    local src="$1"
    local dest="$2"

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then
            info "Already linked: $dest"
            return
        fi

        if [ "$DRY_RUN" = true ]; then
            info "[Dry-Run] Would backup: $dest -> $BACKUP_DIR"
            info "[Dry-Run] Would link: $src -> $dest"
            return
        fi

        mkdir -p "$BACKUP_DIR"
        local rel_path="${dest#$HOME/}"
        mkdir -p "$BACKUP_DIR/$(dirname "$rel_path")"
        mv "$dest" "$BACKUP_DIR/$rel_path"
        warn "Backed up existing $dest -> $BACKUP_DIR/$rel_path"
    fi

    if [ "$DRY_RUN" = true ]; then
        info "[Dry-Run] Would link: $src -> $dest"
    else
        mkdir -p "$(dirname "$dest")"
        ln -sf "$src" "$dest"
        success "Linked: $dest -> $src"
    fi
}

echo "================================================="
echo " Installing Arch / Niri / Caelestia Dotfiles     "
echo "================================================="

# 1. Symlink ~/.config items
info "Linking configuration directories to ~/.config/..."
for config_item in "${DOTFILES_DIR}/.config"/*; do
    [ -e "$config_item" ] || continue
    name="$(basename "$config_item")"
    if [ "$name" = "systemd" ]; then
        # Handle systemd user units individually to avoid overriding whole systemd dir
        mkdir -p "${HOME}/.config/systemd/user"
        for unit in "${DOTFILES_DIR}/.config/systemd/user"/*; do
            [ -e "$unit" ] || continue
            safe_link "$unit" "${HOME}/.config/systemd/user/$(basename "$unit")"
        done
        continue
    fi
    safe_link "$config_item" "${HOME}/.config/${name}"
done

# 2. Symlink ~/.local/bin scripts
info "Linking custom scripts to ~/.local/bin/..."
mkdir -p "${HOME}/.local/bin"
for bin_item in "${DOTFILES_DIR}/.local/bin"/*; do
    [ -e "$bin_item" ] || continue
    name="$(basename "$bin_item")"
    chmod +x "$bin_item"
    safe_link "$bin_item" "${HOME}/.local/bin/${name}"
done

# 3. Symlink ~/.local/state/caelestia state themes and schemes
if [ -d "${DOTFILES_DIR}/.local/state/caelestia" ]; then
    info "Linking Caelestia scheme & palettes to ~/.local/state/caelestia/..."
    mkdir -p "${HOME}/.local/state/caelestia"
    for state_item in "${DOTFILES_DIR}/.local/state/caelestia"/*; do
        [ -e "$state_item" ] || continue
        name="$(basename "$state_item")"
        safe_link "$state_item" "${HOME}/.local/state/caelestia/${name}"
    done
fi

# 4. Symlink home dotfiles
info "Linking home directory dotfiles..."
for home_file in "${DOTFILES_DIR}/home"/.*; do
    [ -f "$home_file" ] || continue
    name="$(basename "$home_file")"
    [ "$name" = "." ] || [ "$name" = ".." ] && continue
    safe_link "$home_file" "${HOME}/${name}"
done

# 5. dconf settings
if [ -f "${DOTFILES_DIR}/dconf/settings.dconf" ] && command -v dconf &>/dev/null; then
    if [ "$DRY_RUN" = false ]; then
        read -p "Do you want to load dconf desktop settings now? (y/N): " -n 1 -r || true
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            dconf load / < "${DOTFILES_DIR}/dconf/settings.dconf"
            success "Loaded dconf settings"
        fi
    fi
fi

echo "================================================="
success "All dotfiles setup completed successfully!"
if [ -d "$BACKUP_DIR" ]; then
    info "Existing files backed up to: $BACKUP_DIR"
fi
echo "================================================="
