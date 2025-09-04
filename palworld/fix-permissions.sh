#!/bin/bash

# Comprehensive fix for Palworld server permissions and systemd service
# Run this script to completely fix the permission and service issues

set -e

PALWORLD_USER="palworld"
SERVER_DIR="/home/palworld/palworld-server"
SERVICE_NAME="palworld-server"

echo "=== Palworld Server Permission Fix ==="

# Stop the service first
echo "Stopping palworld-server service..."
sudo systemctl stop palworld-server 2>/dev/null || true

# Ensure palworld user exists and has proper permissions
echo "Ensuring palworld user exists..."
if id "$PALWORLD_USER" &>/dev/null; then
    echo "User $PALWORLD_USER already exists"
    # Ensure user is in sudo group
    if ! groups "$PALWORLD_USER" | grep -q sudo; then
        echo "Adding $PALWORLD_USER to sudo group..."
        sudo usermod -aG sudo "$PALWORLD_USER"
    fi
else
    echo "Creating palworld user..."
    sudo useradd -m -s /bin/bash "$PALWORLD_USER"
    sudo usermod -aG sudo "$PALWORLD_USER"
fi

# Create server directory if it doesn't exist
echo "Creating server directory..."
sudo mkdir -p "$SERVER_DIR"

# Fix ownership and permissions recursively
echo "Setting proper ownership and permissions..."
sudo chown -R "$PALWORLD_USER:$PALWORLD_USER" "$SERVER_DIR"
sudo chmod -R 755 "$SERVER_DIR"

# Make sure the startup script is executable
if [ -f "$SERVER_DIR/start-server.sh" ]; then
    sudo chmod +x "$SERVER_DIR/start-server.sh"
    echo "Startup script permissions fixed"
fi

# Update systemd service with correct configuration
echo "Updating systemd service configuration..."
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

# Security settings (relaxed for Palworld)
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

# Reload systemd and enable service
echo "Reloading systemd and enabling service..."
sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME"

# Start the service
echo "Starting palworld-server service..."
sudo systemctl start "$SERVICE_NAME"

# Wait a moment and check status
sleep 3
echo ""
echo "=== Service Status ==="
sudo systemctl status "$SERVICE_NAME" --no-pager

echo ""
echo "=== Recent Logs ==="
sudo journalctl -u "$SERVICE_NAME" --no-pager -n 10

echo ""
echo "=== Fix Complete ==="
echo "If the service is still failing, check the logs with:"
echo "sudo journalctl -u palworld-server -f"
echo ""
echo "To check if the server is running:"
echo "sudo systemctl status palworld-server"