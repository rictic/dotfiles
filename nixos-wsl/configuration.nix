# NixOS system configuration for WSL
{ config, pkgs, lib, ... }:

let
  # Import shared packages - these will be passed from the flake
  commonSystemPackages = import ../shared/common-system-packages.nix { inherit pkgs; };
in
{
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
    
    # Dotfiles auto-update management script
    (pkgs.writeShellScriptBin "dotfiles-auto-update-ctl" ''
      #!/bin/bash
      set -euo pipefail
      
      CONFIG_FILE="/etc/dotfiles-auto-update.conf"
      SERVICE_NAME="dotfiles-auto-update"
      TIMER_NAME="$SERVICE_NAME.timer"
      
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
          if grep -q "DOTFILES_AUTO_UPDATE_ENABLED=true" "$CONFIG_FILE"; then
            echo "Config: ENABLED"
          else
            echo "Config: DISABLED"
          fi
          echo ""
          echo "=== Timer Status ==="
          sudo systemctl status "$TIMER_NAME" --no-pager -l
          echo ""
          echo "=== Service Status ==="
          sudo systemctl status "$SERVICE_NAME" --no-pager -l
          echo ""
          echo "=== Recent Logs ==="
          sudo journalctl -u "$SERVICE_NAME" --no-pager -n 20
          ;;
        run-now)
          echo "Running dotfiles auto-update immediately..."
          sudo systemctl start "$SERVICE_NAME"
          echo "Check logs with: dotfiles-auto-update-ctl logs"
          ;;
        logs)
          echo "=== Recent Auto-update Logs ==="
          sudo journalctl -u "$SERVICE_NAME" --no-pager -n ''${2:-50} -f
          ;;
        *)
          echo "Usage: $0 {enable|disable|status|run-now|logs [lines]}"
          echo ""
          echo "Commands:"
          echo "  enable    - Enable and start auto-update timer"
          echo "  disable   - Disable and stop auto-update timer"
          echo "  status    - Show current status and recent logs"
          echo "  run-now   - Trigger an immediate update check"
          echo "  logs [N]  - Show last N log lines (default: 50)"
          exit 1
          ;;
      esac
    '')
  ];

  # Allow specific unfree packages (same as nix-darwin)
  nixpkgs.config.allowUnfree = true;
  # nixpkgs.config.allowUnfreePredicate =
  #   pkg:
  #   builtins.elem (lib.getName pkg) [
  #     "@anthropic-ai/claude-code"  # Commented out - install manually if needed
  #   ];

  # Enable flakes (same as nix-darwin)
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Configure the default user
  users.users.rictic = {
    isNormalUser = true;
    home = "/home/rictic";
    description = "Peter Burns";
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    shell = pkgs.zsh;
  };

  # Enable sudo for wheel group
  security.sudo.wheelNeedsPassword = false;

  # Enable zsh system-wide
  programs.zsh.enable = true;

  # Enable git system-wide
  programs.git.enable = true;

  # Enable NixOS compatibility for VS Code server and other dynamically linked executables
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # Add common libraries that VS Code server might need
    stdenv.cc.cc.lib
    zlib
    openssl
    curl
    expat
    libxml2
    libxcrypt-legacy
  ];

  # Docker support (useful for development in WSL)
  # Uncomment the following lines if you need Docker support
  #virtualisation.docker = {
  #  enable = true;
  #  enableOnBoot = true;
  #};

  # Auto-update system for dotfiles
  # Set to false to disable auto-updates
  environment.etc."dotfiles-auto-update.conf".text = ''
    DOTFILES_AUTO_UPDATE_ENABLED=true
    DOTFILES_PATH=/home/rictic/open/dotfiles
    DOTFILES_BRANCH=main
    LOG_LEVEL=info
  '';

  systemd.services.dotfiles-auto-update = {
    description = "Auto-update dotfiles configuration";
    path = with pkgs; [ git nix nixos-rebuild coreutils ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      WorkingDirectory = "/home/rictic/open/dotfiles";
      StandardOutput = "journal";
      StandardError = "journal";
      ExecStart = pkgs.writeShellScript "dotfiles-auto-update.sh" ''
        set -euo pipefail
        
        # Load configuration
        source /etc/dotfiles-auto-update.conf
        
        # Check if auto-update is enabled
        if [ "$DOTFILES_AUTO_UPDATE_ENABLED" != "true" ]; then
          echo "Auto-update is disabled in /etc/dotfiles-auto-update.conf"
          exit 0
        fi
        
        # Change to dotfiles directory
        cd "$DOTFILES_PATH"
        
        log() {
          echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
        }
        
        log "Starting dotfiles auto-update check..."
        
        # Check if we have any local changes
        if ! git diff --quiet HEAD; then
          log "Local changes detected, skipping auto-update"
          exit 0
        fi
        
        if ! git diff --quiet --cached; then
          log "Staged changes detected, skipping auto-update"
          exit 0
        fi
        
        # Fetch latest changes with timeout
        log "Fetching latest changes..."
        timeout 30 git fetch origin || {
          log "Failed to fetch from origin (timeout or network error)"
          exit 1
        }
        
        # Check if there are new commits
        LOCAL=$(git rev-parse HEAD)
        REMOTE=$(git rev-parse "origin/$DOTFILES_BRANCH")
        
        if [ "$LOCAL" = "$REMOTE" ]; then
          log "No updates available"
          exit 0
        fi
        
        log "Updates found ($(git rev-list --count HEAD..origin/$DOTFILES_BRANCH) commits), pulling changes..."
        git pull origin "$DOTFILES_BRANCH"
        
        # Create a backup reference
        BACKUP_REF="backup-before-auto-update-$(date +%s)"
        git tag "$BACKUP_REF" "$LOCAL"
        log "Created backup tag: $BACKUP_REF"
        
        # Test the flake
        log "Testing flake validity..."
        if ! nix flake check; then
          log "Flake check failed, rolling back..."
          git reset --hard "$LOCAL"
          git tag -d "$BACKUP_REF"
          exit 1
        fi
        
        # Test build (dry-run)
        log "Testing NixOS build..."
        if ! nixos-rebuild dry-build --flake .#nixos-wsl; then
          log "Build test failed, rolling back..."
          git reset --hard "$LOCAL"
          git tag -d "$BACKUP_REF"
          exit 1
        fi
        
        # If tests pass, apply the changes
        log "Tests passed, applying changes..."
        if nixos-rebuild switch --flake .#nixos-wsl; then
          log "Auto-update completed successfully"
          # Clean up old backup tags (keep last 5)
          git tag -l "backup-before-auto-update-*" | sort -V | head -n -5 | xargs -r git tag -d
        else
          log "Failed to apply changes, system may be in inconsistent state"
          log "Backup tag available: $BACKUP_REF"
          exit 1
        fi
      '';
    };
    # Only run if the dotfiles directory exists and git is available
    unitConfig = {
      ConditionPathExists = [ "/home/rictic/open/dotfiles" "/home/rictic/open/dotfiles/.git" ];
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
}
