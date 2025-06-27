# Shared base configuration for all WSL NixOS machines
{ pkgs, ... }:

let
  # Import shared packages - these will be passed from the flake
  commonSystemPackages = import ../shared/common-system-packages.nix { inherit pkgs; };
in
{
  # Import the auto-update module
  imports = [
    ../shared/auto-update/dotfiles-auto-update.nix
  ];

  # WSL-specific settings
  wsl = {
    enable = true;
    defaultUser = "rictic";
    startMenuLaunchers = true;

    useWindowsDriver = true;

    # Enable integration with Windows
    wslConf.automount.root = "/mnt";
    wslConf.interop.appendWindowsPath = false;
    wslConf.network.generateHosts = false;
  };

  # System packages - equivalent to environment.systemPackages in nix-darwin
  environment.systemPackages = commonSystemPackages ++ [
    # claude-code-latest  # Commented out due to build issues, can be installed manually with npm

    # WSL-specific utilities
    pkgs.wslu # WSL utilities

    # Add steam-run for FHS compatibility (useful for running non-Nix binaries)
    pkgs.steam-run

    # Simple HTTP server for demonstration
    pkgs.python3
  ];

  # User account configuration
  users = {
    users.rictic = {
      isNormalUser = true;
      shell = pkgs.zsh;
      extraGroups = [
        "wheel"
        "docker"
        "audio"
        "video"
        "sudo"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH4XhLvnDXQ815nB6fqCIWZ6sV2SY5eUavWAhScLP4Qh rictic@gmail.com"
      ];
    };

    # Allow rictic to use sudo without password
    extraUsers.rictic.extraGroups = [ "wheel" ];
  };

  # Enable sudo for wheel group
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  # System services
  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        PubkeyAuthentication = true;
        AuthenticationMethods = "publickey";
        AllowUsers = [ "rictic" ];
      };
    };
  };

  # Firewall configuration
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22 # SSH
    ];
  };

  # Virtualization
  virtualisation = {
    # Docker
    docker = {
      enable = true;
      enableOnBoot = true;
    };
  };

  # Enable necessary programs
  programs = {
    zsh.enable = true;
    git.enable = true;
    vim.enable = true;

    # Enable nix-ld for running unpatched binaries
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc
        openssl
        curl
        glib
        util-linux
        glibc
        icu
        libunwind
        libuuid
        zlib
        libsecret
        # Add more libraries as needed
      ];
    };
  };

  # Nix configuration
  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      trusted-users = [ "rictic" ];
    };

    # Garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # Network configuration
  networking = {
    # hostname will be set in machine-specific configs
    # Don't try to manage network interfaces in WSL
    dhcpcd.enable = false;
    # Use systemd-resolved for DNS
    networkmanager.enable = false;
  };

  # Configure the dotfiles auto-update service
  services.dotfiles-auto-update = {
    enable = true;
    enableHelloServer = true; # Enable the demo server
    # All other options use defaults but can be customized here
  };

  # Time zone configuration
  time.timeZone = "America/Los_Angeles"; # Adjust to your timezone

  # Locale settings
  i18n.defaultLocale = "en_US.UTF-8";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "24.11";
}
