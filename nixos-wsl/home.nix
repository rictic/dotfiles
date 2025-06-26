# Home Manager configuration for NixOS WSL
# After changing this file, run `sudo nixos-rebuild switch --flake /etc/nixos#nixos-wsl` to apply changes.
{ config, pkgs, ... }:

{
  # User packages - these will be available in your PATH
  # Reusing most packages from the nix-darwin setup
  home.packages = with pkgs; [

    # Dev tools (same as nix-darwin)
    git
    vim
    tmux
    fzf
    ripgrep
    jq

    # Language toolchains (same as nix-darwin)
    nodejs
    python3
    rustc
    cargo

    # Media tools (same as nix-darwin)
    ffmpeg

    # Shell utilities (same as nix-darwin)
    direnv
    starship

    # Nix utilities (same as nix-darwin)
    nixfmt-rfc-style
    nil

    # Our custom claude code (commented out due to build issues)
    # pkgs.claude-code-latest  # Can be installed manually: npm install -g @anthropic-ai/claude-code

    # Additional Linux/WSL specific tools
    htop
    tree
    bat
    eza  # Modern replacement for exa
    fd
    
    # WSL integration tools
    wslu
  ];

  # Session variables (same as nix-darwin, but may want to adjust for WSL)
  home.sessionVariables = {
    EDITOR = "code -w";  # Assumes VS Code is available via Windows integration
    
    # WSL-specific variables
    BROWSER = "/mnt/c/Program Files/Google/Chrome/Application/chrome.exe";  # Adjust path as needed
  };

  # Shell configuration (same as nix-darwin)
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
      gclean = "git branch --merged | grep -v \"\*\" | grep -v master | grep -v dev | xargs -n 1 git branch -d";
      npx = "npx --no-install";
      
      # Modern ls replacement aliases (using eza)
      ls = "eza";
      ll = "eza -l";
      la = "eza -la";
      lt = "eza --tree";
      
      # WSL-specific aliases
      explorer = "explorer.exe";
      code = "code";  # VS Code should work via WSL integration
    };
    
    # WSL-specific shell initialization
    initExtra = ''
      # Add Windows binaries to PATH if needed
      # export PATH="$PATH:/mnt/c/Windows/System32"
      
      # Set up WSL-specific environment
      export DISPLAY=:0
    '';
  };

  # Starship prompt (same as nix-darwin)
  programs.starship = {
    enable = true;
    # This automatically adds the init to your shell
  };

  # Git configuration (same as nix-darwin)
  programs.git = {
    enable = true;
    userName = "Peter Burns";
    userEmail = "rictic@gmail.com";
    
    # Additional git config for WSL
    extraConfig = {
      # Handle line endings properly in WSL
      core.autocrlf = "input";
      
      # Use VS Code as diff/merge tool if available
      diff.tool = "vscode";
      merge.tool = "vscode";
      difftool.vscode.cmd = "code --wait --diff $LOCAL $REMOTE";
      mergetool.vscode.cmd = "code --wait $MERGED";
    };
  };

  # Tmux configuration (same as nix-darwin)
  programs.tmux = {
    enable = true;
    # Add your tmux config here
    extraConfig = ''
      # WSL-specific tmux settings
      set -g default-terminal "screen-256color"
    '';
  };

  # Direnv integration (same as nix-darwin)
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
  };

  # Additional programs that work well in WSL
  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
    };
  };

  # Note: eza is the modern replacement for exa, but we'll just use it as a package
  # since the home-manager module may not be available in all versions

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f";
    defaultOptions = [ "--height 40%" "--border" ];
  };

  home.stateVersion = "24.11";
}
