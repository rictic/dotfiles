# NixOS WSL Configuration

This directory contains a NixOS configuration adapted from the nix-darwin setup for use with NixOS running in WSL2.

## What's been adapted

- **Base system**: Switched from nix-darwin to NixOS with WSL integration
- **Packages**: Kept all the same development tools and utilities
- **Home Manager**: Preserved your shell configuration, git settings, and development environment
- **WSL Integration**: Added WSL-specific settings and Windows integration features
- **Architecture**: Changed from `aarch64-darwin` to `x86_64-linux`

## Prerequisites

1. Install NixOS-WSL following the [official guide](https://github.com/nix-community/NixOS-WSL)
2. Clone your dotfiles repository in the WSL environment:
   ```bash
   git clone <your-dotfiles-repo> ~/open/dotfiles
   ```

## Installation

1. **Test the flake configuration first (optional but recommended):**
   ```bash
   cd ~/open/dotfiles/nixos-wsl
   sudo nixos-rebuild dry-build --flake .#nixos-wsl --impure
   ```

2. **Link the flake to your system configuration:**
   ```bash
   sudo mkdir -p /etc/nixos
   sudo ln -sf ~/open/dotfiles/nixos-wsl/flake.nix /etc/nixos/flake.nix
   sudo ln -sf ~/open/dotfiles/nixos-wsl/configuration.nix /etc/nixos/configuration.nix
   ```

3. **Apply the configuration:**
   ```bash
   sudo nixos-rebuild switch --flake /etc/nixos#nixos-wsl --impure
   ```

   > **Note:** The `--impure` flag is needed because the configuration references absolute paths. This is normal for NixOS configurations.

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

3. **Make rictic the default WSL user** (run this in Windows PowerShell, not WSL):
   ```powershell
   wsl --set-default-user rictic
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
cd ~/open/dotfiles/nixos-wsl
sudo nixos-rebuild dry-build --flake .#nixos-wsl --impure
```

To check what changes would be made:
```bash
sudo nixos-rebuild dry-activate --flake /etc/nixos#nixos-wsl --impure
```

## Making changes

After modifying any of the configuration files, apply changes with:
```bash
sudo nixos-rebuild switch --flake /etc/nixos#nixos-wsl --impure
```

## Key differences from nix-darwin

- **System packages** are defined in `configuration.nix` instead of the flake directly
- **WSL-specific settings** for Windows integration
- **Docker support** enabled for development
- **Additional Linux tools** like `htop`, `bat`, `eza`, and `fd`
- **VS Code integration** configured for WSL development
- **Claude Code** temporarily disabled due to build issues (can be installed manually with `npm install -g @anthropic-ai/claude-code`)

## File structure

- `flake.nix` - Main flake configuration with inputs and outputs
- `configuration.nix` - System-level NixOS configuration
- `home.nix` - User-level Home Manager configuration (adapted from nix-darwin version)

## Features preserved from nix-darwin

- All development tools (Node.js, Python, Rust, etc.)
- Shell configuration with zsh, starship, and custom aliases
- Git configuration with your user details
- Tmux and direnv integration
- Nix formatting and language server tools
- Custom Claude Code package (temporarily disabled, can install manually)

## WSL-specific features added

- Windows path integration (disabled by default, can be enabled)
- WSL utilities (`wslu`)
- VS Code integration for WSL development
- Docker support for containerized development
- Proper handling of Windows/Linux line endings in git
