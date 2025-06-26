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

## Key differences from nix-darwin

- **System packages** are defined in `configuration.nix` instead of the flake directly
- **WSL-specific settings** for Windows integration
- **Additional Linux tools** like `htop`, `bat`, `eza`, and `fd`
- **VS Code integration** configured for WSL development
