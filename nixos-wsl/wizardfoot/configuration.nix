# NixOS system configuration for wizardfoot (WSL)
{ config, pkgs, lib, ... }:

{
  imports = [
    ../base-configuration.nix
  ];

  # Machine-specific settings
  networking.hostName = "wizardfoot";
  
  # WSL-specific hostname setting
  wsl.wslConf.network.hostname = "wizardfoot";
  
  # Machine-specific environment variables
  environment.sessionVariables = {
    MACHINE_NAME = "wizardfoot";
  };

  # Update the auto-update config to use the correct flake target
  environment.etc."dotfiles-auto-update.conf".text = lib.mkForce ''
    # Dotfiles auto-update configuration for wizardfoot
    DOTFILES_AUTO_UPDATE_ENABLED=true
    DOTFILES_PATH=/home/rictic/open/dotfiles
    DOTFILES_BRANCH=main
    LOG_LEVEL=info
    FLAKE_CONFIG=wizardfoot
  '';

  # Machine-specific packages (if any)
  environment.systemPackages = with pkgs; [
    # Add any wizardfoot-specific packages here
    caddy
  ];

  # Caddy reverse proxy configuration
  services.caddy = {
    enable = true;
    virtualHosts = {
      "pf.rictic.com" = {
        extraConfig = ''
          reverse_proxy localhost:30000 {
            header_up X-Forwarded-For {remote_host}
          }
        '';
      };
      "stoot.rictic.com" = {
        extraConfig = ''
          handle_path /f0761029-433c-4cd6-bba3-5170bd8ea4a1/* {
            reverse_proxy 192.168.86.38:8188
          }
        '';
      };
    };
  };

  # Open firewall ports for Caddy
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 ];
  };
}
