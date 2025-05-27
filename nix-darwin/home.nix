# After changing this file, run `sudo darwin-rebuild switch` to apply changes.
{ config, pkgs, ... }:

{
  # User packages - these will be available in your PATH
  home.packages = with pkgs; [
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

    # Shell utilities (zsh will be configured separately)
    direnv
    starship

    # Nix utilities
    nixfmt-rfc-style
  ];

  # Shell configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
  };

  # Starship prompt
  programs.starship = {
    enable = true;
    # This automatically adds the init to your shell
  };

  programs.git = {
    enable = true;
    userName = "Peter Burns";
    userEmail = "rictic@gmail.com";
  };

  # Tmux configuration
  programs.tmux = {
    enable = true;
    # add your tmux config here
  };

  # Direnv integration
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
  };

  home.stateVersion = "24.11";
}
