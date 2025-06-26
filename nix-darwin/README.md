# nix-darwin Configuration

## Prerequisites

1. Install Nix following the [official guide](https://nixos.org/download.html)
2. Clone your dotfiles repository:
   ```bash
   git clone https://github.com/rictic/dotfiles ~/open/dotfiles
   ```

## Installation

1. **Test the flake configuration first (optional but recommended):**
   ```bash
   cd ~/open/dotfiles
   nix flake check
   ```

2. **Install nix-darwin using the unified flake:**
   ```bash
   cd ~/open/dotfiles
   sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin/master#darwin-rebuild -- switch --flake .#rictic-macbook
   ```

   > **Note:** This uses the unified flake at the root of the dotfiles repository, which manages both nix-darwin and NixOS configurations.

3. **For subsequent updates, simply run:**
   ```bash
   sudo darwin-rebuild switch --flake ~/open/dotfiles#rictic-macbook
   ```

## Testing the configuration

To test your configuration without applying it:
```bash
cd ~/open/dotfiles
darwin-rebuild build --flake .#rictic-macbook
```

To check what changes would be made:
```bash
cd ~/open/dotfiles
darwin-rebuild dry-activate --flake .#rictic-macbook
```

## Making changes

After modifying any of the configuration files, apply changes with:
```bash
cd ~/open/dotfiles
sudo darwin-rebuild switch --flake .#rictic-macbook
```

## Configuration Structure

- **System packages** are defined in `nix-darwin/configuration.nix`
- **User packages and dotfiles** are managed via Home Manager in `shared/home-darwin.nix`
- **Shared configurations** between macOS and Linux are in the `shared/` directory
- **Overlays** for custom packages are defined in `shared/claude-overlay.nix`

## Key differences from NixOS

- Uses **darwin-rebuild** instead of nixos-rebuild
- **System services** are managed differently via launchd
- **Package availability** may differ between Darwin and Linux nixpkgs
- **File system structure** follows macOS conventions
