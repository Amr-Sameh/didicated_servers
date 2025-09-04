#!/bin/bash

# Palworld Dedicated Server Setup Script
# This script installs and configures a Palworld dedicated server on Ubuntu

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
PALWORLD_USER="palworld"
PALWORLD_HOME="/home/$PALWORLD_USER"
STEAMCMD_DIR="$PALWORLD_HOME/steamcmd"
SERVER_DIR="$PALWORLD_HOME/palworld-server"
SERVICE_NAME="palworld-server"
STEAM_APP_ID="2394010"

# Server configuration defaults
SERVER_NAME="Palworld Server"
SERVER_DESCRIPTION="A Palworld dedicated server"
SERVER_PASSWORD=""
ADMIN_PASSWORD="admin123"
PLAYER_COUNT="32"
PORT="8211"
PUBLIC="false"

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

# Create palworld user
create_user() {
    if ! id "$PALWORLD_USER" &>/dev/null; then
        log "Creating palworld user..."
        sudo useradd -m -s /bin/bash "$PALWORLD_USER"
        sudo usermod -aG sudo "$PALWORLD_USER"
    else
        log "User $PALWORLD_USER already exists"
    fi
}

# Install SteamCMD
install_steamcmd() {
    log "Installing SteamCMD..."
    sudo -u "$PALWORLD_USER" mkdir -p "$STEAMCMD_DIR"
    cd "$STEAMCMD_DIR"
    
    if [ ! -f "steamcmd.sh" ]; then
        sudo -u "$PALWORLD_USER" wget -qO- "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | sudo -u "$PALWORLD_USER" tar zxf -
    else
        log "SteamCMD already installed"
    fi
}

# Install Palworld server
install_palworld_server() {
    log "Installing Palworld server..."
    sudo -u "$PALWORLD_USER" mkdir -p "$SERVER_DIR"
    
    # Create steamcmd script for Palworld
    sudo -u "$PALWORLD_USER" tee "$STEAMCMD_DIR/install_palworld.txt" > /dev/null << EOF
@ShutdownOnFailedCommand 1
@NoPromptForPassword 1
force_install_dir $SERVER_DIR
login anonymous
app_update $STEAM_APP_ID validate
quit
EOF

    # Run steamcmd to install Palworld
    cd "$STEAMCMD_DIR"
    sudo -u "$PALWORLD_USER" ./steamcmd.sh +runscript install_palworld.txt
}

# Create server configuration
create_server_config() {
    log "Creating server configuration..."
    
    # Create PalWorldSettings.ini
    sudo -u "$PALWORLD_USER" tee "$SERVER_DIR/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini" > /dev/null << EOF
[/Script/Pal.PalGameWorldSettings]
OptionSettings=(
    Difficulty=None,
    DayTimeSpeedRate=1.000000,
    NightTimeSpeedRate=1.000000,
    ExpRate=1.000000,
    PalCaptureRate=1.000000,
    PalSpawnNumRate=1.000000,
    PalDamageRateAttack=1.000000,
    PalDamageRateDefense=1.000000,
    PlayerDamageRateAttack=1.000000,
    PlayerDamageRateDefense=1.000000,
    PlayerAutoHpRegeneRate=1.000000,
    PlayerAutoHpRegeneRateInSleep=1.000000,
    PalAutoHpRegeneRate=1.000000,
    PalAutoHpRegeneRateInSleep=1.000000,
    BuildObjectDeteriorationDamageRate=1.000000,
    BuildObjectDeteriorationRate=1.000000,
    BuildObjectHpRate=1.000000,
    BuildObjectDeteriorationRate=1.000000,
    CollectionDropRate=1.000000,
    CollectionObjectHpRate=1.000000,
    CollectionObjectRate=1.000000,
    EnemyDropItemRate=1.000000,
    DeathPenalty=All,
    bEnablePlayerToPlayerDamage=False,
    bEnableFriendlyFire=False,
    bEnableInvaderEnemy=True,
    bActiveUNKO=False,
    bEnableAimAssistPad=True,
    bEnableAimAssistKeyboard=False,
    DropItemMaxNum=3000,
    DropItemMaxNum_UNKO=100,
    BaseCampMaxNum=128,
    BaseCampMaxNumInGuild=1,
    BaseCampWorkerMaxNum=15,
    GuildPlayerMaxNum=20,
    PalEggDefaultHatchingTime=72.000000,
    WorkSpeedRate=1.000000,
    bIsMultiplay=False,
    bIsPvP=False,
    bCanPickupOtherGuildDeathPenaltyDrop=False,
    bEnableNonLoginPenalty=True,
    bEnableFastTravel=True,
    bIsStartLocationSelectByMap=True,
    bExistPlayerAfterLogout=False,
    bEnableDefenseOtherGuildPlayer=False,
    CoopPlayerMaxNum=4,
    ServerPlayerMaxNum=32,
    ServerName="$SERVER_NAME",
    ServerDescription="$SERVER_DESCRIPTION",
    AdminPassword="$ADMIN_PASSWORD",
    ServerPassword="$SERVER_PASSWORD",
    PublicPort=$PORT,
    PublicIP="",
    RCONEnabled=True,
    RCONPort=25575,
    Region="",
    bUseAuth=True,
    BanListURL="https://api.palworldgame.com/api/banlist.txt"
)
EOF

    # Create server startup script
    sudo -u "$PALWORLD_USER" tee "$SERVER_DIR/start-server.sh" > /dev/null << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
./PalServer.sh -useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS
EOF

    sudo chmod +x "$SERVER_DIR/start-server.sh"
    sudo chown -R "$PALWORLD_USER:$PALWORLD_USER" "$SERVER_DIR"
}

# Create systemd service
create_systemd_service() {
    log "Creating systemd service..."
    
    sudo tee "/etc/systemd/system/$SERVICE_NAME.service" > /dev/null << EOF
[Unit]
Description=Palworld Dedicated Server
After=network.target

[Service]
Type=simple
User=$PALWORLD_USER
Group=$PALWORLD_USER
WorkingDirectory=$SERVER_DIR
ExecStart=$SERVER_DIR/start-server.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
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
    sudo tee "/usr/local/bin/palworld-server" > /dev/null << 'EOF'
#!/bin/bash

SERVICE_NAME="palworld-server"

case "$1" in
    start)
        echo "Starting Palworld server..."
        sudo systemctl start "$SERVICE_NAME"
        ;;
    stop)
        echo "Stopping Palworld server..."
        sudo systemctl stop "$SERVICE_NAME"
        ;;
    restart)
        echo "Restarting Palworld server..."
        sudo systemctl restart "$SERVICE_NAME"
        ;;
    status)
        sudo systemctl status "$SERVICE_NAME"
        ;;
    logs)
        sudo journalctl -u "$SERVICE_NAME" -f
        ;;
    enable)
        echo "Enabling Palworld server to start on boot..."
        sudo systemctl enable "$SERVICE_NAME"
        ;;
    disable)
        echo "Disabling Palworld server from starting on boot..."
        sudo systemctl disable "$SERVICE_NAME"
        ;;
    update)
        echo "Updating Palworld server..."
        sudo -u palworld /home/palworld/steamcmd/steamcmd.sh +runscript /home/palworld/steamcmd/install_palworld.txt
        sudo systemctl restart "$SERVICE_NAME"
        ;;
    backup)
        echo "Creating backup..."
        BACKUP_DIR="/home/palworld/backups"
        sudo -u palworld mkdir -p "$BACKUP_DIR"
        BACKUP_FILE="$BACKUP_DIR/palworld-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
        sudo -u palworld tar -czf "$BACKUP_FILE" -C /home/palworld palworld-server/Pal/Saved
        echo "Backup created: $BACKUP_FILE"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|enable|disable|update|backup}"
        exit 1
        ;;
esac
EOF

    sudo chmod +x "/usr/local/bin/palworld-server"
}

# Configure firewall
configure_firewall() {
    log "Configuring firewall..."
    
    if command -v ufw &> /dev/null; then
        sudo ufw allow $PORT/udp
        sudo ufw allow 25575/tcp  # RCON port
        log "Firewall rules added for ports $PORT (UDP) and 25575 (TCP)"
    else
        warning "UFW not found. Please manually open ports $PORT (UDP) and 25575 (TCP) in your firewall."
    fi
}

# Main installation function
main() {
    echo -e "${BLUE}"
    echo "=========================================="
    echo "  Palworld Dedicated Server Setup"
    echo "=========================================="
    echo -e "${NC}"
    
    check_root
    check_sudo
    
    log "Starting Palworld server installation..."
    
    install_dependencies
    create_user
    install_steamcmd
    install_palworld_server
    create_server_config
    create_systemd_service
    create_management_scripts
    configure_firewall
    
    log "Installation completed successfully!"
    echo
    info "Server configuration:"
    info "  Server Name: $SERVER_NAME"
    info "  Server Port: $PORT"
    info "  Admin Password: $ADMIN_PASSWORD"
    info "  Server Password: ${SERVER_PASSWORD:-"None"}"
    info "  Max Players: $PLAYER_COUNT"
    echo
    info "Management commands:"
    info "  Start server:   palworld-server start"
    info "  Stop server:    palworld-server stop"
    info "  Restart server: palworld-server restart"
    info "  Check status:   palworld-server status"
    info "  View logs:      palworld-server logs"
    info "  Update server:  palworld-server update"
    info "  Backup save:    palworld-server backup"
    echo
    warning "Please configure your server settings in:"
    warning "  $SERVER_DIR/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini"
    echo
    log "To start the server, run: palworld-server start"
}

# Run main function
main "$@"