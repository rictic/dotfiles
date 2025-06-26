# Common home-manager configuration shared between nix-darwin and NixOS
{ config, pkgs, lib, ... }:

let
  commonPackages = import ./common-packages.nix { inherit pkgs; };
in
{
  # User packages - common across all platforms
  home.packages = commonPackages;

  # Common session variables
  home.sessionVariables = {
    EDITOR = "code -w";
  };

  # Shell configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    shellAliases = {
      l = "ls -a -l -h";
      gs = "git status";
      gc = "git commit";
      gp = "git push";
      gca = "git commit -a";
      gb = "git checkout -b";
      gclean = "git branch --merged | grep -v \"*\" | grep -v master | grep -v dev | xargs -n 1 git branch -d";
      npx = "npx --no-install";
    };
  };

  # Starship prompt
  programs.starship = {
    enable = true;
  };

  # Git configuration
  programs.git = {
    enable = true;
    userName = "Peter Burns";
    userEmail = "rictic@gmail.com";
  };

  # Tmux configuration
  programs.tmux = {
    enable = true;
  };

  # Direnv integration
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
  };

  # FZF configuration
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultOptions = [ "--height 40%" "--border" ];
  };

  home.stateVersion = "24.11";
}
