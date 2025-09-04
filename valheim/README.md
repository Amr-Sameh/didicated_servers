# Valheim Dedicated Server Setup

This repository contains scripts to easily set up and manage a Valheim dedicated server on Ubuntu.

## Files

- `valheim-server-setup.sh` - Main installation script
- `valheim-configure.sh` - Server configuration management script
- `README.md` - This documentation

## Quick Start

1. **Download the scripts:**
   ```bash
   wget https://raw.githubusercontent.com/your-repo/valheim-server-setup.sh
   wget https://raw.githubusercontent.com/your-repo/valheim-configure.sh
   chmod +x valheim-server-setup.sh valheim-configure.sh
   ```

2. **Run the setup script:**
   ```bash
   ./valheim-server-setup.sh
   ```

3. **Start the server:**
   ```bash
   valheim-server start
   ```

## Features

### Main Setup Script (`valheim-server-setup.sh`)

- Installs all required dependencies
- Downloads and installs SteamCMD
- Installs Valheim dedicated server
- Creates a dedicated `valheim` user
- Sets up systemd service for automatic management
- Configures firewall rules
- Creates management scripts

### Configuration Script (`valheim-configure.sh`)

- Interactive server configuration
- View current settings
- Reset to defaults
- Easy server management

## Server Management

After installation, you can use the `valheim-server` command to manage your server:

```bash
# Start the server
valheim-server start

# Stop the server
valheim-server stop

# Restart the server
valheim-server restart

# Check server status
valheim-server status

# View server logs
valheim-server logs

# Enable auto-start on boot
valheim-server enable

# Disable auto-start on boot
valheim-server disable

# Update the server
valheim-server update

# Create a backup
valheim-server backup
```

## Configuration

Use the configuration script to modify server settings:

```bash
# Interactive configuration
./valheim-configure.sh configure

# Show current configuration
./valheim-configure.sh show

# Reset to defaults
./valheim-configure.sh reset
```

### Server Settings

The server configuration is managed through systemd environment variables:

- **Server Name** - Display name for your server
- **Server Password** - Password to join the server (optional)
- **World Name** - Name of the world/save file
- **Public Server** - Whether to list on public server browser
- **Server Port** - Game port (default: 2456)
- **Query Port** - Server query port (default: 2457)
- **Valheim Plus** - Enable Valheim Plus mod support

## Default Configuration

- **Server Name:** "Valheim Server"
- **Server Port:** 2456 (UDP)
- **Query Port:** 2457 (UDP)
- **Server Password:** None (public server)
- **World Name:** "Dedicated"
- **Public Server:** false
- **Valheim Plus:** false

## Firewall

The setup script automatically configures UFW firewall to allow:
- Port 2456 (UDP) - Game traffic
- Port 2457 (UDP) - Server queries

## Backups

The server automatically creates backups of save data. Backups are stored in:
`/home/valheim/backups/`

You can create manual backups with:
```bash
valheim-server backup
```

## Troubleshooting

### Check server status
```bash
valheim-server status
```

### View server logs
```bash
valheim-server logs
```

### Check if ports are open
```bash
sudo ufw status
```

### Restart the service
```bash
sudo systemctl restart valheim-server
```

### Check service logs
```bash
sudo journalctl -u valheim-server -f
```

### Manual configuration
```bash
# Edit server configuration
sudo systemctl edit --full valheim-server

# Reload configuration
sudo systemctl daemon-reload
sudo systemctl restart valheim-server
```

## Server Files Location

- **Server Directory:** `/home/valheim/valheim-server/`
- **Save Files:** `/home/valheim/valheim-server/saves/`
- **Logs:** `/home/valheim/valheim-server/logs/`

## Requirements

- Ubuntu 18.04 or later
- At least 2GB RAM (4GB+ recommended)
- 5GB+ free disk space
- Sudo privileges
- Internet connection

## Valheim Plus Support

To enable Valheim Plus mod support:

1. Install Valheim Plus on your server
2. Configure the server with Valheim Plus enabled:
   ```bash
   ./valheim-configure.sh configure
   # Set "Enable Valheim Plus" to true
   ```

## Security Notes

- Set a strong server password for private servers
- Consider making the server private if you don't want random players
- Regularly update the server
- Monitor server logs for any issues
- Keep your system updated

## Common Issues

### Server won't start
- Check if ports are open: `sudo ufw status`
- Check service logs: `valheim-server logs`
- Verify user permissions: `sudo chown -R valheim:valheim /home/valheim/valheim-server`

### Can't connect from client
- Ensure ports 2456 and 2457 are open in firewall
- Check if server is public and has correct password
- Verify server is running: `valheim-server status`

### World not saving
- Check save directory permissions
- Ensure valheim user owns the save directory
- Check available disk space

## Support

For issues or questions:
1. Check the server logs: `valheim-server logs`
2. Verify configuration: `./valheim-configure.sh show`
3. Check system resources: `htop` or `free -h`
4. Ensure ports are open: `sudo ufw status`

## License

This project is provided as-is for educational and personal use.