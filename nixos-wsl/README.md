# NixOS WSL Configuration

This directory contains configurations for multiple WSL NixOS machines. Each machine has its own named configuration that inherits from a shared base.

## Available Machines

- **abadar** - Located in `nixos-wsl/abadar/`
- **wizardfoot** - Located in `nixos-wsl/wizardfoot/`

## Quick Start

1. Install NixOS-WSL following the [official guide](https://github.com/nix-community/NixOS-WSL)
2. Inside the new NixOS distro, run:

```bash
git clone https://github.com/rictic/dotfiles
cd dotfiles
# The first time you must specify the machine name to use.
sudo nixos-rebuild switch --flake .#abadar
exit
```

This should drop you back into your windows shell, where you should run:

```powershell
wsl --shutdown
wsl
```

## Making changes

### Machine-specific changes:
- **Abadar**: Edit `nixos-wsl/abadar/configuration.nix`
- **Wizardfoot**: Edit `nixos-wsl/wizardfoot/configuration.nix`

After making changes, apply them with:
```bash
cd ~/open/dotfiles
sudo nixos-rebuild switch --flake .
```

Changes pushed up to github will by automatically applied every ~5 minutes.

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

## Key differences from nix-darwin

- **System packages** are defined in `configuration.nix` instead of the flake directly
- **WSL-specific settings** for Windows integration
- **Additional Linux tools** like `htop`, `bat`, `eza`, and `fd`
- **VS Code integration** configured for WSL development
