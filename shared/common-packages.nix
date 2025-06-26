# Common packages shared between nix-darwin and NixOS
{ pkgs }:

with pkgs; [
  # Dev tools
  git
  vim
  tmux
  fzf
  ripgrep
  jq

  # Language toolchains
  nodejs
  python3
  rustc
  cargo

  # Media tools
  ffmpeg

  # Shell utilities
  direnv
  starship

  # Nix utilities
  nixfmt-rfc-style
  nil

  pkgs.claude-code-latest
]
