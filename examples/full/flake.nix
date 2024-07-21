{
  description = "A sample flake demonstrating make-shell features";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    make-shell.url = "github:nicknovitski/make-shell";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} (_: {
      imports = [inputs.make-shell.flakeModules.default];
      systems = ["x86_64-linux" "aarch64-darwin"];
      flake.lib.emphasize = s: s + "!"; # see env.GREETINGS, below
      perSystem = {pkgs, ...}: {
        packages.default = pkgs.hello; # see inputsFrom, below
        make-shells.default = {
          shellHook = "echo $GREETINGS";
          stdenv = pkgs.stdenvNoCC; # a slightly stripped-down environment
          # Import and merge modules!
          imports = [
            # Refer to your flake's outputs!
            ({self, ...}: {env.GREETINGS = self.lib.emphasize "Hello from a merged shell";})
            # Refer to your flake's perSystem outputs with `self'`!
            ({self', ...}: {inputsFrom = [self'.packages.default];})
            # Refer to your flake's inputs!
            ({inputs, ...}: {env.FLAKE_PARTS_REV = inputs.flake-parts.rev;})
            # Refer to the results of other modules!
            ({
              config,
              lib,
              ...
            }: {
              shellHook = ''
                echo Packages provided:
                echo "${lib.strings.concatMapStringsSep "\n" (pkg: pkg.name + ": " + pkg.meta.description or "") config.packages}"
                echo
              '';
            })
            # Declare your own options!
            ({
              config,
              lib,
              pkgs,
              ...
            }: {
              options.nix-packages.enable = lib.mkEnableOption "Add some packages for working with nix!";
              config = lib.mkIf config.nix-packages.enable {
                packages = [pkgs.alejandra pkgs.deadnix pkgs.statix];
              };
            })
            # And then define them!
            {nix-packages.enable = true;}
            # How about something fancier?
            ({
              config,
              lib,
              pkgs,
              ...
            }: {
              # For each `aliases.<name> = "<string>"...
              options.aliases = lib.mkOption {
                type = lib.types.attrsOf lib.types.singleLineStr;
                default = {};
              };
              # ...add a shell script <name> with the contents "<string>"
              config.packages = let
                inherit (lib.attrsets) mapAttrsToList;
                alias = name: command: (pkgs.writeShellScriptBin name ''exec ${command} "$@"'') // {meta.description = "alias for '${command}'";};
              in
                mapAttrsToList alias config.aliases;
            })
            # Now we can make some aliases!
            {
              aliases = {
                n = "nix";
                g = "git";
              };
            }
          ];
        };
      };
    });
}
