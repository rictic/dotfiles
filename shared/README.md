# Shared Nix Configuration

This directory contains shared configuration modules that are used by both the nix-darwin (macOS) and NixOS (WSL) configurations.

## Structure

- `common-packages.nix` - Home Manager packages shared between both platforms
- `common-system-packages.nix` - System packages shared between both platforms  
- `home-common.nix` - Common Home Manager configuration (shell, git, etc.)
- `home-darwin.nix` - macOS-specific Home Manager configuration that imports the common config
- `home-nixos.nix` - NixOS-specific Home Manager configuration that imports the common config
- `claude-overlay.nix` - Shared overlay for the Claude Code package that works on both platforms

## How it works

1. **Common Configuration**: The `home-common.nix` file contains all the shared Home Manager configuration like shell aliases, git setup, program configurations, etc.

2. **Platform-Specific Overrides**: Each platform has its own home configuration file (`home-darwin.nix` or `home-nixos.nix`) that:
   - Imports the common configuration
   - Adds platform-specific packages 
   - Provides platform-specific overrides and extensions

3. **Shared Overlays**: The `claude-overlay.nix` contains the Claude Code package definition that works on both macOS and Linux, with platform-specific conditionals where needed.

## Benefits

- **DRY Principle**: No duplication of common configuration
- **Consistency**: Ensures both environments have the same core setup
- **Maintainability**: Changes to common tools/configs only need to be made once
- **Platform Flexibility**: Still allows for platform-specific customizations

## Usage

The main flake files in each platform directory import these shared modules:

- nix-darwin uses `../shared/home-darwin.nix`
- NixOS uses `../shared/home-nixos.nix`

Both ultimately inherit from `../shared/home-common.nix` for the base configuration.
