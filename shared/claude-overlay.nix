# Claude Code overlay shared between nix-darwin and NixOS
# This creates a custom package for claude-code that can be used on both platforms
final: prev: {
  claude-code-latest = prev.stdenv.mkDerivation rec {
    pname = "@anthropic-ai/claude-code";
    version = "1.0.25";

    src = prev.fetchurl {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
      hash = "sha512-5p4FLlFO4TuRf0zV0axiOxiAkUC8eer0lqJi/A/pA46LESv31Alw6xaNYgwQVkP6oSbP5PydK36u7YrB9QSaXQ==";
    };

    buildInputs = [ prev.nodejs ];
    nativeBuildInputs = prev.lib.optionals prev.stdenv.isLinux [ prev.dos2unix ];

    postUnpack = prev.lib.optionalString prev.stdenv.isLinux ''
      find . -type f -name "*.js" -o -name "*.json" -o -name "*.md" | xargs dos2unix
    '';

    installPhase = ''
      mkdir -p $out/bin
      mkdir -p $out/lib/node_modules/@anthropic-ai/claude-code

      # Copy the entire package to the lib directory
      cp -r . $out/lib/node_modules/@anthropic-ai/claude-code/

      # Find the actual binary file
      if [ -f cli.js ]; then
        BINARY_FILE="cli.js"
      elif [ -f index.js ]; then
        BINARY_FILE="index.js"
      elif [ -f bin/claude ]; then
        BINARY_FILE="bin/claude"
      else
        echo "Could not find binary file"
        find . -name "*.js" -type f
        exit 1
      fi

      # Create the binary symlink
      ln -s $out/lib/node_modules/@anthropic-ai/claude-code/$BINARY_FILE $out/bin/claude

      # Make sure the binary is executable
      chmod +x $out/lib/node_modules/@anthropic-ai/claude-code/$BINARY_FILE
    '';

    meta = with prev.lib; {
      description = "Agentic coding tool that lives in your terminal";
      homepage = "https://github.com/anthropics/claude-code";
      license = licenses.unfree;
      platforms = platforms.unix;
    };
  };
}
