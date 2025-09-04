#!/bin/bash

# Palworld Server Configuration Script
# This script allows easy configuration of Palworld server settings

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration file path
CONFIG_FILE="/home/palworld/palworld-server/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini"
SERVICE_NAME="palworld-server"

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

# Check if config file exists
check_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        error "Configuration file not found at $CONFIG_FILE"
        error "Please run the main setup script first: ./palworld-server-setup.sh"
        exit 1
    fi
    
    # Ensure the directory structure exists
    CONFIG_DIR=$(dirname "$CONFIG_FILE")
    if [ ! -d "$CONFIG_DIR" ]; then
        error "Configuration directory not found: $CONFIG_DIR"
        error "Please run the main setup script first: ./palworld-server-setup.sh"
        exit 1
    fi
}

# Interactive configuration
interactive_config() {
    echo -e "${BLUE}"
    echo "=========================================="
    echo "  Palworld Server Configuration"
    echo "=========================================="
    echo -e "${NC}"
    
    # Get current values
    current_name=$(grep "ServerName=" "$CONFIG_FILE" | cut -d'"' -f2)
    current_desc=$(grep "ServerDescription=" "$CONFIG_FILE" | cut -d'"' -f2)
    current_admin=$(grep "AdminPassword=" "$CONFIG_FILE" | cut -d'"' -f2)
    current_password=$(grep "ServerPassword=" "$CONFIG_FILE" | cut -d'"' -f2)
    current_port=$(grep "PublicPort=" "$CONFIG_FILE" | cut -d'=' -f2 | cut -d',' -f1)
    current_players=$(grep "ServerPlayerMaxNum=" "$CONFIG_FILE" | cut -d'=' -f2 | cut -d',' -f1)
    
    echo "Current configuration:"
    echo "  Server Name: $current_name"
    echo "  Server Description: $current_desc"
    echo "  Admin Password: $current_admin"
    echo "  Server Password: ${current_password:-"None"}"
    echo "  Port: $current_port"
    echo "  Max Players: $current_players"
    echo
    
    # Get new values
    read -p "Enter server name [$current_name]: " new_name
    new_name=${new_name:-$current_name}
    
    read -p "Enter server description [$current_desc]: " new_desc
    new_desc=${new_desc:-$current_desc}
    
    read -p "Enter admin password [$current_admin]: " new_admin
    new_admin=${new_admin:-$current_admin}
    
    read -p "Enter server password (leave empty for no password) [$current_password]: " new_password
    new_password=${new_password:-$current_password}
    
    read -p "Enter server port [$current_port]: " new_port
    new_port=${new_port:-$current_port}
    
    read -p "Enter max players [$current_players]: " new_players
    new_players=${new_players:-$current_players}
    
    # Update configuration
    update_config "$new_name" "$new_desc" "$new_admin" "$new_password" "$new_port" "$new_players"
}

# Update configuration file
update_config() {
    local name="$1"
    local desc="$2"
    local admin="$3"
    local password="$4"
    local port="$5"
    local players="$6"
    
    log "Updating server configuration..."
    
    # Create backup
    cp "$CONFIG_FILE" "$CONFIG_FILE.backup.$(date +%Y%m%d-%H%M%S)"
    
    # Update values in config file
    sed -i "s/ServerName=\".*\"/ServerName=\"$name\"/" "$CONFIG_FILE"
    sed -i "s/ServerDescription=\".*\"/ServerDescription=\"$desc\"/" "$CONFIG_FILE"
    sed -i "s/AdminPassword=\".*\"/AdminPassword=\"$admin\"/" "$CONFIG_FILE"
    sed -i "s/ServerPassword=\".*\"/ServerPassword=\"$password\"/" "$CONFIG_FILE"
    sed -i "s/PublicPort=[0-9]*/PublicPort=$port/" "$CONFIG_FILE"
    sed -i "s/ServerPlayerMaxNum=[0-9]*/ServerPlayerMaxNum=$players/" "$CONFIG_FILE"
    
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
    echo "  Current Palworld Server Configuration"
    echo "=========================================="
    echo -e "${NC}"
    
    if [ -f "$CONFIG_FILE" ]; then
        echo "Server Name: $(grep "ServerName=" "$CONFIG_FILE" | cut -d'"' -f2)"
        echo "Server Description: $(grep "ServerDescription=" "$CONFIG_FILE" | cut -d'"' -f2)"
        echo "Admin Password: $(grep "AdminPassword=" "$CONFIG_FILE" | cut -d'"' -f2)"
        echo "Server Password: $(grep "ServerPassword=" "$CONFIG_FILE" | cut -d'"' -f2)"
        echo "Port: $(grep "PublicPort=" "$CONFIG_FILE" | cut -d'=' -f2 | cut -d',' -f1)"
        echo "Max Players: $(grep "ServerPlayerMaxNum=" "$CONFIG_FILE" | cut -d'=' -f2 | cut -d',' -f1)"
        echo "RCON Port: $(grep "RCONPort=" "$CONFIG_FILE" | cut -d'=' -f2 | cut -d',' -f1)"
        echo "PvP Enabled: $(grep "bIsPvP=" "$CONFIG_FILE" | cut -d'=' -f2 | cut -d',' -f1)"
        echo "Multiplay: $(grep "bIsMultiplay=" "$CONFIG_FILE" | cut -d'=' -f2 | cut -d',' -f1)"
    else
        error "Configuration file not found!"
    fi
}

# Reset to defaults
reset_config() {
    warning "This will reset the server configuration to defaults. Are you sure? (y/n)"
    read -p "> " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        log "Resetting configuration to defaults..."
        
        # Create backup
        cp "$CONFIG_FILE" "$CONFIG_FILE.backup.$(date +%Y%m%d-%H%M%S)"
        
        # Reset to default values
        update_config "Palworld Server" "A Palworld dedicated server" "admin123" "" "8211" "32"
        
        log "Configuration reset to defaults!"
    else
        log "Reset cancelled."
    fi
}

# Show help
show_help() {
    echo "Palworld Server Configuration Script"
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
            check_config
            interactive_config
            ;;
        show|s)
            check_config
            show_config
            ;;
        reset|r)
            check_config
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