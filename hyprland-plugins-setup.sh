#!/usr/bin/env bash
# ============================================================================
# Hyprland Plugins Setup Script
# ============================================================================
# Description: Configures Hyprland plugins using hyprpm
# Author: Yeshua (generated with Claude Code)
# Date: 2025-11-25
# ============================================================================
# IMPORTANTE: Ejecuta este script DESPUÉS de:
#   1. Completar post-install-archlinux.sh
#   2. Reiniciar el sistema
#   3. Iniciar sesión en Hyprland
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

# ============================================================================
# Prerequisite Checks
# ============================================================================
check_prerequisites() {
    print_header "Checking Prerequisites"

    # Check if Hyprland is installed
    if ! command -v hyprctl &>/dev/null; then
        print_error "Hyprland no está instalado"
        print_warning "Ejecuta primero: ./post-install-archlinux.sh"
        exit 1
    fi

    # Check if running in Hyprland session
    if [[ "$XDG_CURRENT_DESKTOP" != "Hyprland" ]]; then
        print_error "No estás en una sesión de Hyprland"
        print_warning "Inicia sesión en Hyprland antes de ejecutar este script"
        exit 1
    fi

    # Check if hyprpm is available
    if ! command -v hyprpm &>/dev/null; then
        print_error "hyprpm no está disponible"
        exit 1
    fi

    print_success "Todos los prerequisitos están cumplidos"
}

# ============================================================================
# Install Build Dependencies
# ============================================================================
install_build_deps() {
    print_header "Installing Build Dependencies"

    BUILD_DEPS=(
        base-devel
        cmake
        meson
        ninja
        git
        cpio
    )

    print_warning "Instalando dependencias de compilación..."
    sudo pacman -S --needed --noconfirm "${BUILD_DEPS[@]}"

    print_success "Dependencias instaladas"
}

# ============================================================================
# Setup Hyprland Plugins Repository
# ============================================================================
setup_plugins_repo() {
    print_header "Setting up Hyprland Plugins Repository"

    # Check if repo already added
    if hyprpm list 2>/dev/null | grep -q "hyprland-plugins"; then
        print_warning "Repositorio ya existe, actualizando..."
        hyprpm update
    else
        print_warning "Añadiendo repositorio oficial de plugins..."
        hyprpm add https://github.com/hyprwm/hyprland-plugins
        hyprpm update
    fi

    print_success "Repositorio configurado"
}

# ============================================================================
# Install and Enable Plugins
# ============================================================================
install_plugins() {
    print_header "Installing Hyprland Plugins"

    # Plugins disponibles en el repositorio oficial
    PLUGINS_TO_INSTALL=(
        "borders-plus-plus"  # Bordes mejorados con gradientes
        "hyprscrolling"      # Scrolling mejorado en ventanas
        "hyprexpo"           # Overview de escritorios (como GNOME)
    )

    print_warning "Plugins disponibles:"
    echo "1. borders-plus-plus - Bordes personalizables con gradientes"
    echo "2. hyprscrolling - Mejora el comportamiento del scroll"
    echo "3. hyprexpo - Vista general de escritorios (Expo)"
    echo ""

    read -p "¿Instalar TODOS los plugins? (y/n): " install_all

    if [[ "$install_all" =~ ^[Yy]$ ]]; then
        print_warning "Compilando e instalando plugins (esto puede tardar)..."

        for plugin in "${PLUGINS_TO_INSTALL[@]}"; do
            print_warning "Instalando $plugin..."
            if hyprpm enable "$plugin" 2>/dev/null; then
                print_success "$plugin instalado y habilitado"
            else
                print_warning "$plugin no disponible o ya instalado"
            fi
        done
    else
        print_warning "Instalación manual:"
        echo "Usa: hyprpm enable <plugin-name>"
        echo "Lista de plugins: hyprpm list"
    fi
}

# ============================================================================
# Configure Plugin Settings
# ============================================================================
configure_plugins() {
    print_header "Plugin Configuration"

    print_warning "Configuración de plugins en ~/.config/hypr/hyprland.conf"
    echo ""
    echo "Añade esto a tu configuración de Hyprland:"
    echo ""
    echo "# ========== Hyprland Plugins =========="
    echo "exec-once = hyprpm reload -n  # Cargar plugins al inicio"
    echo ""
    echo "# borders-plus-plus"
    echo "plugin {
    borders-plus-plus {
        add_borders = 1
        col.border_1 = rgb(7aa2f7)  # Tokyo Night blue
        col.border_2 = rgb(bb9af7)  # Tokyo Night purple
        border_size_1 = 2
        border_size_2 = 2
        natural_rounding = yes
    }
}"
    echo ""
    echo "# hyprexpo"
    echo "plugin {
    hyprexpo {
        columns = 3
        gap_size = 5
        bg_col = rgb(1a1b26)
        workspace_method = first 1

        enable_gesture = true
        gesture_fingers = 3
        gesture_distance = 300
    }
}"
    echo ""
    echo "# Bind para hyprexpo (overview)"
    echo "bind = SUPER, grave, hyprexpo:expo, toggle"
    echo ""
}

# ============================================================================
# Summary
# ============================================================================
show_summary() {
    print_header "Installation Complete!"

    echo -e "${GREEN}✓ Plugins de Hyprland configurados${NC}\n"
    echo -e "Comandos útiles:"
    echo -e "  ${BLUE}hyprpm list${NC}         - Ver plugins instalados"
    echo -e "  ${BLUE}hyprpm enable <plugin>${NC}  - Habilitar plugin"
    echo -e "  ${BLUE}hyprpm disable <plugin>${NC} - Deshabilitar plugin"
    echo -e "  ${BLUE}hyprpm reload${NC}       - Recargar plugins"
    echo -e "  ${BLUE}hyprpm update${NC}       - Actualizar repositorio"
    echo ""
    echo -e "${YELLOW}⚠ Reinicia Hyprland para aplicar cambios:${NC}"
    echo -e "  ${BLUE}hyprctl reload${NC} o cierra sesión"
    echo ""
}

# ============================================================================
# Main Script Execution
# ============================================================================
main() {
    print_header "Hyprland Plugins Setup"
    echo "Este script compilará e instalará plugins para Hyprland"
    echo "Puede tardar varios minutos..."
    echo ""
    echo "Press Enter to continue..."
    read

    # Execute steps
    check_prerequisites
    install_build_deps
    setup_plugins_repo
    install_plugins
    configure_plugins
    show_summary
}

# Run main function
main "$@"
