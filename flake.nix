# Unified dotfiles configuration for both nix-darwin and NixOS
{
  description = "Cross-platform dotfiles configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";

    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-24.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";

    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixpkgs-darwin,
      home-manager,
      nix-darwin,
      nixos-wsl,
    }:
    let
      # Import shared configurations
      claude-overlay = import ./shared/claude-overlay.nix;

      # Import VM tests
      vmTests = import ./tests/vm-tests.nix {
        inherit
          nixpkgs
          nixos-wsl
          home-manager
          nix-darwin
          inputs
          ;
      };
    in
    {
      # macOS configuration
      darwinConfigurations.reepicheep = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit inputs; };
        modules = [
          ./nix-darwin/configuration.nix
          { nixpkgs.overlays = [ claude-overlay ]; }
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

      # NixOS WSL configurations
      nixosConfigurations.abadar = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          nixos-wsl.nixosModules.wsl
          ./nixos-wsl/abadar/configuration.nix
          home-manager.nixosModules.home-manager
          {
            # Allow unfree packages at the system level
            nixpkgs.config.allowUnfree = true;
            nixpkgs.overlays = [ claude-overlay ];

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

      nixosConfigurations.wizardfoot = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          nixos-wsl.nixosModules.wsl
          ./nixos-wsl/wizardfoot/configuration.nix
          home-manager.nixosModules.home-manager
          {
            # Allow unfree packages at the system level
            nixpkgs.config.allowUnfree = true;
            nixpkgs.overlays = [ claude-overlay ];

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

      # VM Tests output for manual access
      inherit vmTests;

      # Test checks for nix flake check
      checks.x86_64-linux = vmTests.integration-tests;
    };
}
