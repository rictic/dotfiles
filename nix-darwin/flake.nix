# To use this, go through the nix-darwin setup process, but
# instead of creating /etc/nix-darwin/flake.nix
# do:
#    ln -s ~/open/dotfiles/nix-darwin/flake.nix /etc/nix-darwin/flake.nix
#
# I believe these are the complete instructions:
#    sudo mkdir -p /etc/nix-darwin
#    sudo chown $(id -nu):$(id -ng) /etc/nix-darwin
#    cd /etc/nix-darwin
#    ln -s ~/open/dotfiles/nix-darwin-flake.nix /etc/nix-darwin/flake.nix
#    sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin/master#darwin-rebuild -- switch
#
# And from then on, after changing this file, just do:
#    sudo darwin-rebuild switch
{
  description = "nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-24.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      home-manager,
    }:
    let
      configuration =
        { pkgs, lib, ... }:
        {
          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          environment.systemPackages = [
            pkgs.vim
            pkgs.claude-code-latest
          ];

          # Allow specific unfree packages
          nixpkgs.config.allowUnfreePredicate =
            pkg:
            builtins.elem (lib.getName pkg) [
              "@anthropic-ai/claude-code"
            ];

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Enable alternative shell support in nix-darwin.
          # programs.fish.enable = true;

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 5;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";

          users.users.rictic.home = "/Users/rictic";
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.rictic = import ./home.nix;
        };
      claude-overlay = final: prev: {
        claude-code-latest = prev.stdenv.mkDerivation rec {
          pname = "@anthropic-ai/claude-code";
          version = "1.0.25";

          src = prev.fetchurl {
            url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
            hash = "sha512-5p4FLlFO4TuRf0zV0axiOxiAkUC8eer0lqJi/A/pA46LESv31Alw6xaNYgwQVkP6oSbP5PydK36u7YrB9QSaXQ==";
          };

          buildInputs = [ prev.nodejs ];

          installPhase = ''
            mkdir -p $out/bin
            mkdir -p $out/lib/node_modules/@anthropic-ai/claude-code

            # Copy the entire package to the lib directory
            cp -r . $out/lib/node_modules/@anthropic-ai/claude-code/

            # Create the binary symlink (the actual binary is cli.js according to package.json)
            ln -s $out/lib/node_modules/@anthropic-ai/claude-code/cli.js $out/bin/claude

            # Make sure the binary is executable
            chmod +x $out/lib/node_modules/@anthropic-ai/claude-code/cli.js
          '';

          meta = with prev.lib; {
            description = "Agentic coding tool that lives in your terminal";
            homepage = "https://github.com/anthropics/claude-code";
            license = licenses.unfree;
            platforms = platforms.darwin;
          };
        };
      };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#reepicheep
      darwinConfigurations."reepicheep" = nix-darwin.lib.darwinSystem {
        modules = [
          { nixpkgs.overlays = [ claude-overlay ]; }
          configuration
          home-manager.darwinModules.home-manager
        ];
      };
    };
}
