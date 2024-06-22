{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption types;
in {
  options = {
    name = mkOption {
      default = "nix-shell";
      type = types.str;
      description = "Name of the shell environment";
    };
    finalPackage = mkOption {
      type = types.package;
      readOnly = true;
      description = "Resulting shell environment package.";
    };
    env = mkOption {
      default = {};
      description = "Environment variables set in the shell environment.";
      type = let
        one = [types.bool types.int types.str types.path types.package];
        listOrOne = one ++ [(types.listOf (types.oneOf one))];
      in
        types.attrsOf (types.nullOr (types.oneOf listOrOne));
    };
    shellHook = mkOption {
      default = "";
      description = "Bash code evaluated when the shell environment starts.";
      type = types.lines;
    };
    packages = mkOption {
      default = [];
      description = "Packages available in the shell environment";
      type = types.listOf types.package;
    };
    inputsFrom = mkOption {
      default = [];
      description = "Packages whose inputs are available in the shell environment";
      type = types.listOf types.package;
    };
    extraArgs = mkOption {
      default = {};
      description = "Arbitrary additional arguments passed to mkShell";
      type = types.attrs;
    };
  };
  config.finalPackage = pkgs.mkShell (
    lib.recursiveUpdate
    {inherit (config) env name packages inputsFrom shellHook;}
    config.extraArgs
  );
}
