# The Forest Dedicated Server Setup

This repository contains scripts to easily set up and manage a The Forest dedicated server on Ubuntu.

## Files

- `forest-server-setup.sh` - Main installation script
- `forest-configure.sh` - Server configuration management script
- `forest-server.conf` - Default server configuration template
- `forest-server.conf.example` - Example configuration with custom values
- `README.md` - This documentation

## Quick Start

### Option 1: Use Default Configuration
1. **Download the scripts:**
   ```bash
   wget https://raw.githubusercontent.com/your-repo/forest-server-setup.sh
   wget https://raw.githubusercontent.com/your-repo/forest-configure.sh
   chmod +x forest-server-setup.sh forest-configure.sh
   ```

2. **Run the setup script:**
   ```bash
   ./forest-server-setup.sh
   ```

3. **Start the server:**
   ```bash
   forest-server start
   ```

### Option 2: Custom Configuration (Recommended)
1. **Download the scripts:**
   ```bash
   wget https://raw.githubusercontent.com/your-repo/forest-server-setup.sh
   wget https://raw.githubusercontent.com/your-repo/forest-configure.sh
   chmod +x forest-server-setup.sh forest-configure.sh
   ```

2. **Configure your server:**
   ```bash
   # Copy the example configuration
   cp forest-server.conf.example forest-server.conf
   
   # Edit with your preferred settings
   nano forest-server.conf
   ```

3. **Run the setup script:**
   ```bash
   ./forest-server-setup.sh
   ```

4. **Start the server:**
   ```bash
   forest-server start
   ```

## Features

### Main Setup Script (`forest-server-setup.sh`)

- Installs all required dependencies (including Xvfb for headless operation)
- Downloads and installs SteamCMD
- Installs The Forest dedicated server
- Creates a dedicated `forest` user
- Sets up systemd service for automatic management
- Configures firewall rules
- Creates management scripts

### Configuration Script (`forest-configure.sh`)

- Interactive server configuration
- View current settings
- Reset to defaults
- Easy server management

## Server Management

After installation, you can use the `forest-server` command to manage your server:

```bash
# Start the server
forest-server start

# Stop the server
forest-server stop

# Restart the server
forest-server restart

# Check server status
forest-server status

# View server logs
forest-server logs

# Enable auto-start on boot
forest-server enable

# Disable auto-start on boot
forest-server disable

# Update the server
forest-server update

# Create a backup
forest-server backup
```

## Configuration

### Pre-Setup Configuration (Recommended)

Edit the configuration file before running the setup script:

```bash
# Copy the example configuration
cp forest-server.conf.example forest-server.conf

# Edit with your preferred settings
nano forest-server.conf
```

**Key settings you can configure:**
- Server name and password
- Max players and port settings
- Game mode and difficulty
- Save settings and intervals
- Tree regrowth options
- Performance settings
- Server information and tags

### Post-Setup Configuration

Use the configuration script to modify server settings after installation:

```bash
# Interactive configuration
./forest-configure.sh configure

# Show current configuration
./forest-configure.sh show

# Reset to defaults
./forest-configure.sh reset
```

### Server Settings

The server configuration includes:

**Basic Settings:**
- **Server Name** - Display name for your server
- **Server Password** - Password to join the server (optional)
- **Max Players** - Maximum number of players (1-8)
- **Server Port** - Game port (default: 27015)
- **VAC** - Valve Anti-Cheat enable/disable

**Game Settings:**
- **Game Mode** - Standard, Creative, Peaceful, or Hard
- **Difficulty** - Peaceful, Normal, or Hard
- **Save Slot** - Which save slot to use (1-5)
- **Save Interval** - Auto-save frequency in seconds
- **Tree Regrowth** - Enable/disable and set percentage

**Performance:**
- **Target FPS** - Separate settings for idle and active states
- **Auto-save on Sleep** - Save when players sleep

## Default Configuration

- **Server Name:** "The Forest Server"
- **Server Port:** 27015 (UDP)
- **Max Players:** 8
- **Server Password:** None (public server)
- **Game Mode:** Standard
- **Difficulty:** Normal
- **Tree Regrowth:** Enabled (10%)
- **VAC:** Enabled

## Firewall

The setup script automatically configures UFW firewall to allow:
- Port 27015 (UDP) - Game traffic
- Port 27016 (UDP) - Game port + 1
- Port 27017 (UDP) - Query port

## Backups

The server automatically creates backups of save data. Backups are stored in:
`/home/forest/backups/`

You can create manual backups with:
```bash
forest-server backup
```

## Troubleshooting

### Check server status
```bash
forest-server status
```

### View server logs
```bash
forest-server logs
```

### Check if ports are open
```bash
sudo ufw status
```

### Restart the service
```bash
sudo systemctl restart forest-server
```

### Check service logs
```bash
sudo journalctl -u forest-server -f
```

### Manual configuration
```bash
# Edit server configuration
sudo systemctl edit --full forest-server

# Reload configuration
sudo systemctl daemon-reload
sudo systemctl restart forest-server
```

## Server Files Location

- **Server Directory:** `/home/forest/forest-server/`
- **Configuration:** `/home/forest/forest-server/config/`
- **Save Files:** `/home/forest/forest-server/saves/`
- **Logs:** `/home/forest/forest-server/logs/`

## Requirements

- Ubuntu 18.04 or later
- At least 4GB RAM (8GB+ recommended)
- 10GB+ free disk space
- Sudo privileges
- Internet connection

## Important Notes

### Headless Operation
The Forest server requires a display to run, even in dedicated mode. The setup script automatically configures Xvfb (virtual framebuffer) to provide a virtual display for headless operation.

### Game Modes
- **Standard** - Normal survival gameplay
- **Creative** - Unlimited resources, no enemies
- **Peaceful** - Survival without enemies
- **Hard** - Increased difficulty and enemy aggression

### Tree Regrowth
Tree regrowth can be configured with different percentages:
- 0 = Off (no regrowth)
- 1 = 10% regrowth
- 2 = 25% regrowth
- 3 = 50% regrowth
- 4 = 100% regrowth

## Security Notes

- Set a strong server password for private servers
- Consider the game mode based on your player preferences
- Regularly update the server
- Monitor server logs for any issues
- Keep your system updated

## Common Issues

### Server won't start
- Check if ports are open: `sudo ufw status`
- Check service logs: `forest-server logs`
- Verify Xvfb is installed: `which Xvfb`
- Check user permissions: `sudo chown -R forest:forest /home/forest/forest-server`

### Can't connect from client
- Ensure ports 27015-27017 are open in firewall
- Check if server is running: `forest-server status`
- Verify server password if set

### Performance issues
- Adjust target FPS settings in configuration
- Reduce max players if needed
- Monitor system resources with `htop`

## Support

For issues or questions:
1. Check the server logs: `forest-server logs`
2. Verify configuration: `./forest-configure.sh show`
3. Check system resources: `htop` or `free -h`
4. Ensure ports are open: `sudo ufw status`

## License

This project is provided as-is for educational and personal use.