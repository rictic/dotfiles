# Dotfiles Auto-Update Module

This module provides automatic synchronization and deployment of dotfiles configurations using NixOS.

## Files

- `dotfiles-auto-update.nix` - Main NixOS module with configurable options
- `dotfiles-auto-update.sh` - Core update script that handles git operations and system rebuilds
- `dotfiles-auto-update-ctl.sh` - Control script for managing the auto-update service
- `hello-server.py` - Optional demo HTTP server

## Usage

Import the module in your NixOS configuration:

```nix
{
  imports = [
    ../shared/dotfiles-auto-update.nix
  ];

  services.dotfiles-auto-update = {
    enable = true;
    # Optional: customize settings
    interval = "10min";
    remote = "https://github.com/username/dotfiles.git";
    branch = "main";
    enableHelloServer = true;
  };
}
```

## Available Options

- `enable` - Enable/disable the auto-update service
- `dotfilesPath` - Path for root-owned repository (default: `/etc/dotfiles`)
- `sourcePath` - User's dotfiles directory for reference
- `remote` - Git repository URL
- `branch` - Git branch to track
- `interval` - Update check frequency (default: `5min`)
- `onBootDelay` - Delay before first run after boot
- `enableHelloServer` - Enable demo HTTP server
- `flakeConfig` - Flake configuration name (auto-detected if not set)

## Control Commands

Once installed, use `dotfiles-auto-update-ctl` to manage the service:

```bash
# Enable auto-updates
dotfiles-auto-update-ctl enable

# Check status
dotfiles-auto-update-ctl status

# View logs
dotfiles-auto-update-ctl logs

# Trigger immediate update
dotfiles-auto-update-ctl run-now

# Disable auto-updates
dotfiles-auto-update-ctl disable
```

## How It Works

1. The service maintains a root-owned copy of your dotfiles at `/etc/dotfiles`
2. Every 5 minutes (configurable), it checks for updates from the remote repository
3. If changes are found, it tests the build with `nixos-rebuild dry-build`
4. If the test passes, it applies the changes with `nixos-rebuild switch`
5. All operations are logged and can be monitored via systemd

This approach ensures that:
- Updates are applied automatically but safely
- The system remains stable (failed builds don't break anything)
- You can monitor and control the update process
- The update mechanism is isolated from your user directory
