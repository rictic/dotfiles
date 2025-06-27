# NixOS system configuration for abadar (WSL)
{ ... }:

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
}
