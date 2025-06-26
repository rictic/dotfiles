# Common system packages shared between nix-darwin and NixOS
{ pkgs }:

with pkgs; [
  vim
  curl
  wget
  unzip
  gcc
  gnumake
]
