#!/bin/bash
set -euo pipefail

CONFIG_FILE="/etc/dotfiles-auto-update.conf"
SERVICE_NAME="dotfiles-auto-update"
TIMER_NAME="$SERVICE_NAME.timer"
ROOT_DOTFILES_PATH="/etc/dotfiles"

case "${1:-}" in
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
    LINES="${2:-50}"
    if [ "${2:-}" = "-f" ] || [ "${2:-}" = "--follow" ]; then
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
