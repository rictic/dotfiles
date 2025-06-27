# nix-darwin system configuration
{ pkgs, lib, ... }:

let
  commonSystemPackages = import ../shared/common-system-packages.nix { inherit pkgs; };
in
{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = commonSystemPackages ++ [
    pkgs.claude-code-latest
  ];

  # Allow specific unfree packages
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "@anthropic-ai/claude-code"
    ];

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Enable alternative shell support in nix-darwin.
  # programs.fish.enable = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.rictic.home = "/Users/rictic";
}
