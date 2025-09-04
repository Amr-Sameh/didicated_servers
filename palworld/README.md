# Palworld Dedicated Server Setup

This repository contains scripts to easily set up and manage a Palworld dedicated server on Ubuntu.

## Files

- `palworld-server-setup.sh` - Main installation script
- `palworld-configure.sh` - Server configuration management script
- `README.md` - This documentation

## Quick Start

1. **Download the scripts:**
   ```bash
   wget https://raw.githubusercontent.com/your-repo/palworld-server-setup.sh
   wget https://raw.githubusercontent.com/your-repo/palworld-configure.sh
   chmod +x palworld-server-setup.sh palworld-configure.sh
   ```

2. **Run the setup script:**
   ```bash
   ./palworld-server-setup.sh
   ```

3. **Start the server:**
   ```bash
   palworld-server start
   ```

## Features

### Main Setup Script (`palworld-server-setup.sh`)

- Installs all required dependencies
- Downloads and installs SteamCMD
- Installs Palworld dedicated server
- Creates a dedicated `palworld` user
- Sets up systemd service for automatic management
- Configures firewall rules
- Creates management scripts

### Configuration Script (`palworld-configure.sh`)

- Interactive server configuration
- View current settings
- Reset to defaults
- Easy server management

## Server Management

After installation, you can use the `palworld-server` command to manage your server:

```bash
# Start the server
palworld-server start

# Stop the server
palworld-server stop

# Restart the server
palworld-server restart

# Check server status
palworld-server status

# View server logs
palworld-server logs

# Enable auto-start on boot
palworld-server enable

# Disable auto-start on boot
palworld-server disable

# Update the server
palworld-server update

# Create a backup
palworld-server backup
```

## Configuration

Use the configuration script to modify server settings:

```bash
# Interactive configuration
./palworld-configure.sh configure

# Show current configuration
./palworld-configure.sh show

# Reset to defaults
./palworld-configure.sh reset
```

### Server Settings

The server configuration is stored in:
`/home/palworld/palworld-server/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini`

Key settings include:
- Server Name
- Server Description
- Admin Password
- Server Password (optional)
- Port (default: 8211)
- Max Players (default: 32)
- PvP settings
- Difficulty settings
- Experience rates
- And much more...

## Default Configuration

- **Server Name:** "Palworld Server"
- **Port:** 8211 (UDP)
- **RCON Port:** 25575 (TCP)
- **Max Players:** 32
- **Admin Password:** "admin123"
- **Server Password:** None (public server)
- **PvP:** Disabled
- **Difficulty:** Normal

## Firewall

The setup script automatically configures UFW firewall to allow:
- Port 8211 (UDP) - Game traffic
- Port 25575 (TCP) - RCON access

## Backups

The server automatically creates backups of save data. Backups are stored in:
`/home/palworld/backups/`

You can create manual backups with:
```bash
palworld-server backup
```

## Troubleshooting

### Check server status
```bash
palworld-server status
```

### View server logs
```bash
palworld-server logs
```

### Check if ports are open
```bash
sudo ufw status
```

### Restart the service
```bash
sudo systemctl restart palworld-server
```

### Check service logs
```bash
sudo journalctl -u palworld-server -f
```

## Server Files Location

- **Server Directory:** `/home/palworld/palworld-server/`
- **Configuration:** `/home/palworld/palworld-server/Pal/Saved/Config/LinuxServer/`
- **Save Data:** `/home/palworld/palworld-server/Pal/Saved/SaveGames/`
- **Logs:** `/home/palworld/palworld-server/Pal/Saved/Logs/`

## Requirements

- Ubuntu 18.04 or later
- At least 4GB RAM (8GB+ recommended)
- 20GB+ free disk space
- Sudo privileges
- Internet connection

## Security Notes

- Change the default admin password immediately
- Consider setting a server password for private servers
- Regularly update the server
- Monitor server logs for any issues
- Keep your system updated

## Support

For issues or questions:
1. Check the server logs: `palworld-server logs`
2. Verify configuration: `./palworld-configure.sh show`
3. Check system resources: `htop` or `free -h`
4. Ensure ports are open: `sudo ufw status`

## License

This project is provided as-is for educational and personal use.