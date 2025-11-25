#!/usr/bin/env bash
# ============================================================================
# Ejecutar solo los pasos 19-24 que faltan
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# ============================================================================
# STEP 19: Restore Dotfiles with Stow
# ============================================================================
step_restore_dotfiles() {
    print_header "Restoring Dotfiles"

    DOTFILES_REPO="https://github.com/Jesusado89/.dotfiles"
    DOTFILES_DIR="$HOME/.dotfiles"
    CONFIGS_TO_APPLY=(zsh nvim waybar swaync hypr fuzzel starship qutebrowser kitty)

    if [ ! -d "$DOTFILES_DIR" ]; then
        print_warning "Cloning dotfiles..."
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR" || return 1
    else
        print_warning "Pulling latest changes..."
        cd "$DOTFILES_DIR" && git pull origin main 2>/dev/null || true
    fi

    if [ -d "$DOTFILES_DIR" ]; then
        print_warning "Applying dotfiles with stow..."
        cd "$DOTFILES_DIR"
        for config in "${CONFIGS_TO_APPLY[@]}"; do
            if [ -d "$config" ]; then
                # Backup if exists and is not a symlink
                if [ -d "$HOME/.config/$config" ] && [ ! -L "$HOME/.config/$config" ]; then
                    mv "$HOME/.config/$config" "$HOME/.config/${config}.bak"
                fi

                stow -v "$config" 2>/dev/null || stow -R "$config" 2>/dev/null
            fi
        done
        cd "$HOME"
        print_success "Dotfiles configuration complete"
    fi
}

# ============================================================================
# STEP 20: Setup Services
# ============================================================================
step_setup_services() {
    print_header "Enabling Services"

    sudo systemctl enable --now NetworkManager
    sudo systemctl enable --now ly
    sudo systemctl enable --now power-profiles-daemon

    if [ -f /etc/systemd/zram-generator.conf ]; then
        sudo systemctl daemon-reload
        sudo systemctl start systemd-zram-setup@zram0.service
    fi

    print_success "Services enabled"
}

# ============================================================================
# STEP 21: Performance Optimizations
# ============================================================================
step_performance_optimization() {
    print_header "Applying Performance Optimizations"

    if [ ! -f /etc/systemd/zram-generator.conf ]; then
        sudo tee /etc/systemd/zram-generator.conf >/dev/null <<EOF
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF
    fi

    if ! grep -q "^ParallelDownloads" /etc/pacman.conf; then
        sudo sed -i 's/#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
    fi

    print_success "Performance optimizations applied"
}

# ============================================================================
# STEP 22: Setup Claude Code
# ============================================================================
step_setup_claude_code() {
    print_header "Setting up Claude Code Configuration"

    if [[ ! -d "$HOME/.dotfiles/claude" ]]; then
        print_warning "Claude config not found, skipping..."
        return
    fi

    # Config Link
    mkdir -p "$HOME/.config"
    if [[ ! -L "$HOME/.config/claude" ]]; then
        ln -sf "$HOME/.dotfiles/claude" "$HOME/.config/claude"
    fi

    # Scripts Links
    mkdir -p "$HOME/.local/bin"
    for script in searxng-search claude-backup claude-check; do
        if [[ -f "$HOME/.dotfiles/scripts/$script" ]]; then
            ln -sf "$HOME/.dotfiles/scripts/$script" "$HOME/.local/bin/$script"
            chmod +x "$HOME/.dotfiles/scripts/$script"
        fi
    done

    # SearXNG Link
    if [[ -d "$HOME/.dotfiles/searxng" ]] && [[ ! -L "$HOME/searxng" ]]; then
        if [[ -d "$HOME/searxng" ]]; then mv "$HOME/searxng" "$HOME/searxng.bak"; fi
        ln -sf "$HOME/.dotfiles/searxng" "$HOME/searxng"
    fi

    print_success "Claude Code setup complete"
}

# ============================================================================
# STEP 23: Cleanup
# ============================================================================
step_cleanup() {
    print_header "Cleaning up"
    if command -v paru &>/dev/null; then
        paru -Sc --noconfirm
    fi
    sudo pacman -Sc --noconfirm
    print_success "Cleanup complete"
}

# ============================================================================
# STEP 24: Summary
# ============================================================================
step_summary() {
    print_header "Missing Steps Completed!"
    echo -e "${GREEN}✓ Dotfiles restored and configuration complete${NC}\n"
    echo -e "${BLUE}Después del reinicio (OPCIONAL):${NC}"
    echo -e "  ${YELLOW}•${NC} Para instalar plugins de Hyprland:"
    echo -e "    ${BLUE}cd ~/post_install && ./hyprland-plugins-setup.sh${NC}"
    echo -e "    ${YELLOW}⚠${NC} Requiere sesión activa de Hyprland"
    echo ""
}

# ============================================================================
# Main Execution
# ============================================================================
main() {
    print_header "Ejecutando pasos faltantes (19-24)"
    echo "Press Enter to continue..."
    read

    step_restore_dotfiles
    step_setup_services
    step_performance_optimization
    step_setup_claude_code
    step_cleanup
    step_summary
}

main "$@"
