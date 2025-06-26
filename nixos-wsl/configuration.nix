# NixOS system configuration for WSL
{ config, pkgs, lib, ... }:

let
  commonSystemPackages = import ../shared/common-system-packages.nix { inherit pkgs; };
in
{
  # WSL-specific settings
  wsl = {
    enable = true;
    defaultUser = "rictic";
    startMenuLaunchers = true;
    
    # Enable integration with Windows
    wslConf.automount.root = "/mnt";
    wslConf.interop.appendWindowsPath = false;
    wslConf.network.generateHosts = false;
  };

  # System packages - equivalent to environment.systemPackages in nix-darwin
  environment.systemPackages = commonSystemPackages ++ [
    # claude-code-latest  # Commented out due to build issues, can be installed manually with npm
    
    # WSL-specific utilities
    pkgs.wslu  # WSL utilities
  ];

  # Allow specific unfree packages (same as nix-darwin)
  # nixpkgs.config.allowUnfreePredicate =
  #   pkg:
  #   builtins.elem (lib.getName pkg) [
  #     "@anthropic-ai/claude-code"  # Commented out - install manually if needed
  #   ];

  # Enable flakes (same as nix-darwin)
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Configure the default user
  users.users.rictic = {
    isNormalUser = true;
    home = "/home/rictic";
    description = "Peter Burns";
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    shell = pkgs.zsh;
  };

  # Enable sudo for wheel group
  security.sudo.wheelNeedsPassword = false;

  # Enable zsh system-wide
  programs.zsh.enable = true;

  # Enable git system-wide
  programs.git.enable = true;

  # Docker support (useful for development in WSL)
  #virtualisation.docker = {
  #  enable = true;
  #  enableOnBoot = true;
  #};

  # Time zone configuration
  time.timeZone = "America/Los_Angeles";  # Adjust to your timezone

  # Locale settings
  i18n.defaultLocale = "en_US.UTF-8";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "24.11";
}
