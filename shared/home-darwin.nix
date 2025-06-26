# nix-darwin specific home configuration
{ config, pkgs, ... }:

{
  # Import common configuration
  imports = [ ../shared/home-common.nix ];

  # Additional darwin-specific packages
  home.packages = [
  ];

  # Platform-specific overrides can go here
}
