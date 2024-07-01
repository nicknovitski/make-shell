{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption types;
in {
  imports = [./env.nix];
  options = {
    name = mkOption {
      default = "nix-shell";
      type = types.str;
      description = "Name of the shell environment package.";
    };
    finalPackage = mkOption {
      type = types.package;
      readOnly = true;
      description = "The resulting shell environment package.";
    };
    shellHook = mkOption {
      default = "";
      description = "Bash code evaluated when the shell environment starts.";
      type = types.lines;
    };
    packages = mkOption {
      default = [];
      description = "Packages available in the shell environment.";
      type = types.listOf types.package;
    };
    inputsFrom = mkOption {
      default = [];
      description = "Packages whose inputs are available in the shell environment.";
      type = types.listOf types.package;
    };
    additionalArguments = mkOption {
      default = {};
      description = "Arbitrary additional arguments passed to mkShell";
      type = types.attrsOf types.anything;
    };
  };
  config.finalPackage = pkgs.mkShell (
    lib.recursiveUpdate {
      inherit (config) name packages inputsFrom shellHook;
      env = config.finalEnv;
    }
    config.additionalArguments
  );
}
