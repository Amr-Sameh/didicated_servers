#!/bin/bash

# Quick fix for Palworld server permissions
# Run this script to fix the permission issues

set -e

PALWORLD_USER="palworld"
SERVER_DIR="/home/palworld/palworld-server"

echo "Fixing Palworld server permissions..."

# Stop the service first
sudo systemctl stop palworld-server

# Fix ownership and permissions
sudo chown -R "$PALWORLD_USER:$PALWORLD_USER" "$SERVER_DIR"
sudo chmod -R 755 "$SERVER_DIR"

# Make sure the startup script is executable
sudo chmod +x "$SERVER_DIR/start-server.sh"

# Reload systemd and restart service
sudo systemctl daemon-reload
sudo systemctl start palworld-server

echo "Permissions fixed! Checking service status..."
sudo systemctl status palworld-server --no-pager

echo "Service should now be running. Check logs with: sudo journalctl -u palworld-server -f"