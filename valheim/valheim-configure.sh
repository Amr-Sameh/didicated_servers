#!/bin/bash

# Valheim Server Configuration Script
# This script allows easy configuration of Valheim server settings

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Service name
SERVICE_NAME="valheim-server"

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
        error "Valheim server service not found. Please run the setup script first."
        exit 1
    fi
}

# Interactive configuration
interactive_config() {
    echo -e "${BLUE}"
    echo "=========================================="
    echo "  Valheim Server Configuration"
    echo "=========================================="
    echo -e "${NC}"
    
    # Get current values from systemd service
    current_name=$(systemctl show valheim-server --property=Environment | grep SERVER_NAME | cut -d'=' -f2 | tr -d '"')
    current_password=$(systemctl show valheim-server --property=Environment | grep SERVER_PASSWORD | cut -d'=' -f2 | tr -d '"')
    current_world=$(systemctl show valheim-server --property=Environment | grep SERVER_WORLD | cut -d'=' -f2 | tr -d '"')
    current_public=$(systemctl show valheim-server --property=Environment | grep SERVER_PUBLIC | cut -d'=' -f2 | tr -d '"')
    current_port=$(systemctl show valheim-server --property=Environment | grep SERVER_PORT | cut -d'=' -f2 | tr -d '"')
    current_query_port=$(systemctl show valheim-server --property=Environment | grep SERVER_QUERY_PORT | cut -d'=' -f2 | tr -d '"')
    current_plus=$(systemctl show valheim-server --property=Environment | grep SERVER_PLUS | cut -d'=' -f2 | tr -d '"')
    
    echo "Current configuration:"
    echo "  Server Name: $current_name"
    echo "  Server Password: ${current_password:-"None"}"
    echo "  World Name: $current_world"
    echo "  Public Server: $current_public"
    echo "  Server Port: $current_port"
    echo "  Query Port: $current_query_port"
    echo "  Valheim Plus: $current_plus"
    echo
    
    # Get new values
    read -p "Enter server name [$current_name]: " new_name
    new_name=${new_name:-$current_name}
    
    read -p "Enter server password (leave empty for no password) [$current_password]: " new_password
    new_password=${new_password:-$current_password}
    
    read -p "Enter world name [$current_world]: " new_world
    new_world=${new_world:-$current_world}
    
    read -p "Make server public? (true/false) [$current_public]: " new_public
    new_public=${new_public:-$current_public}
    
    read -p "Enter server port [$current_port]: " new_port
    new_port=${new_port:-$current_port}
    
    read -p "Enter query port [$current_query_port]: " new_query_port
    new_query_port=${new_query_port:-$current_query_port}
    
    read -p "Enable Valheim Plus? (true/false) [$current_plus]: " new_plus
    new_plus=${new_plus:-$current_plus}
    
    # Update configuration
    update_config "$new_name" "$new_password" "$new_world" "$new_public" "$new_port" "$new_query_port" "$new_plus"
}

# Update configuration
update_config() {
    local name="$1"
    local password="$2"
    local world="$3"
    local public="$4"
    local port="$5"
    local query_port="$6"
    local plus="$7"
    
    log "Updating server configuration..."
    
    # Create override directory
    sudo mkdir -p "/etc/systemd/system/valheim-server.service.d"
    
    # Create override file
    sudo tee "/etc/systemd/system/valheim-server.service.d/override.conf" > /dev/null << EOF
[Service]
Environment=SERVER_NAME="$name"
Environment=SERVER_PASSWORD="$password"
Environment=SERVER_WORLD="$world"
Environment=SERVER_PUBLIC="$public"
Environment=SERVER_PORT="$port"
Environment=SERVER_QUERY_PORT="$query_port"
Environment=SERVER_PLUS="$plus"
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
    echo "  Current Valheim Server Configuration"
    echo "=========================================="
    echo -e "${NC}"
    
    if systemctl list-unit-files | grep -q "$SERVICE_NAME.service"; then
        echo "Server Name: $(systemctl show valheim-server --property=Environment | grep SERVER_NAME | cut -d'=' -f2 | tr -d '"')"
        echo "Server Password: $(systemctl show valheim-server --property=Environment | grep SERVER_PASSWORD | cut -d'=' -f2 | tr -d '"')"
        echo "World Name: $(systemctl show valheim-server --property=Environment | grep SERVER_WORLD | cut -d'=' -f2 | tr -d '"')"
        echo "Public Server: $(systemctl show valheim-server --property=Environment | grep SERVER_PUBLIC | cut -d'=' -f2 | tr -d '"')"
        echo "Server Port: $(systemctl show valheim-server --property=Environment | grep SERVER_PORT | cut -d'=' -f2 | tr -d '"')"
        echo "Query Port: $(systemctl show valheim-server --property=Environment | grep SERVER_QUERY_PORT | cut -d'=' -f2 | tr -d '"')"
        echo "Valheim Plus: $(systemctl show valheim-server --property=Environment | grep SERVER_PLUS | cut -d'=' -f2 | tr -d '"')"
        echo ""
        echo "Service Status:"
        systemctl status valheim-server --no-pager
    else
        error "Valheim server service not found!"
    fi
}

# Reset to defaults
reset_config() {
    warning "This will reset the server configuration to defaults. Are you sure? (y/n)"
    read -p "> " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        log "Resetting configuration to defaults..."
        
        # Remove override file
        sudo rm -f "/etc/systemd/system/valheim-server.service.d/override.conf"
        
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
    echo "Valheim Server Configuration Script"
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