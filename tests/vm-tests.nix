# VM tests for dotfiles configuration
{
  nixpkgs,
  nixos-wsl,
  home-manager,
  nix-darwin,
  inputs,
}:

let
  # Common test utilities
  testLib = nixpkgs.lib;

  # Test user credentials
  testPassword = "test123";

  # Common test packages for verification
  testPackages = [
    "git"
    "vim"
    "tmux"
    "node"
    "python3"
    "rustc"
    "cargo"
    "fzf"
    "rg"
    "jq"
    "ffmpeg"
    "direnv"
    "starship"
  ];

in
{
  # Test NixOS WSL configuration (abadar)
  nixos-wsl-abadar =
    let
      pkgsWithUnfree = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
    in
    pkgsWithUnfree.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        # Use the actual configuration but with test modifications
        nixos-wsl.nixosModules.wsl
        ../nixos-wsl/abadar/configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = false;
          home-manager.useUserPackages = true;
          home-manager.users.rictic = import ../shared/home-nixos.nix;
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.sharedModules = [
            {
              nixpkgs.overlays = [ (import ../shared/claude-overlay.nix) ];
            }
          ];
        }
        # Test-specific overrides
        {
          # Disable WSL for VM testing
          wsl.enable = testLib.mkForce false;

          # Enable VM-specific settings
          virtualisation.vmVariant = {
            virtualisation.memorySize = 2048;
            virtualisation.diskSize = 8192;
            virtualisation.cores = 2;
          };

          # Set a test password for the user
          users.users.rictic.password = testPassword;

          # Add test-specific packages
          environment.systemPackages = with pkgsWithUnfree; [
            # Testing utilities
            curl
            nettools
            ps
            which
          ];
        }
      ];
    };

  # Test NixOS WSL configuration (wizardfoot)
  nixos-wsl-wizardfoot =
    let
      pkgsWithUnfree = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
    in
    pkgsWithUnfree.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        nixos-wsl.nixosModules.wsl
        ../nixos-wsl/wizardfoot/configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = false;
          home-manager.useUserPackages = true;
          home-manager.users.rictic = import ../shared/home-nixos.nix;
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.sharedModules = [
            {
              nixpkgs.overlays = [ (import ../shared/claude-overlay.nix) ];
            }
          ];
        }
        {
          # Test-specific overrides
          wsl.enable = testLib.mkForce false;

          virtualisation.vmVariant = {
            virtualisation.memorySize = 2048;
            virtualisation.diskSize = 8192;
            virtualisation.cores = 2;
          };

          users.users.rictic.password = testPassword;

          environment.systemPackages = with pkgsWithUnfree; [
            curl
            nettools
            ps
            which
          ];
        }
      ];
    };

  # Integration tests using NixOS testing framework
  integration-tests = {

    # Test basic system functionality
    basic-system-test =
      let
        pkgsWithUnfree = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
          overlays = [ (import ../shared/claude-overlay.nix) ];
        };
      in
      pkgsWithUnfree.nixosTest {
        name = "dotfiles-basic-system";

        nodes.machine =
          { config, pkgs, ... }:
          {
            _module.args = { inherit inputs; };

            imports = [
              nixos-wsl.nixosModules.wsl
              ../nixos-wsl/base-configuration.nix
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = false;
                home-manager.useUserPackages = true;
                home-manager.users.rictic = import ../shared/home-nixos.nix;
                home-manager.extraSpecialArgs = { inherit inputs; };
                home-manager.sharedModules = [
                  {
                    nixpkgs.overlays = [ (import ../shared/claude-overlay.nix) ];
                  }
                ];
              }
            ];

            # Test overrides
            wsl.enable = testLib.mkForce false;
            networking.hostName = "test-machine";
            users.users.rictic.password = testPassword;
          };

        testScript = ''
          machine.wait_for_unit("default.target")

          # Test that the user exists and can log in
          machine.wait_for_unit("getty@tty1.service")
          machine.succeed("getent passwd rictic")

          # Wait for home-manager to complete setup
          # Check if home-manager created the user's zsh config
          machine.wait_for_file("/home/rictic/.zshrc")

          # Test that essential packages are installed (in user environment)
          # Login as user to get proper environment
          ${testLib.concatMapStringsSep "\n" (
            pkg: "machine.succeed(\"sudo -u rictic -i which ${pkg}\")"
          ) testPackages}

          # Test that home-manager configuration is applied
          machine.succeed("sudo -u rictic test -f /home/rictic/.zshrc")

          # Test git configuration
          machine.succeed("sudo -u rictic git config --get user.name | grep 'Peter Burns'")
          machine.succeed("sudo -u rictic git config --get user.email | grep 'rictic@gmail.com'")

          # Test shell aliases (check if zsh aliases work)
          machine.succeed("sudo -u rictic -i bash -c 'zsh -i -c \"alias | grep gs\"'")

          # Test that starship is configured
          machine.succeed("sudo -u rictic -i which starship")

          # Test that tmux works (just test that it runs)
          machine.succeed("sudo -u rictic -i tmux -V")

          # Test Docker service
          machine.wait_for_unit("docker.service")
          machine.succeed("docker info")

          # Test SSH service
          machine.wait_for_unit("sshd.service")
          machine.succeed("systemctl is-active sshd")

          # Test that nix flakes work
          machine.succeed("sudo -u rictic -i nix --version | grep -E '2\\.[0-9]+\\.[0-9]+'")
          machine.succeed("sudo -u rictic -i nix flake --help")

          # Test that claude-code is available (fails currently)
          # machine.succeed("sudo -u rictic -i which claude")
        '';
      };

    # Test auto-update service
    auto-update-test =
      let
        pkgsWithUnfree = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
          overlays = [ (import ../shared/claude-overlay.nix) ];
        };
      in
      pkgsWithUnfree.nixosTest {
        name = "dotfiles-auto-update";

        nodes.machine =
          { config, pkgs, ... }:
          {
            _module.args = { inherit inputs; };

            imports = [
              nixos-wsl.nixosModules.wsl
              ../nixos-wsl/base-configuration.nix
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = false;
                home-manager.useUserPackages = true;
                home-manager.users.rictic = import ../shared/home-nixos.nix;
                home-manager.extraSpecialArgs = { inherit inputs; };
                home-manager.sharedModules = [
                  {
                    nixpkgs.overlays = [ (import ../shared/claude-overlay.nix) ];
                  }
                ];
              }
            ];

            wsl.enable = testLib.mkForce false;
            networking.hostName = "auto-update-test";
            users.users.rictic.password = testPassword;

            # Enable auto-update service for testing
            services.dotfiles-auto-update = {
              enable = true;
              enableHelloServer = true;
            };
          };

        testScript = ''
          machine.wait_for_unit("default.target")

          # Test that auto-update timer is enabled
          machine.wait_for_unit("dotfiles-auto-update.timer")
          machine.succeed("systemctl is-enabled dotfiles-auto-update.timer")

          # Test that hello server is running
          machine.wait_for_unit("hello-server.service")
          machine.wait_for_open_port(8000)

          # Test hello server response
          machine.succeed("curl -f http://localhost:8000/ | grep -i hello")

          # Test control script
          machine.succeed("dotfiles-auto-update-ctl --help")
          machine.succeed("dotfiles-auto-update-ctl status")

          # Test configuration file exists
          machine.succeed("test -f /etc/dotfiles-auto-update.conf")
          machine.succeed("grep 'DOTFILES_AUTO_UPDATE_ENABLED=true' /etc/dotfiles-auto-update.conf")
        '';
      };

    # Test machine-specific configurations
    machine-specific-test =
      let
        pkgsWithUnfree = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
          overlays = [ (import ../shared/claude-overlay.nix) ];
        };
      in
      pkgsWithUnfree.nixosTest {
        name = "dotfiles-machine-specific";

        nodes = {
          abadar =
            { config, pkgs, ... }:
            {
              _module.args = { inherit inputs; };

              imports = [
                nixos-wsl.nixosModules.wsl
                ../nixos-wsl/abadar/configuration.nix
                home-manager.nixosModules.home-manager
                {
                  home-manager.useGlobalPkgs = false;
                  home-manager.useUserPackages = true;
                  home-manager.users.rictic = import ../shared/home-nixos.nix;
                  home-manager.extraSpecialArgs = { inherit inputs; };
                  home-manager.sharedModules = [
                    {
                      nixpkgs.overlays = [ (import ../shared/claude-overlay.nix) ];
                      nixpkgs.config.allowUnfree = true;
                    }
                  ];
                }
              ];

              wsl.enable = testLib.mkForce false;
              users.users.rictic.password = testPassword;
            };

          wizardfoot =
            { config, pkgs, ... }:
            {
              _module.args = { inherit inputs; };
              imports = [
                nixos-wsl.nixosModules.wsl
                ../nixos-wsl/wizardfoot/configuration.nix
                home-manager.nixosModules.home-manager
                {
                  home-manager.useGlobalPkgs = false;
                  home-manager.useUserPackages = true;
                  home-manager.users.rictic = import ../shared/home-nixos.nix;
                  home-manager.extraSpecialArgs = { inherit inputs; };
                  home-manager.sharedModules = [
                    {
                      nixpkgs.overlays = [ (import ../shared/claude-overlay.nix) ];
                      nixpkgs.config.allowUnfree = true;
                    }
                  ];
                }
              ];

              wsl.enable = testLib.mkForce false;
              users.users.rictic.password = testPassword;
            };
        };

        testScript = ''
          # Test machine-specific hostnames and configurations
          abadar.wait_for_unit("default.target")
          abadar.succeed("hostname | grep abadar")
          abadar.succeed("grep 'FLAKE_CONFIG=abadar' /etc/dotfiles-auto-update.conf")

          wizardfoot.wait_for_unit("default.target")
          wizardfoot.succeed("hostname | grep wizardfoot")
          wizardfoot.succeed("grep 'FLAKE_CONFIG=wizardfoot' /etc/dotfiles-auto-update.conf")
        '';
      };

    # Test home-manager integration
    home-manager-test =
      let
        pkgsWithUnfree = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
          overlays = [ (import ../shared/claude-overlay.nix) ];
        };
      in
      pkgsWithUnfree.nixosTest {
        name = "dotfiles-home-manager";

        nodes.machine =
          { config, pkgs, ... }:
          {
            _module.args = { inherit inputs; };

            imports = [
              nixos-wsl.nixosModules.wsl
              ../nixos-wsl/base-configuration.nix
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = false;
                home-manager.useUserPackages = true;
                home-manager.users.rictic = import ../shared/home-nixos.nix;
                home-manager.extraSpecialArgs = { inherit inputs; };
                home-manager.sharedModules = [
                  {
                    nixpkgs.overlays = [ (import ../shared/claude-overlay.nix) ];
                  }
                ];
              }
            ];

            wsl.enable = testLib.mkForce false;
            networking.hostName = "home-manager-test";
            users.users.rictic.password = testPassword;
            services.dotfiles-auto-update.enable = testLib.mkForce false;
          };

        testScript = ''
          machine.wait_for_unit("default.target")

          # Wait for home-manager to complete setup
          machine.wait_for_file("/home/rictic/.zshrc")

          # Test home-manager user packages are available
          ${testLib.concatMapStringsSep "\n" (
            pkg: "machine.succeed(\"sudo -u rictic -i which ${pkg}\")"
          ) testPackages}

          # Test shell configuration
          machine.succeed("sudo -u rictic test -f /home/rictic/.zshrc")
          machine.succeed("sudo -u rictic -i zsh -c 'echo $EDITOR' | grep 'code -w'")

          # Test git configuration is applied
          machine.succeed("sudo -u rictic git config --global --get user.name | grep 'Peter Burns'")
          machine.succeed("sudo -u rictic git config --global --get user.email | grep 'rictic@gmail.com'")

          # Test starship is available (program enables it)
          machine.succeed("sudo -u rictic -i which starship")

          # Test tmux is available (program enables it)
          machine.succeed("sudo -u rictic -i tmux -V")

          # Test direnv integration
          machine.succeed("sudo -u rictic -i which direnv")

          # Test that user packages are in PATH
          machine.succeed("sudo -u rictic -i which node")
          machine.succeed("sudo -u rictic -i which python3")
          machine.succeed("sudo -u rictic -i which rustc")
          machine.succeed("sudo -u rictic -i which cargo")

          # Test that claude-code is available (fails currently)
          # machine.succeed("sudo -u rictic -i which claude")
        '';
      };
  };
}
