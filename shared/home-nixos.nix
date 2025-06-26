# NixOS WSL specific home configuration
{ config, pkgs, ... }:

{
  # Import common configuration
  imports = [ ../shared/home-common.nix ];

  # Additional Linux/WSL-specific packages
  home.packages = [
    # Additional Linux/WSL specific tools
    pkgs.htop
    pkgs.tree
    pkgs.bat
    pkgs.eza  # Modern replacement for exa
    pkgs.fd
    
    # WSL integration tools
    pkgs.wslu

    # Uncomment if claude-code builds successfully
    # pkgs.claude-code-latest
  ];

  # WSL-specific session variables
  home.sessionVariables = {
    # WSL-specific variables
    BROWSER = "/mnt/c/Program Files/Google/Chrome/Application/chrome.exe";
  };

  # WSL-specific shell aliases and configuration
  programs.zsh.shellAliases = {
    # Modern ls replacement aliases (using eza)
    ls = "eza";
    ll = "eza -l";
    la = "eza -la";
    lt = "eza --tree";
    
    # WSL-specific aliases
    explorer = "explorer.exe";
    code = "code";
  };

  programs.zsh.initExtra = ''
    # Set up WSL-specific environment
    export DISPLAY=:0
  '';

  # Git configuration with WSL-specific settings
  programs.git.extraConfig = {
    # Handle line endings properly in WSL
    core.autocrlf = "input";
    
    # Use VS Code as diff/merge tool if available
    diff.tool = "vscode";
    merge.tool = "vscode";
    difftool.vscode.cmd = "code --wait --diff $LOCAL $REMOTE";
    mergetool.vscode.cmd = "code --wait $MERGED";
  };

  # Tmux with WSL-specific settings
  programs.tmux.extraConfig = ''
    # WSL-specific tmux settings
    set -g default-terminal "screen-256color"
  '';

  # Bat configuration
  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
    };
  };

  # FZF with fd integration
  programs.fzf = {
    defaultCommand = "fd --type f";
  };
}
