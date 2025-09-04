#!/bin/bash

# Diagnostic script for Palworld server issues

PALWORLD_USER="palworld"
SERVER_DIR="/home/palworld/palworld-server"
SERVICE_NAME="palworld-server"

echo "=== Palworld Server Diagnostic ==="
echo ""

echo "1. Checking if palworld user exists:"
if id "$PALWORLD_USER" &>/dev/null; then
    echo "✓ User $PALWORLD_USER exists"
    echo "  UID: $(id -u $PALWORLD_USER)"
    echo "  Groups: $(groups $PALWORLD_USER)"
else
    echo "✗ User $PALWORLD_USER does not exist"
fi
echo ""

echo "2. Checking server directory:"
if [ -d "$SERVER_DIR" ]; then
    echo "✓ Directory $SERVER_DIR exists"
    echo "  Owner: $(ls -ld $SERVER_DIR | awk '{print $3":"$4}')"
    echo "  Permissions: $(ls -ld $SERVER_DIR | awk '{print $1}')"
else
    echo "✗ Directory $SERVER_DIR does not exist"
fi
echo ""

echo "3. Checking startup script:"
if [ -f "$SERVER_DIR/start-server.sh" ]; then
    echo "✓ Startup script exists"
    echo "  Owner: $(ls -l $SERVER_DIR/start-server.sh | awk '{print $3":"$4}')"
    echo "  Permissions: $(ls -l $SERVER_DIR/start-server.sh | awk '{print $1}')"
    echo "  Executable: $([ -x $SERVER_DIR/start-server.sh ] && echo "Yes" || echo "No")"
else
    echo "✗ Startup script does not exist"
fi
echo ""

echo "4. Checking PalServer.sh:"
if [ -f "$SERVER_DIR/PalServer.sh" ]; then
    echo "✓ PalServer.sh exists"
    echo "  Owner: $(ls -l $SERVER_DIR/PalServer.sh | awk '{print $3":"$4}')"
    echo "  Permissions: $(ls -l $SERVER_DIR/PalServer.sh | awk '{print $1}')"
    echo "  Executable: $([ -x $SERVER_DIR/PalServer.sh ] && echo "Yes" || echo "No")"
else
    echo "✗ PalServer.sh does not exist"
fi
echo ""

echo "5. Checking systemd service:"
if [ -f "/etc/systemd/system/$SERVICE_NAME.service" ]; then
    echo "✓ Service file exists"
    echo "  Content:"
    cat "/etc/systemd/system/$SERVICE_NAME.service"
else
    echo "✗ Service file does not exist"
fi
echo ""

echo "6. Checking service status:"
sudo systemctl status "$SERVICE_NAME" --no-pager
echo ""

echo "7. Recent service logs:"
sudo journalctl -u "$SERVICE_NAME" --no-pager -n 20
echo ""

echo "=== Diagnostic Complete ==="