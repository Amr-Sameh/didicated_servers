#!/bin/bash

# The Forest Server Configuration Script
# This script allows easy configuration of The Forest server settings

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Service name
SERVICE_NAME="forest-server"

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check if service exists
check_service() {
    if ! systemctl list-unit-files | grep -q "$SERVICE_NAME.service"; then
        error "The Forest server service not found. Please run the setup script first."
        exit 1
    fi
}

# Interactive configuration
interactive_config() {
    echo -e "${BLUE}"
    echo "=========================================="
    echo "  The Forest Server Configuration"
    echo "=========================================="
    echo -e "${NC}"
    
    # Get current values from systemd service
    current_name=$(systemctl show forest-server --property=Environment | grep SERVER_NAME | cut -d'=' -f2 | tr -d '"')
    current_password=$(systemctl show forest-server --property=Environment | grep SERVER_PASSWORD | cut -d'=' -f2 | tr -d '"')
    current_slots=$(systemctl show forest-server --property=Environment | grep SERVER_SLOTS | cut -d'=' -f2 | tr -d '"')
    current_port=$(systemctl show forest-server --property=Environment | grep SERVER_PORT | cut -d'=' -f2 | tr -d '"')
    current_vac=$(systemctl show forest-server --property=Environment | grep ENABLE_VAC | cut -d'=' -f2 | tr -d '"')
    current_save_slot=$(systemctl show forest-server --property=Environment | grep SAVE_SLOT | cut -d'=' -f2 | tr -d '"')
    current_game_mode=$(systemctl show forest-server --property=Environment | grep GAME_MODE | cut -d'=' -f2 | tr -d '"')
    current_difficulty=$(systemctl show forest-server --property=Environment | grep DIFFICULTY | cut -d'=' -f2 | tr -d '"')
    
    echo "Current configuration:"
    echo "  Server Name: $current_name"
    echo "  Server Password: ${current_password:-"None"}"
    echo "  Max Players: $current_slots"
    echo "  Server Port: $current_port"
    echo "  VAC Enabled: $current_vac"
    echo "  Save Slot: $current_save_slot"
    echo "  Game Mode: $current_game_mode"
    echo "  Difficulty: $current_difficulty"
    echo
    
    # Get new values
    read -p "Enter server name [$current_name]: " new_name
    new_name=${new_name:-$current_name}
    
    read -p "Enter server password (leave empty for no password) [$current_password]: " new_password
    new_password=${new_password:-$current_password}
    
    read -p "Enter max players (1-8) [$current_slots]: " new_slots
    new_slots=${new_slots:-$current_slots}
    
    read -p "Enter server port [$current_port]: " new_port
    new_port=${new_port:-$current_port}
    
    read -p "Enable VAC (true/false) [$current_vac]: " new_vac
    new_vac=${new_vac:-$current_vac}
    
    read -p "Enter save slot (1-5) [$current_save_slot]: " new_save_slot
    new_save_slot=${new_save_slot:-$current_save_slot}
    
    echo "Game Mode options:"
    echo "  Standard - Normal survival game"
    echo "  Creative - Creative mode with unlimited resources"
    echo "  Peaceful - No enemies"
    echo "  Hard - Increased difficulty"
    read -p "Enter game mode [$current_game_mode]: " new_game_mode
    new_game_mode=${new_game_mode:-$current_game_mode}
    
    echo "Difficulty options:"
    echo "  Peaceful - No enemies attack"
    echo "  Normal - Standard difficulty"
    echo "  Hard - Increased enemy difficulty"
    read -p "Enter difficulty [$current_difficulty]: " new_difficulty
    new_difficulty=${new_difficulty:-$current_difficulty}
    
    # Update configuration
    update_config "$new_name" "$new_password" "$new_slots" "$new_port" "$new_vac" "$new_save_slot" "$new_game_mode" "$new_difficulty"
}

# Update configuration
update_config() {
    local name="$1"
    local password="$2"
    local slots="$3"
    local port="$4"
    local vac="$5"
    local save_slot="$6"
    local game_mode="$7"
    local difficulty="$8"
    
    log "Updating server configuration..."
    
    # Create override directory
    sudo mkdir -p "/etc/systemd/system/forest-server.service.d"
    
    # Create override file
    sudo tee "/etc/systemd/system/forest-server.service.d/override.conf" > /dev/null << EOF
[Service]
Environment=SERVER_NAME="$name"
Environment=SERVER_PASSWORD="$password"
Environment=SERVER_SLOTS="$slots"
Environment=SERVER_PORT="$port"
Environment=ENABLE_VAC="$vac"
Environment=SAVE_SLOT="$save_slot"
Environment=GAME_MODE="$game_mode"
Environment=DIFFICULTY="$difficulty"
EOF

    # Reload systemd
    sudo systemctl daemon-reload
    
    log "Configuration updated successfully!"
    
    # Ask if user wants to restart server
    read -p "Do you want to restart the server to apply changes? (y/n): " restart
    if [[ $restart =~ ^[Yy]$ ]]; then
        log "Restarting server..."
        sudo systemctl restart "$SERVICE_NAME"
        log "Server restarted!"
    fi
}

# Show current configuration
show_config() {
    echo -e "${BLUE}"
    echo "=========================================="
    echo "  Current The Forest Server Configuration"
    echo "=========================================="
    echo -e "${NC}"
    
    if systemctl list-unit-files | grep -q "$SERVICE_NAME.service"; then
        echo "Server Name: $(systemctl show forest-server --property=Environment | grep SERVER_NAME | cut -d'=' -f2 | tr -d '"')"
        echo "Server Password: $(systemctl show forest-server --property=Environment | grep SERVER_PASSWORD | cut -d'=' -f2 | tr -d '"')"
        echo "Max Players: $(systemctl show forest-server --property=Environment | grep SERVER_SLOTS | cut -d'=' -f2 | tr -d '"')"
        echo "Server Port: $(systemctl show forest-server --property=Environment | grep SERVER_PORT | cut -d'=' -f2 | tr -d '"')"
        echo "VAC Enabled: $(systemctl show forest-server --property=Environment | grep ENABLE_VAC | cut -d'=' -f2 | tr -d '"')"
        echo "Save Slot: $(systemctl show forest-server --property=Environment | grep SAVE_SLOT | cut -d'=' -f2 | tr -d '"')"
        echo "Game Mode: $(systemctl show forest-server --property=Environment | grep GAME_MODE | cut -d'=' -f2 | tr -d '"')"
        echo "Difficulty: $(systemctl show forest-server --property=Environment | grep DIFFICULTY | cut -d'=' -f2 | tr -d '"')"
        echo "Tree Regrowth: $(systemctl show forest-server --property=Environment | grep ENABLE_TREE_REGROWTH | cut -d'=' -f2 | tr -d '"')"
        echo ""
        echo "Service Status:"
        systemctl status forest-server --no-pager
    else
        error "The Forest server service not found!"
    fi
}

# Reset to defaults
reset_config() {
    warning "This will reset the server configuration to defaults. Are you sure? (y/n)"
    read -p "> " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        log "Resetting configuration to defaults..."
        
        # Remove override file
        sudo rm -f "/etc/systemd/system/forest-server.service.d/override.conf"
        
        # Reload systemd
        sudo systemctl daemon-reload
        
        log "Configuration reset to defaults!"
        
        # Ask if user wants to restart server
        read -p "Do you want to restart the server to apply changes? (y/n): " restart
        if [[ $restart =~ ^[Yy]$ ]]; then
            log "Restarting server..."
            sudo systemctl restart "$SERVICE_NAME"
            log "Server restarted!"
        fi
    else
        log "Reset cancelled."
    fi
}

# Show help
show_help() {
    echo "The Forest Server Configuration Script"
    echo
    echo "Usage: $0 [option]"
    echo
    echo "Options:"
    echo "  configure, config, c    - Interactive configuration"
    echo "  show, s                 - Show current configuration"
    echo "  reset, r                - Reset to default configuration"
    echo "  help, h                 - Show this help message"
    echo
    echo "Examples:"
    echo "  $0 configure    # Interactive configuration"
    echo "  $0 show         # Show current settings"
    echo "  $0 reset        # Reset to defaults"
}

# Main function
main() {
    case "${1:-configure}" in
        configure|config|c)
            check_service
            interactive_config
            ;;
        show|s)
            check_service
            show_config
            ;;
        reset|r)
            check_service
            reset_config
            ;;
        help|h|--help|-h)
            show_help
            ;;
        *)
            error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"