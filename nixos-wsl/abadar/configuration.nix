# NixOS system configuration for abadar (WSL)
{ config, pkgs, lib, ... }:

{
  imports = [
    ../base-configuration.nix
  ];

  # Machine-specific settings
  networking.hostName = "abadar";
  
  # WSL-specific hostname setting
  wsl.wslConf.network.hostname = "abadar";
  
  # Machine-specific environment variables
  environment.sessionVariables = {
    MACHINE_NAME = "abadar";
  };

  # Update the auto-update config to use the correct flake target
  environment.etc."dotfiles-auto-update.conf".text = lib.mkForce ''
    # Dotfiles auto-update configuration for abadar
    DOTFILES_AUTO_UPDATE_ENABLED=true
    DOTFILES_PATH=/home/rictic/open/dotfiles
    DOTFILES_BRANCH=main
    LOG_LEVEL=info
    FLAKE_CONFIG=abadar
  '';

  # Machine-specific packages (if any)
  environment.systemPackages = with pkgs; [
    # Add any abadar-specific packages here
  ];
}
