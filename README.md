# Cross-Platform Dotfiles

A Nix configuration for managing my systems.

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
# Replace 'abadar' with your machine name (e.g. abadar, wizardfoot)
sudo nixos-rebuild switch --flake .#abadar
# Then restart WSL.
```

## More detailed docs in subdirs.

- [macOS Setup](./nix-darwin/README.md) - nix-darwin configuration and setup
- [NixOS WSL Setup](./nixos-wsl/README.md) - NixOS WSL configuration and setup

