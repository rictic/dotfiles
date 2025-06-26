# Cross-Platform Dotfiles

Includes a unified Nix configuration for managing dotfiles and system configurations across macOS (via nix-darwin) and Linux (via NixOS in WSL).

## Quick Start

### macOS (nix-darwin)
```bash
git clone https://github.com/rictic/dotfiles ~/open/dotfiles
cd ~/open/dotfiles
sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin/master#darwin-rebuild -- switch --flake .#rictic-macbook
```

### Linux (NixOS WSL)
```bash
git clone https://github.com/rictic/dotfiles ~/open/dotfiles
cd ~/open/dotfiles
sudo nixos-rebuild switch --flake .#nixos-wsl
```

## More detailed docs in subdirs.

- [macOS Setup](./nix-darwin/README.md) - nix-darwin configuration and setup
- [NixOS WSL Setup](./nixos-wsl/README.md) - NixOS WSL configuration and setup

## Making Changes

1. **Edit configurations** in the appropriate directory
2. **Test changes** with dry-run commands
3. **Apply changes** using the rebuild commands

### Testing Changes
```bash
# Test flake validity
nix flake check

# Test macOS build
darwin-rebuild build --flake .#rictic-macbook

# Test NixOS build  
sudo nixos-rebuild dry-build --flake .#nixos-wsl
```

### Applying Changes
```bash
# macOS
sudo darwin-rebuild switch --flake .#rictic-macbook

# NixOS
sudo nixos-rebuild switch --flake .#nixos-wsl
```

## Auto-Update (NixOS only)

The NixOS configuration includes an automatic update system that:
- Checks for repository updates every 5 minutes
- Tests changes before applying them
- Creates backup points for easy rollback
- Logs all activity to systemd journal

Manage with: `dotfiles-auto-update-ctl {enable|disable|status|logs}`

See [NixOS WSL Setup](./nixos-wsl/README.md) for detailed documentation.
