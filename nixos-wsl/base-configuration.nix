# Shared base configuration for all WSL NixOS machines
{ config, pkgs, lib, ... }:

let
  # Import shared packages - these will be passed from the flake
  commonSystemPackages = import ../shared/common-system-packages.nix { inherit pkgs; };
in
{
  # Allow unfree packages (needed for some packages like steam-run)
  nixpkgs.config.allowUnfree = true;

  # WSL-specific settings
  wsl = {
    enable = true;
    defaultUser = "rictic";
    startMenuLaunchers = true;
    
    # Enable integration with Windows
    wslConf.automount.root = "/mnt";
    wslConf.interop.appendWindowsPath = false;
    wslConf.network.generateHosts = false;
  };

  # System packages - equivalent to environment.systemPackages in nix-darwin
  environment.systemPackages = commonSystemPackages ++ [
    # claude-code-latest  # Commented out due to build issues, can be installed manually with npm
    
    # WSL-specific utilities
    pkgs.wslu  # WSL utilities
    
    # Add steam-run for FHS compatibility (useful for running non-Nix binaries)
    pkgs.steam-run
    
    # Simple HTTP server for demonstration
    pkgs.python3
    
    # Dotfiles auto-update management script
    (pkgs.writeShellScriptBin "dotfiles-auto-update-ctl" ''
      #!/bin/bash
      set -euo pipefail
      
      CONFIG_FILE="/etc/dotfiles-auto-update.conf"
      SERVICE_NAME="dotfiles-auto-update"
      TIMER_NAME="$SERVICE_NAME.timer"
      ROOT_DOTFILES_PATH="/etc/dotfiles"
      
      case "''${1:-}" in
        enable)
          echo "Enabling dotfiles auto-update..."
          sudo sed -i 's/DOTFILES_AUTO_UPDATE_ENABLED=.*/DOTFILES_AUTO_UPDATE_ENABLED=true/' "$CONFIG_FILE"
          sudo systemctl enable "$TIMER_NAME"
          sudo systemctl start "$TIMER_NAME"
          echo "Auto-update enabled and started"
          ;;
        disable)
          echo "Disabling dotfiles auto-update..."
          sudo sed -i 's/DOTFILES_AUTO_UPDATE_ENABLED=.*/DOTFILES_AUTO_UPDATE_ENABLED=false/' "$CONFIG_FILE"
          sudo systemctl stop "$TIMER_NAME"
          sudo systemctl disable "$TIMER_NAME"
          echo "Auto-update disabled and stopped"
          ;;
        status)
          echo "=== Auto-update Status ==="
          if systemctl is-active --quiet "$TIMER_NAME"; then
            echo "Timer: Active"
          else
            echo "Timer: Inactive"
          fi
          
          if systemctl is-enabled --quiet "$TIMER_NAME"; then
            echo "Timer: Enabled"
          else
            echo "Timer: Disabled"
          fi
          
          echo ""
          echo "=== Configuration ==="
          if [ -f "$CONFIG_FILE" ]; then
            grep -E "^[^#]" "$CONFIG_FILE" || echo "No configuration found"
          else
            echo "Configuration file not found"
          fi
          
          echo ""
          echo "=== Repository Status ==="
          if [ -d "$ROOT_DOTFILES_PATH" ]; then
            echo "Root dotfiles repo: EXISTS at $ROOT_DOTFILES_PATH"
            if [ -d "$ROOT_DOTFILES_PATH/.git" ]; then
              cd "$ROOT_DOTFILES_PATH"
              echo "Current branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"
              echo "Last commit: $(git log -1 --oneline 2>/dev/null || echo 'unknown')"
              echo "Repository owner: $(stat -c %U . 2>/dev/null || echo 'unknown')"
            else
              echo "Not a git repository"
            fi
          else
            echo "Root dotfiles repo: NOT FOUND"
          fi
          
          echo ""
          echo "=== Last runs ==="
          systemctl list-timers "$TIMER_NAME" --no-pager
          ;;
        run-now)
          echo "Triggering immediate update check..."
          sudo systemctl start "$SERVICE_NAME"
          echo "Update check triggered. Check logs with: dotfiles-auto-update-ctl logs"
          ;;
        logs)
          LINES="''${2:-50}"
          if [ "''${2:-}" = "-f" ] || [ "''${2:-}" = "--follow" ]; then
            echo "Following dotfiles auto-update logs (Ctrl+C to stop)..."
            journalctl -u "$SERVICE_NAME" -f
          else
            echo "Last $LINES lines of dotfiles auto-update logs:"
            journalctl -u "$SERVICE_NAME" -n "$LINES" --no-pager
          fi
          ;;
        reset)
          echo "Resetting root dotfiles repository..."
          if [ -d "$ROOT_DOTFILES_PATH" ]; then
            echo "Removing existing root repository..."
            sudo rm -rf "$ROOT_DOTFILES_PATH"
          fi
          echo "Repository will be re-cloned on next update"
          ;;
        *)
          echo "Usage: dotfiles-auto-update-ctl {enable|disable|status|run-now|logs [count|-f]|reset}"
          echo ""
          echo "Commands:"
          echo "  enable     - Enable auto-updates"
          echo "  disable    - Disable auto-updates"  
          echo "  status     - Show current status and repository info"
          echo "  run-now    - Trigger immediate update check"
          echo "  logs [N]   - Show last N log lines (default: 50)"
          echo "  logs -f    - Follow logs in real-time"
          echo "  reset      - Remove root dotfiles repo (will be re-cloned)"
          exit 1
          ;;
      esac
    '')
  ];

  # User account configuration
  users = {
    users.rictic = {
      isNormalUser = true;
      shell = pkgs.zsh;
      extraGroups = [ "wheel" "docker" "audio" "video" ];
      # We'll set up SSH keys via home-manager
    };
    
    # Allow rictic to use sudo without password
    extraUsers.rictic.extraGroups = [ "wheel" ];
  };

  # Enable sudo for wheel group
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  # System services
  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };
  };

  # Virtualization
  virtualisation = {
    # Docker
    docker = {
      enable = true;
      enableOnBoot = true;
    };
  };

  # Enable necessary programs
  programs = {
    zsh.enable = true;
    git.enable = true;
    vim.enable = true;
    
    # Enable nix-ld for running unpatched binaries
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc
        openssl
        curl
        glib
        util-linux
        glibc
        icu
        libunwind
        libuuid
        zlib
        libsecret
        # Add more libraries as needed
      ];
    };
  };

  # Nix configuration
  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      trusted-users = [ "rictic" ];
    };
    
    # Garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # Network configuration
  networking = {
    # hostname will be set in machine-specific configs
    # Don't try to manage network interfaces in WSL
    dhcpcd.enable = false;
    # Use systemd-resolved for DNS
    networkmanager.enable = false;
  };

  # Auto-update configuration
  environment.etc."dotfiles-auto-update.conf".text = ''
    # Dotfiles auto-update configuration
    DOTFILES_AUTO_UPDATE_ENABLED=true
    DOTFILES_PATH=/etc/dotfiles
    DOTFILES_SOURCE_PATH=/home/rictic/open/dotfiles
    DOTFILES_REMOTE=https://github.com/rictic/dotfiles.git
    DOTFILES_BRANCH=main
    LOG_LEVEL=info
    
    # Flake configuration name (will be detected automatically if not set)
    # FLAKE_CONFIG=abadar
  '';

  # Auto-update script
  systemd.services.dotfiles-auto-update = {
    description = "Auto-update dotfiles configuration";
    after = [ "network.target" ];
    wants = [ "network.target" ];
    
    script = ''
      #!/bin/bash
      set -euo pipefail
      
      # Source configuration
      source /etc/dotfiles-auto-update.conf
      
      # Check if auto-update is enabled
      if [ "''${DOTFILES_AUTO_UPDATE_ENABLED:-true}" != "true" ]; then
        echo "Auto-update is disabled, skipping..."
        exit 0
      fi
      
      # Set defaults
      DOTFILES_PATH="''${DOTFILES_PATH:-/etc/dotfiles}"
      DOTFILES_SOURCE_PATH="''${DOTFILES_SOURCE_PATH:-/home/rictic/open/dotfiles}"
      DOTFILES_REMOTE="''${DOTFILES_REMOTE:-https://github.com/rictic/dotfiles.git}"
      DOTFILES_BRANCH="''${DOTFILES_BRANCH:-main}"
      LOG_LEVEL="''${LOG_LEVEL:-info}"
      
      echo "Debug: Root-owned dotfiles path: $DOTFILES_PATH"
      echo "Debug: Source path for reference: $DOTFILES_SOURCE_PATH"
      
      # Handle transition from old configuration - if DOTFILES_PATH is still pointing to rictic's home
      if [ "$DOTFILES_PATH" = "/home/rictic/open/dotfiles" ]; then
        echo "Warning: Still using old configuration, forcing use of /etc/dotfiles"
        DOTFILES_PATH="/etc/dotfiles"
      fi
      
      
      # Initialize or update the root-owned repository
      if [ ! -d "$DOTFILES_PATH" ]; then
        echo "Creating root-owned dotfiles repository at $DOTFILES_PATH"
        mkdir -p "$DOTFILES_PATH"
        cd "$DOTFILES_PATH"
        git clone "$DOTFILES_REMOTE" .
        git checkout "$DOTFILES_BRANCH"
      else
        echo "Updating existing root-owned repository"
        cd "$DOTFILES_PATH"
        
        # Ensure we're on the right branch
        current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
        if [ "$current_branch" != "$DOTFILES_BRANCH" ]; then
          echo "Switching to $DOTFILES_BRANCH branch (was on $current_branch)"
          git fetch origin "$DOTFILES_BRANCH"
          git checkout "$DOTFILES_BRANCH"
        fi
        
        # Check for local changes in root repo
        if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
          echo "Local changes detected in root repository, resetting to clean state"
          git reset --hard HEAD
          git clean -fd
        fi
      fi
      
      echo "Working directory: $(pwd)"
      echo "Repository owner: $(stat -c %U .)"
      
      # Fetch latest changes
      echo "Fetching latest changes..."
      if ! git fetch origin "$DOTFILES_BRANCH" 2>/dev/null; then
        echo "Warning: Failed to fetch from origin"
        exit 1
      fi

      # Check if we need to update
      local_commit=$(git rev-parse HEAD 2>/dev/null)
      remote_commit=$(git rev-parse "origin/$DOTFILES_BRANCH" 2>/dev/null)
      
      if [ "$local_commit" = "$remote_commit" ]; then
        echo "Already up to date"
        exit 0
      fi
      
      echo "Updates available, proceeding with auto-update..."

      # Pull changes
      echo "Pulling changes from origin/$DOTFILES_BRANCH..."
      if ! git pull origin "$DOTFILES_BRANCH"; then
        echo "Error: Failed to pull changes"
        exit 1
      fi
      
      # Test build
      echo "Testing build..."
      if ! nixos-rebuild dry-build --flake ".#$FLAKE_CONFIG"; then
        echo "Build test failed, not applying changes."
        exit 1
      fi
      
      # Apply the configuration
      echo "Applying new configuration..."
      if ! nixos-rebuild switch --flake ".#$FLAKE_CONFIG"; then
        echo "Switch failed. Changes likely not applied."
        exit 1
      fi
      
      echo "Auto-update completed successfully"
    '';
    
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      Group = "root";
      # Ensure git and other necessary commands are available
      Environment = "PATH=${pkgs.git}/bin:${pkgs.nixos-rebuild}/bin:${pkgs.nix}/bin:/run/current-system/sw/bin";
    };
    
    # Only run if git is available - we'll create the directory ourselves
    unitConfig = {
      # No longer depend on rictic's directory existing
    };
    
    # Restart on failure after 1 minute
    serviceConfig.Restart = "on-failure";
    serviceConfig.RestartSec = "60";
  };

  # Timer to run the auto-update every 5 minutes
  systemd.timers.dotfiles-auto-update = {
    description = "Timer for dotfiles auto-update";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";  # Start 5 minutes after boot
      OnUnitActiveSec = "5min";  # Run every 5 minutes
      Persistent = true;  # Run missed timers on boot
    };
  };

  # Time zone configuration
  time.timeZone = "America/Los_Angeles";  # Adjust to your timezone

  # Locale settings
  i18n.defaultLocale = "en_US.UTF-8";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "24.11";

  # Simple HTTP server service for demonstration
  systemd.services.hello-server = {
    description = "Simple HTTP server saying hello from hostname";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "simple";
      User = "rictic";
      WorkingDirectory = "/home/rictic";
      ExecStart = "${pkgs.writeScript "hello-server.py" ''
        #!${pkgs.python3}/bin/python3
        import http.server
        import socketserver
        import socket

        class HelloHandler(http.server.BaseHTTPRequestHandler):
            def do_GET(self):
                hostname = socket.gethostname()
                self.send_response(200)
                self.send_header('Content-type', 'text/plain')
                self.end_headers()
                self.wfile.write(f'Hello from {hostname} - root-owned repo test!\n'.encode())
            
            def log_message(self, format, *args):
                pass  # Suppress default logging

        PORT = 9876
        with socketserver.TCPServer(('0.0.0.0', PORT), HelloHandler) as httpd:
            print(f'Serving at port {PORT}')
            httpd.serve_forever()
      ''}";
      Restart = "always";
      RestartSec = "5";
    };
  };
}
