{
  description = "mkShell meets modules";

  inputs = {
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;
  };

  outputs = _: {
    flakeModule = builtins.trace "[1;31mUse `flakeModules.default` instead of `flakeModule`[0" ./flake-module.nix;
    flakeModules.default = ./flake-module.nix;
    overlays.default = final: prev: {
      make-shell = module:
        (prev.lib.evalModules {
          modules = [
            ./shell-modules/default.nix
            {config._module.args.pkgs = final;}
            module
          ];
        })
        .config
        .finalPackage;
    };
    templates = {
      default = {
        description = "Example using the make-shell overlay";
        path = builtins.path {
          path = ./examples/flake;
          filter = path: _: baseNameOf path == "flake.nix";
        };
      };
      flake-parts = {
        description = "Example using the make-shell flake module with flake-parts";
        path = builtins.path {
          path = ./examples/flake-parts;
          filter = path: _: baseNameOf path == "flake.nix";
        };
      };
      full = {
        description = "Example demonstrating many make-shell features";
        path = builtins.path {
          path = ./examples/flake-parts;
          filter = path: _: baseNameOf path == "flake.nix";
        };
      };
    };
  };
}
