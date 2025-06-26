#!/bin/bash
set -euo pipefail

# Source configuration
source /etc/dotfiles-auto-update.conf

# Check if auto-update is enabled
if [ "${DOTFILES_AUTO_UPDATE_ENABLED:-true}" != "true" ]; then
  echo "Auto-update is disabled, skipping..."
  exit 0
fi

# Set defaults
DOTFILES_PATH="${DOTFILES_PATH:-/etc/dotfiles}"
DOTFILES_SOURCE_PATH="${DOTFILES_SOURCE_PATH:-/home/rictic/open/dotfiles}"
DOTFILES_REMOTE="${DOTFILES_REMOTE:-https://github.com/rictic/dotfiles.git}"
DOTFILES_BRANCH="${DOTFILES_BRANCH:-main}"
LOG_LEVEL="${LOG_LEVEL:-info}"

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
