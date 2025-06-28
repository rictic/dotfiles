# NixOS system configuration for wizardfoot (WSL)
{ pkgs, lib, ... }:

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

  environment.systemPackages = with pkgs; [
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

  systemd.services.caddy = {
    serviceConfig = {
      # Restart on failure
      Restart = "on-failure";
      RestartSec = lib.mkForce "10s";
      # Don't restart too frequently
      StartLimitIntervalSec = "60s";
      StartLimitBurst = "3";
    };
  };

  services.forgejo = {
    enable = true;
    database.type = "sqlite3";
    settings = {
      server.DOMAIN = "git.yourdomain.local";
      server.HTTP_PORT = 7272;
      # We don't need any additional users.
      service.DISABLE_REGISTRATION = true;
    };
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      80 # HTTP
      443 # HTTPS
      22 # SSH
    ];
  };
}
