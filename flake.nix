# Unified dotfiles configuration for both nix-darwin and NixOS
{
  description = "Cross-platform dotfiles configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
    
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";
    
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-darwin, home-manager, nix-darwin, nixos-wsl }:
    let
      # Import shared configurations
      claude-overlay = import ./shared/claude-overlay.nix;
    in
    {
      # macOS configuration
      darwinConfigurations.rictic-macbook = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./nix-darwin/configuration.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = false;
            home-manager.useUserPackages = true;
            home-manager.users.rictic = import ./shared/home-darwin.nix;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.sharedModules = [
              {
                nixpkgs.overlays = [ claude-overlay ];
                nixpkgs.config.allowUnfree = true;
              }
            ];
          }
        ];
      };

      # NixOS WSL configuration
      nixosConfigurations.nixos-wsl = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          nixos-wsl.nixosModules.wsl
          ./nixos-wsl/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = false;
            home-manager.useUserPackages = true;
            home-manager.users.rictic = import ./shared/home-nixos.nix;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.sharedModules = [
              {
                nixpkgs.overlays = [ claude-overlay ];
                nixpkgs.config.allowUnfree = true;
              }
            ];
          }
        ];
      };
    };
}
