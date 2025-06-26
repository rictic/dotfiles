# NixOS configuration for WSL
# To use this, follow these steps:
# 1. Install NixOS-WSL following the official guide
# 2. Clone your dotfiles repo in the WSL environment
# 3. Link this flake to your system configuration:
#    sudo ln -s ~/open/dotfiles/nixos-wsl/flake.nix /etc/nixos/flake.nix
# 4. Apply the configuration:
#    sudo nixos-rebuild switch --flake /etc/nixos#nixos-wsl
#
# For subsequent updates, just run:
#    sudo nixos-rebuild switch --flake /etc/nixos#nixos-wsl
{
  description = "NixOS configuration for WSL";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      nixos-wsl,
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      
      # Reuse the claude overlay from shared
      claude-overlay = import ../shared/claude-overlay.nix;
    in
    {
      nixosConfigurations.nixos-wsl = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          # WSL-specific module
          nixos-wsl.nixosModules.wsl
          
          # Apply the claude overlay
          { nixpkgs.overlays = [ claude-overlay ]; }
          
          # Main system configuration
          ./configuration.nix
          
          # Home Manager integration
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.rictic = import ../shared/home-nixos.nix;
            home-manager.extraSpecialArgs = { inherit inputs; };
          }
        ];
      };
    };
}
