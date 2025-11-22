#!/usr/bin/env bash
# ============================================================================
# Arch Linux Post-Installation Script
# ============================================================================
# Description: Complete setup script for Arch Linux with Hyprland
# Author: Yeshua (generated with Claude Code)
# Date: $(date +%Y-%m-%d)
# ============================================================================

set -e # Exit on error

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

check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should NOT be run as root (except for specific parts)"
        exit 1
    fi
}

# ============================================================================
# STEP 1: System Update
# ============================================================================
step_system_update() {
    print_header "Updating System"
    sudo pacman -Syu --noconfirm
    print_success "System updated"
}

# ============================================================================
# STEP 2: Setup Chaotic-AUR Repository
# ============================================================================
step_setup_chaotic_aur() {
    print_header "Setting up Chaotic-AUR"

    # Check if already configured
    if grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
        print_success "Chaotic-AUR already configured"
        return
    fi

    print_warning "Installing Chaotic-AUR keyring and mirrorlist..."
    sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    sudo pacman-key --lsign-key 3056513887B78AEB
    sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
    sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

    # Add Chaotic-AUR to pacman.conf
    if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
        sudo tee -a /etc/pacman.conf >/dev/null <<EOF

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOF
        print_success "Chaotic-AUR repository added to pacman.conf"
    fi

    # Update package databases
    sudo pacman -Sy

    print_success "Chaotic-AUR configured"
}

# ============================================================================
# STEP 3: Install paru (AUR helper) if not installed
# ============================================================================
step_install_paru() {
    print_header "Installing paru (AUR Helper)"

    if command -v paru &>/dev/null; then
        print_success "paru already installed"
        return
    fi

    print_warning "Installing paru..."
    cd /tmp
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si --noconfirm
    cd ~
    rm -rf /tmp/paru
    print_success "paru installed"
}

# ============================================================================
# STEP 4: Install Essential Packages
# ============================================================================
step_install_essentials() {
    print_header "Installing Essential Packages"

    ESSENTIALS=(
        # Base system
        base base-devel linux-zen linux-zen-headers linux-firmware
        intel-ucode efibootmgr btrfs-progs

        # Network
        networkmanager openssh

        # Shell & Terminal
        zsh starship kitty

        # Editor
        neovim

        # Essential tools
        git wget curl unzip 7zip stow
    )

    sudo pacman -S --needed --noconfirm "${ESSENTIALS[@]}"
    print_success "Essential packages installed"
}

# ============================================================================
# STEP 5: Install Modern CLI Tools
# ============================================================================
step_install_modern_cli() {
    print_header "Installing Modern CLI Tools"

    MODERN_CLI=(
        # Core replacements
        bat eza fd ripgrep fzf zoxide sd

        # System monitoring
        btop bottom procs dust duf

        # Performance
        hyperfine

        # Development
        tokei tealdeer

        # Git tools
        git-delta lazygit github-cli glab

        # File managers
        yazi # Terminal file manager with vi keybindings

        # Additional CLI tools
        tree # Directory tree
    )

    sudo pacman -S --needed --noconfirm "${MODERN_CLI[@]}"
    print_success "Modern CLI tools installed"
}

# ============================================================================
# STEP 6: Install Hyprland & Wayland Ecosystem
# ============================================================================
step_install_hyprland() {
    print_header "Installing Hyprland & Wayland"

    HYPRLAND=(
        # Hyprland core
        hyprland hyprpaper hyprlock hypridle hyprsunset
        hyprshot hyprpicker hyprpolkitagent

        # Hyprland IPC
        dipc

        # Wayland essentials
        waybar swaync fuzzel wlogout

        # Display manager
        ly

        # Clipboard manager
        cliphist wl-clipboard

        # Bluetooth applet
        blueman

        # Utilities
        nwg-look brightnessctl
        gst-plugin-pipewire
    )

    sudo pacman -S --needed --noconfirm "${HYPRLAND[@]}"
    print_success "Hyprland installed"
}

# ============================================================================
# STEP 7: Configure Hyprland Plugins (hyprpm)
# ============================================================================
step_configure_hyprpm() {
    print_header "Configuring Hyprland Plugins"

    # Check if hyprland is installed
    if ! command -v hyprctl &>/dev/null; then
        print_warning "Hyprland not installed, skipping plugins"
        return
    fi

    print_warning "Adding hyprland-plugins repository..."

    # Add the official plugins repository
    hyprpm add https://github.com/hyprwm/hyprland-plugins || print_warning "Repository already added"

    # Update plugin repository
    hyprpm update

    # Install and enable hyprscrolling
    print_warning "Enabling hyprscrolling plugin..."
    hyprpm enable hyprscrolling

    # Reload plugins (will be done on next Hyprland start)
    print_success "Hyprland plugins configured"
    print_warning "Note: Plugins will be loaded when you start Hyprland"
    print_warning "Add 'exec-once = hyprpm reload -n' to your hyprland.conf"
}

# ============================================================================
# STEP 8: Install Audio (PipeWire)
# ============================================================================
step_install_audio() {
    print_header "Installing Audio (PipeWire)"

    AUDIO=(
        pipewire pipewire-alsa pipewire-jack pipewire-pulse
        wireplumber libpulse sof-firmware
    )

    sudo pacman -S --needed --noconfirm "${AUDIO[@]}"
    systemctl --user enable --now pipewire pipewire-pulse wireplumber
    print_success "PipeWire audio configured"
}

# ============================================================================
# STEP 9: Install Development Tools
# ============================================================================
step_install_dev_tools() {
    print_header "Installing Development Tools"

    DEV_TOOLS=(
        # Build tools
        cmake meson ninja

        # Languages
        go

        # Docker
        docker docker-buildx docker-compose

        # Editors & IDEs
        vscodium

        # Other
        lazydocker
    )

    sudo pacman -S --needed --noconfirm "${DEV_TOOLS[@]}"

    # Enable Docker
    sudo systemctl enable --now docker
    sudo usermod -aG docker $USER

    print_success "Development tools installed"
}

# ============================================================================
# STEP 10: Install Node.js Manager (fnm)
# ============================================================================
step_install_fnm() {
    print_header "Installing fnm (Fast Node Manager)"

    if command -v fnm &>/dev/null; then
        print_success "fnm already installed"
        return
    fi

    curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
    print_success "fnm installed"
}

# ============================================================================
# STEP 11: Install Python Tools
# ============================================================================
step_install_python() {
    print_header "Installing Python Tools"

    sudo pacman -S --needed --noconfirm python python-pip
    paru -S --needed --noconfirm uv # Modern Python package manager

    print_success "Python tools installed"
}

# ============================================================================
# STEP 12: Install Fonts
# ============================================================================
step_install_fonts() {
    print_header "Installing Fonts"

    FONTS=(
        ttf-fira-code
        ttf-firacode-nerd
        ttf-nerd-fonts-symbols-mono
        noto-fonts-emoji
    )

    sudo pacman -S --needed --noconfirm "${FONTS[@]}"
    fc-cache -fv
    print_success "Fonts installed"
}

# ============================================================================
# STEP 13: Install Browsers
# ============================================================================
step_install_browsers() {
    print_header "Installing Browsers"

    sudo pacman -S --needed --noconfirm firefox-developer-edition qutebrowser

    print_success "Browsers installed"
}

# ============================================================================
# STEP 14: Install Themes
# ============================================================================
step_install_themes() {
    print_header "Installing Themes"

    paru -S --needed --noconfirm tokyonight-gtk-theme-git rose-pine-gtk-theme-full

    print_success "Themes installed"
}

# ============================================================================
# STEP 15: Install Additional Tools
# ============================================================================
step_install_additional() {
    print_header "Installing Additional Tools"

    ADDITIONAL=(
        # VPN
        protonvpn-cli

        # File manager (GUI for backup)
        nemo

        # System
        bluez bluez-utils
        fastfetch
        power-profiles-daemon
        dmidecode
        xclip
        cpio

        # Scheduler
        scx-scheds

        # Python tools
        python-adblock # For qutebrowser

        # zRAM
        zram-generator

        # Keyring
        gnome-keyring
    )

    sudo pacman -S --needed --noconfirm "${ADDITIONAL[@]}"

    # Enable Bluetooth
    sudo systemctl enable --now bluetooth

    print_success "Additional tools installed"
}

# ============================================================================
# STEP 16: Install Claude Code & Other AUR
# ============================================================================
step_install_aur() {
    print_header "Installing AUR Packages"

    AUR_PACKAGES=(
        claude-code # Claude AI in terminal
        bun-bin     # JavaScript runtime
        localsend   # Local file sharing
        yaak        # API client
    )

    paru -S --needed --noconfirm "${AUR_PACKAGES[@]}"

    print_success "AUR packages installed"
}

# ============================================================================
# STEP 17: Setup ZSH
# ============================================================================
step_setup_zsh() {
    print_header "Setting up ZSH"

    # Change default shell to ZSH
    if [[ "$SHELL" != *"zsh"* ]]; then
        print_warning "Changing default shell to ZSH..."
        chsh -s $(which zsh)
        print_success "Default shell changed to ZSH (logout required)"
    fi

    # Install zinit (plugin manager)
    if [ ! -d "${HOME}/.local/share/zinit/zinit.git" ]; then
        print_warning "Installing zinit..."
        bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
        print_success "zinit installed"
    else
        print_success "zinit already installed"
    fi

    # Backup existing .zshrc
    if [ -f ~/.zshrc ] && [ ! -f ~/.zshrc.backup ]; then
        cp ~/.zshrc ~/.zshrc.backup
        print_success "Backed up existing .zshrc to .zshrc.backup"
    fi

    print_success "ZSH setup complete"
}

# ============================================================================
# STEP 18: Setup Git
# ============================================================================
step_setup_git() {
    print_header "Setting up Git"

    # Check if git is already configured
    if git config --global user.name &>/dev/null; then
        print_success "Git already configured"
        return
    fi

    read -p "Enter your Git name: " git_name
    read -p "Enter your Git email: " git_email

    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    git config --global init.defaultBranch main
    git config --global core.pager delta
    git config --global interactive.diffFilter "delta --color-only"

    print_success "Git configured with Delta"
}

# ============================================================================
# STEP 19: Restore Dotfiles with Stow
# ============================================================================
step_restore_dotfiles() {
    print_header "Restoring Dotfiles"

    DOTFILES_REPO="https://github.com/Jesusado89/.dotfiles"
    DOTFILES_DIR="$HOME/.dotfiles"

    # Configurations to apply with stow
    CONFIGS_TO_APPLY=(
        zsh
        nvim
        waybar
        swaync
        hypr
        fuzzel
        starship
        qutebrowser
        kitty
    )

    # Clone dotfiles if not exists
    if [ ! -d "$DOTFILES_DIR" ]; then
        print_warning "Cloning dotfiles from $DOTFILES_REPO..."
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR" || {
            print_error "Failed to clone dotfiles repository"
            return 1
        }
        print_success "Dotfiles cloned successfully"
    else
        print_success "Dotfiles directory already exists"
        # Pull latest changes
        print_warning "Pulling latest changes..."
        cd "$DOTFILES_DIR"
        git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || print_warning "Could not pull latest changes"
    fi

    # Apply configurations with stow
    if [ -d "$DOTFILES_DIR" ]; then
        print_warning "Applying dotfiles with stow..."
        cd "$DOTFILES_DIR"

        # List available configurations
        echo -e "${YELLOW}Available configurations in dotfiles:${NC}"
        ls -d */ 2>/dev/null | sed 's#/##g'
        echo ""

        echo -e "${YELLOW}Applying selected configurations:${NC}"
        for config in "${CONFIGS_TO_APPLY[@]}"; do
            if [ -d "$config" ]; then
                echo -e "${BLUE}Applying $config...${NC}"
                if stow -v "$config" 2>/dev/null; then
                    print_success "Applied $config"
                else
                    # Try restow to fix conflicts
                    if stow -R "$config" 2>/dev/null; then
                        print_success "Re-applied $config (resolved conflicts)"
                    else
                        print_warning "Could not apply $config (conflicts exist)"
                    fi
                fi
            else
                print_warning "$config directory not found in dotfiles"
            fi
        done

        cd "$HOME"
        print_success "Dotfiles configuration complete"
    else
        print_error "Dotfiles directory not accessible"
        return 1
    fi
}

# ============================================================================
# STEP 20: Setup Services
# ============================================================================
step_setup_services() {
    print_header "Enabling Services"

    # Enable NetworkManager
    sudo systemctl enable --now NetworkManager

    # Enable ly (display manager)
    sudo systemctl enable --now ly

    # Enable power-profiles-daemon
    sudo systemctl enable --now power-profiles-daemon

    # Enable zram
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

    # zRAM configuration
    if [ ! -f /etc/systemd/zram-generator.conf ]; then
        sudo tee /etc/systemd/zram-generator.conf >/dev/null <<EOF
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF
        print_success "zRAM configured"
    fi

    # Pacman parallel downloads
    if ! grep -q "^ParallelDownloads" /etc/pacman.conf; then
        sudo sed -i 's/#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
        print_success "Pacman parallel downloads enabled"
    fi

    print_success "Performance optimizations applied"
}

# ============================================================================
# STEP 22: Cleanup
# ============================================================================
step_cleanup() {
    print_header "Cleaning up"

    paru -Sc --noconfirm
    sudo pacman -Sc --noconfirm

    print_success "Cleanup complete"
}

# ============================================================================
# STEP 23: Summary & Post-Install Instructions
# ============================================================================
step_summary() {
    print_header "Installation Complete!"

    echo -e "${GREEN}✓ System fully configured${NC}\n"

    echo -e "${YELLOW}Post-Installation Steps:${NC}"
    echo "1. Logout and login again to apply shell changes"
    echo "2. Run 'source ~/.zshrc' to load ZSH configuration"
    echo "3. Test Hyprland: logout and select Hyprland session"
    echo "4. Configure your dotfiles if you have them"
    echo ""

    echo -e "${YELLOW}Useful Commands:${NC}"
    echo "  paru -Syu          # Update system & AUR"
    echo "  btop               # System monitor"
    echo "  lazygit            # Git TUI"
    echo "  lazydocker         # Docker TUI"
    echo "  fastfetch          # System info"
    echo ""

    echo -e "${YELLOW}Next Steps:${NC}"
    echo "1. Configure Hyprland: ~/.config/hypr/hyprland.conf"
    echo "2. Configure Waybar: ~/.config/waybar/"
    echo "3. Setup your development environment"
    echo "4. Restore your dotfiles if you have them"
    echo ""

    echo -e "${GREEN}Enjoy your Arch Linux setup! 🚀${NC}\n"
}

# ============================================================================
# Main Script Execution
# ============================================================================
main() {
    check_root

    print_header "Arch Linux Post-Installation Script"
    echo "This script will install and configure your system"
    echo "Press Ctrl+C to cancel, or Enter to continue..."
    read

    # Execute steps
    step_system_update
    step_setup_chaotic_aur
    step_install_paru
    step_install_essentials
    step_install_modern_cli
    step_install_hyprland
    step_configure_hyprpm
    step_install_audio
    step_install_dev_tools
    step_install_fnm
    step_install_python
    step_install_fonts
    step_install_browsers
    step_install_themes
    step_install_additional
    step_install_aur
    step_setup_zsh
    step_setup_git
    step_restore_dotfiles
    step_setup_services
    step_performance_optimization
    step_cleanup
    step_summary
}

# Run main function
main "$@"
