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
      description = "Name of the shell environment package.";
      type = types.str;
    };
    function = mkOption {
      default = pkgs.mkShell;
      example = lib.literalExpression "pkgs.mkShellNoCC";
      defaultText = lib.literalExpression "pkgs.mkShell";
      description = "Function which the final evaluated config will be passed to, returning a shell derivation.";
      type = types.functionTo types.package;
    };
    finalPackage = mkOption {
      description = "The shell environment resulting from passing evaluated module configuration to the package-making function.";
      readOnly = true;
      type = types.package;
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
      description = "Arbitrary additional arguments passed to the function";
      type = types.attrsOf types.anything;
    };
  };
  config.finalPackage = config.function (
    lib.recursiveUpdate {
      inherit (config) name packages inputsFrom shellHook;
      env = config.finalEnv;
    }
    config.additionalArguments
  );
}
