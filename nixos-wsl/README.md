# NixOS WSL Configuration

## Prerequisites

1. Install NixOS-WSL following the [official guide](https://github.com/nix-community/NixOS-WSL)
2. Clone inside the WSL environment:
   ```bash
   git clone https://github.com/rictic/dotfiles ~/open/dotfiles
   ```

## Installation

1. **Test the flake configuration first (optional but recommended):**
   ```bash
   cd ~/open/dotfiles
   sudo nixos-rebuild dry-build --flake .#nixos-wsl
   ```

2. **Apply the configuration directly from your dotfiles:**
   ```bash
   cd ~/open/dotfiles
   sudo nixos-rebuild switch --flake .#nixos-wsl
   ```

3. **Set up your user shell:**
   ```bash
   chsh -s $(which zsh)
   ```

## Post-installation setup

After the initial configuration, you may need to switch to the `rictic` user:

1. **Switch to the rictic user:**
   ```bash
   su - rictic
   ```

2. **Set a password for the rictic user:**
   ```bash
   sudo passwd rictic
   ```

3. **Make rictic the default WSL user**:

Edit /etc/wsl.conf to ensure that it has rictic as the default user.

   ```
   [user]
   default=rictic
   ```

4. **Restart WSL to apply the default user change:**
   ```powershell
   wsl --shutdown
   wsl
   ```

5. **Once logged in as rictic, set up zsh as your shell:**
   ```bash
   chsh -s $(which zsh)
   ```

## Testing the configuration

To test your configuration without applying it:
```bash
cd ~/open/dotfiles
sudo nixos-rebuild dry-build --flake .#nixos-wsl
```

To check what changes would be made:
```bash
cd ~/open/dotfiles
sudo nixos-rebuild dry-activate --flake .#nixos-wsl
```

## Making changes

After modifying any of the configuration files, apply changes with:
```bash
cd ~/open/dotfiles
sudo nixos-rebuild switch --flake .#nixos-wsl
```

## Auto-Update System

This configuration includes an automatic update system that checks for changes to your dotfiles repository every 5 minutes and applies them automatically if all tests pass.

### How it works

1. **Checks for updates** every 5 minutes by fetching from the remote repository
2. **Safety checks** - skips update if you have local uncommitted changes
3. **Testing** - validates the flake and does a dry-build before applying
4. **Rollback protection** - creates backup tags and can rollback on failure
5. **Logging** - all actions are logged to systemd journal

### Managing auto-updates

Use the `dotfiles-auto-update-ctl` command to manage the auto-update system:

```bash
# Check current status
dotfiles-auto-update-ctl status

# Enable auto-updates (enabled by default)
dotfiles-auto-update-ctl enable

# Disable auto-updates
dotfiles-auto-update-ctl disable

# Trigger an immediate update check
dotfiles-auto-update-ctl run-now

# View recent logs (follow mode)
dotfiles-auto-update-ctl logs

# View specific number of log lines
dotfiles-auto-update-ctl logs 100
```

### Configuration

The auto-update behavior can be configured by editing `/etc/dotfiles-auto-update.conf`:

```bash
sudo nano /etc/dotfiles-auto-update.conf
```

Options:
- `DOTFILES_AUTO_UPDATE_ENABLED` - Set to `false` to disable
- `DOTFILES_PATH` - Path to your dotfiles repository
- `DOTFILES_BRANCH` - Git branch to track (default: main)
- `LOG_LEVEL` - Logging verbosity

### Safety features

- **Local changes detection** - Won't update if you have uncommitted changes
- **Test before apply** - Validates flake and tests build before switching
- **Backup tags** - Creates git tags before each update for easy rollback
- **Rollback on failure** - Automatically rolls back if tests fail
- **Network timeout** - Won't hang on network issues

### Troubleshooting

If something goes wrong:

1. **Check the logs:**
   ```bash
   dotfiles-auto-update-ctl logs
   ```

2. **Check service status:**
   ```bash
   dotfiles-auto-update-ctl status
   ```

3. **Temporarily disable:**
   ```bash
   dotfiles-auto-update-ctl disable
   ```

4. **Manual rollback if needed:**
   ```bash
   cd ~/open/dotfiles
   git tag -l "backup-before-auto-update-*"  # List backup tags
   git reset --hard backup-before-auto-update-XXXXXXX  # Replace with actual tag
   sudo nixos-rebuild switch --flake .#nixos-wsl
   ```

## Key differences from nix-darwin

- **System packages** are defined in `configuration.nix` instead of the flake directly
- **WSL-specific settings** for Windows integration
- **Additional Linux tools** like `htop`, `bat`, `eza`, and `fd`
- **VS Code integration** configured for WSL development
