# nix-darwin specific home configuration
{ config, pkgs, ... }:

{
  # Import common configuration
  imports = [ ../shared/home-common.nix ];

  # Additional darwin-specific packages
  home.packages = [
    # Add the custom claude code package
    pkgs.claude-code-latest
  ];

  # Platform-specific overrides can go here
  programs.fzf = {
    defaultCommand = "fd --type f";
  };
}
