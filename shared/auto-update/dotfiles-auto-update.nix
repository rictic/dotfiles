# Dotfiles auto-update module
# This module provides automatic dotfiles synchronization and system updates
{
  config,
  pkgs,
  lib,
  inputs ? { },
  ...
}:

with lib;

let
  cfg = config.services.dotfiles-auto-update;

  # Control script for managing the auto-updater
  controlScript = pkgs.writeShellScriptBin "dotfiles-auto-update-ctl" (
    builtins.readFile ./dotfiles-auto-update-ctl.sh
  );

  # Main auto-update service script
  updateScript = pkgs.writeShellScript "dotfiles-auto-update" (
    builtins.readFile ./dotfiles-auto-update.sh
  );

  # Get the git revision of the dotfiles repo from flake inputs
  # Fail if inputs aren't properly configured rather than hiding the problem
  dotfilesGitRev = 
    if !(inputs ? self) then
      builtins.throw "inputs.self is missing - ensure specialArgs = { inherit inputs; } is set in your flake configuration"
    else if !(inputs.self ? rev) then
      # During flake check or when working with dirty git tree, rev might not be available
      # Use lastModified or outPath as fallback, but make it clear this isn't a real git SHA
      if (inputs.self ? lastModified) then
        "dirty-${toString inputs.self.lastModified}"
      else if (inputs.self ? outPath) then
        "local-${builtins.substring 0 7 (builtins.hashString "sha256" (toString inputs.self.outPath))}"
      else
        builtins.throw "inputs.self has no rev, lastModified, or outPath - this shouldn't happen"
    else
      inputs.self.rev;

  # Hello server demo script with git SHA
  helloServerScript = pkgs.writeShellScript "hello-server" ''
    export DOTFILES_GIT_SHA="${dotfilesGitRev}"
    exec ${pkgs.python3}/bin/python3 ${./hello-server.py}
  '';

  # Default configuration content
  defaultConfig = ''
    # Dotfiles auto-update configuration
    DOTFILES_AUTO_UPDATE_ENABLED=${if cfg.enable then "true" else "false"}
    DOTFILES_PATH=${cfg.dotfilesPath}
    DOTFILES_SOURCE_PATH=${cfg.sourcePath}
    DOTFILES_REMOTE=${cfg.remote}
    DOTFILES_BRANCH=${cfg.branch}
    LOG_LEVEL=${cfg.logLevel}

    # Flake configuration name (will be detected automatically if not set)
    ${optionalString (cfg.flakeConfig != null) "FLAKE_CONFIG=${cfg.flakeConfig}"}
  '';

in
{
  options.services.dotfiles-auto-update = {
    enable = mkEnableOption "dotfiles auto-update service";

    dotfilesPath = mkOption {
      type = types.str;
      default = "/etc/dotfiles";
      description = "Path where the root-owned dotfiles repository will be stored";
    };

    sourcePath = mkOption {
      type = types.str;
      default = "/home/rictic/open/dotfiles";
      description = "Source path for reference (user's dotfiles directory)";
    };

    remote = mkOption {
      type = types.str;
      default = "https://github.com/rictic/dotfiles.git";
      description = "Git remote URL for the dotfiles repository";
    };

    branch = mkOption {
      type = types.str;
      default = "main";
      description = "Git branch to track";
    };

    logLevel = mkOption {
      type = types.str;
      default = "info";
      description = "Logging level for the auto-update service";
    };

    flakeConfig = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Flake configuration name (will be auto-detected if not set)";
    };

    interval = mkOption {
      type = types.str;
      default = "5min";
      description = "How often to check for updates";
    };

    onBootDelay = mkOption {
      type = types.str;
      default = "5min";
      description = "Delay before first run after boot";
    };

    enableHelloServer = mkOption {
      type = types.bool;
      default = false;
      description = "Enable the demo hello server";
    };

    helloServerPort = mkOption {
      type = types.int;
      default = 9876;
      description = "Port for the hello server";
    };
  };

  config = mkIf cfg.enable {
    # Add the control script to system packages
    environment.systemPackages = [ controlScript ];

    # Configuration file
    environment.etc."dotfiles-auto-update.conf".text = defaultConfig;

    # Auto-update service
    systemd.services.dotfiles-auto-update = {
      description = "Auto-update dotfiles configuration";
      after = [ "network.target" ];
      wants = [ "network.target" ];

      script = "${updateScript}";

      serviceConfig = {
        Type = "oneshot";
        User = "root";
        Group = "root";
        # Ensure git and other necessary commands are available
        Environment = "PATH=${pkgs.git}/bin:${pkgs.nixos-rebuild}/bin:${pkgs.nix}/bin:/run/current-system/sw/bin";
        # Restart on failure after 1 minute
        Restart = "on-failure";
        RestartSec = "60";
      };
    };

    # Timer to run the auto-update
    systemd.timers.dotfiles-auto-update = {
      description = "Timer for dotfiles auto-update";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = cfg.onBootDelay;
        OnUnitActiveSec = cfg.interval;
        Persistent = true; # Run missed timers on boot
      };
    };

    # Optional hello server for demonstration
    systemd.services.hello-server = mkIf cfg.enableHelloServer {
      description = "Simple HTTP server saying hello from hostname";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = "rictic";
        WorkingDirectory = "/home/rictic";
        ExecStart = "${helloServerScript}";
        Restart = "always";
        RestartSec = "5";
      };
    };
  };
}
