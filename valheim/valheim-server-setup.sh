#!/bin/bash

# Valheim Dedicated Server Setup Script
# This script installs and configures a Valheim dedicated server on Ubuntu

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
VALHEIM_USER="valheim"
VALHEIM_HOME="/home/$VALHEIM_USER"
STEAMCMD_DIR="$VALHEIM_HOME/steamcmd"
SERVER_DIR="$VALHEIM_HOME/valheim-server"
SERVICE_NAME="valheim-server"
STEAM_APP_ID="896660"

# Server configuration defaults
SERVER_NAME="Valheim Server"
SERVER_PASSWORD=""
SERVER_WORLD="Dedicated"
SERVER_PUBLIC="false"
SERVER_PORT="2456"
SERVER_QUERY_PORT="2457"
SERVER_PLUS="false"

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

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root. Please run as a regular user with sudo privileges."
        exit 1
    fi
}

# Check if user has sudo privileges
check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        error "This script requires sudo privileges. Please run: sudo visudo and add your user to sudoers."
        exit 1
    fi
}

# Install required packages
install_dependencies() {
    log "Installing required packages..."
    sudo apt update
    sudo apt install -y curl wget lib32gcc-s1 lib32stdc++6 libc6-i386 libsdl2-2.0-0:i386
}

# Create valheim user
create_user() {
    if id "$VALHEIM_USER" &>/dev/null; then
        log "User $VALHEIM_USER already exists"
        # Ensure user is in sudo group
        if ! groups "$VALHEIM_USER" | grep -q sudo; then
            log "Adding $VALHEIM_USER to sudo group..."
            sudo usermod -aG sudo "$VALHEIM_USER" || {
                warning "Failed to add $VALHEIM_USER to sudo group, but continuing..."
            }
        fi
    else
        log "Creating valheim user..."
        if ! sudo useradd -m -s /bin/bash "$VALHEIM_USER"; then
            error "Failed to create user $VALHEIM_USER"
            exit 1
        fi
        if ! sudo usermod -aG sudo "$VALHEIM_USER"; then
            warning "Failed to add $VALHEIM_USER to sudo group, but continuing..."
        fi
    fi
}

# Install SteamCMD
install_steamcmd() {
    log "Installing SteamCMD..."
    sudo -u "$VALHEIM_USER" mkdir -p "$STEAMCMD_DIR"
    cd "$STEAMCMD_DIR"
    
    if [ ! -f "steamcmd.sh" ]; then
        sudo -u "$VALHEIM_USER" wget -qO- "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | sudo -u "$VALHEIM_USER" tar zxf -
    else
        log "SteamCMD already installed"
    fi
}

# Install Valheim server
install_valheim_server() {
    log "Installing Valheim server..."
    sudo -u "$VALHEIM_USER" mkdir -p "$SERVER_DIR"
    
    # Create steamcmd script for Valheim
    sudo -u "$VALHEIM_USER" tee "$STEAMCMD_DIR/install_valheim.txt" > /dev/null << EOF
@ShutdownOnFailedCommand 1
@NoPromptForPassword 1
force_install_dir $SERVER_DIR
login anonymous
app_update $STEAM_APP_ID validate
quit
EOF

    # Run steamcmd to install Valheim
    cd "$STEAMCMD_DIR"
    sudo -u "$VALHEIM_USER" ./steamcmd.sh +runscript install_valheim.txt
    
    # Ensure proper permissions on server directory
    log "Setting proper permissions on server directory..."
    sudo chown -R "$VALHEIM_USER:$VALHEIM_USER" "$SERVER_DIR"
    sudo chmod -R 755 "$SERVER_DIR"
}

# Create server configuration
create_server_config() {
    log "Creating server configuration..."
    
    # Create necessary directories
    sudo -u "$VALHEIM_USER" mkdir -p "$SERVER_DIR/saves"
    sudo -u "$VALHEIM_USER" mkdir -p "$SERVER_DIR/logs"
    
    # Create server startup script
    sudo -u "$VALHEIM_USER" tee "$SERVER_DIR/start-server.sh" > /dev/null << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"

# Set server parameters
SERVER_NAME="${SERVER_NAME:-Valheim Server}"
SERVER_PASSWORD="${SERVER_PASSWORD:-}"
SERVER_WORLD="${SERVER_WORLD:-Dedicated}"
SERVER_PUBLIC="${SERVER_PUBLIC:-false}"
SERVER_PORT="${SERVER_PORT:-2456}"
SERVER_QUERY_PORT="${SERVER_QUERY_PORT:-2457}"
SERVER_PLUS="${SERVER_PLUS:-false}"

# Build command line arguments
ARGS="-name \"$SERVER_NAME\" -port $SERVER_PORT -world $SERVER_WORLD -password \"$SERVER_PASSWORD\" -public $SERVER_PUBLIC"

if [ "$SERVER_PLUS" = "true" ]; then
    ARGS="$ARGS -crossplay"
fi

# Start the server
echo "Starting Valheim server with: $ARGS"
exec ./valheim_server.x86_64 $ARGS
EOF

    sudo chmod +x "$SERVER_DIR/start-server.sh"
    sudo chown -R "$VALHEIM_USER:$VALHEIM_USER" "$SERVER_DIR"
}

# Create systemd service
create_systemd_service() {
    log "Creating systemd service..."
    
    sudo tee "/etc/systemd/system/$SERVICE_NAME.service" > /dev/null << EOF
[Unit]
Description=Valheim Dedicated Server
After=network.target

[Service]
Type=simple
User=$VALHEIM_USER
Group=$VALHEIM_USER
WorkingDirectory=$SERVER_DIR
ExecStart=$SERVER_DIR/start-server.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Environment variables for server configuration
Environment=SERVER_NAME="$SERVER_NAME"
Environment=SERVER_PASSWORD="$SERVER_PASSWORD"
Environment=SERVER_WORLD="$SERVER_WORLD"
Environment=SERVER_PUBLIC="$SERVER_PUBLIC"
Environment=SERVER_PORT="$SERVER_PORT"
Environment=SERVER_QUERY_PORT="$SERVER_QUERY_PORT"
Environment=SERVER_PLUS="$SERVER_PLUS"

# Security settings (relaxed for Valheim)
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=false
ProtectHome=false
ReadWritePaths=$SERVER_DIR
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable "$SERVICE_NAME"
}

# Create management scripts
create_management_scripts() {
    log "Creating management scripts..."
    
    # Create server control script
    sudo tee "/usr/local/bin/valheim-server" > /dev/null << 'EOF'
#!/bin/bash

SERVICE_NAME="valheim-server"

case "$1" in
    start)
        echo "Starting Valheim server..."
        sudo systemctl start "$SERVICE_NAME"
        ;;
    stop)
        echo "Stopping Valheim server..."
        sudo systemctl stop "$SERVICE_NAME"
        ;;
    restart)
        echo "Restarting Valheim server..."
        sudo systemctl restart "$SERVICE_NAME"
        ;;
    status)
        sudo systemctl status "$SERVICE_NAME"
        ;;
    logs)
        sudo journalctl -u "$SERVICE_NAME" -f
        ;;
    enable)
        echo "Enabling Valheim server to start on boot..."
        sudo systemctl enable "$SERVICE_NAME"
        ;;
    disable)
        echo "Disabling Valheim server from starting on boot..."
        sudo systemctl disable "$SERVICE_NAME"
        ;;
    update)
        echo "Updating Valheim server..."
        sudo -u valheim /home/valheim/steamcmd/steamcmd.sh +runscript /home/valheim/steamcmd/install_valheim.txt
        sudo systemctl restart "$SERVICE_NAME"
        ;;
    backup)
        echo "Creating backup..."
        BACKUP_DIR="/home/valheim/backups"
        sudo -u valheim mkdir -p "$BACKUP_DIR"
        BACKUP_FILE="$BACKUP_DIR/valheim-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
        sudo -u valheim tar -czf "$BACKUP_FILE" -C /home/valheim valheim-server/saves
        echo "Backup created: $BACKUP_FILE"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|enable|disable|update|backup}"
        exit 1
        ;;
esac
EOF

    sudo chmod +x "/usr/local/bin/valheim-server"
}

# Configure firewall
configure_firewall() {
    log "Configuring firewall..."
    
    if command -v ufw &> /dev/null; then
        sudo ufw allow $SERVER_PORT/udp
        sudo ufw allow $SERVER_QUERY_PORT/udp
        log "Firewall rules added for ports $SERVER_PORT and $SERVER_QUERY_PORT (UDP)"
    else
        warning "UFW not found. Please manually open ports $SERVER_PORT and $SERVER_QUERY_PORT (UDP) in your firewall."
    fi
}

# Main installation function
main() {
    echo -e "${BLUE}"
    echo "=========================================="
    echo "  Valheim Dedicated Server Setup"
    echo "=========================================="
    echo -e "${NC}"
    
    check_root
    check_sudo
    
    log "Starting Valheim server installation..."
    
    install_dependencies
    create_user
    install_steamcmd
    install_valheim_server
    create_server_config
    create_systemd_service
    create_management_scripts
    configure_firewall
    
    log "Installation completed successfully!"
    echo
    info "Server configuration:"
    info "  Server Name: $SERVER_NAME"
    info "  Server Port: $SERVER_PORT"
    info "  Query Port: $SERVER_QUERY_PORT"
    info "  Server Password: ${SERVER_PASSWORD:-"None"}"
    info "  World Name: $SERVER_WORLD"
    info "  Public Server: $SERVER_PUBLIC"
    echo
    info "Management commands:"
    info "  Start server:   valheim-server start"
    info "  Stop server:    valheim-server stop"
    info "  Restart server: valheim-server restart"
    info "  Check status:   valheim-server status"
    info "  View logs:      valheim-server logs"
    info "  Update server:  valheim-server update"
    info "  Backup save:    valheim-server backup"
    echo
    warning "To configure your server, edit the systemd service file:"
    warning "  sudo systemctl edit --full valheim-server"
    warning "  Then restart the service: valheim-server restart"
    echo
    log "To start the server, run: valheim-server start"
}

# Run main function
main "$@"