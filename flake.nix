{
  description = "My personal development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Development tools
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

            # Shell utilities
            zsh
            starship
            direnv
          ];

          shellHook = ''
            eval "$(starship init bash)"
          '';
        };
      });
}
