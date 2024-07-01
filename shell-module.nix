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
      description = "Name of the shell environment package.";
    };
    finalPackage = mkOption {
      type = types.package;
      readOnly = true;
      description = "The resulting shell environment package.";
    };
    env = mkOption {
      default = {};
      description = ''
        An attribute set to control environment variables in the shell environment.

        If the value of an attribute is `null`, the variable of the matching name is `unset`.  Otherwise the variable of the attribute name is set to the attribute's value.  Integer, path, and derivation values are converted to strings.  The boolean true value is converted to the string `"1"`, and the boolean false value is converted to the empty string.
      '';
      type = types.attrsOf (types.nullOr (types.oneOf [types.bool types.int types.str types.path types.package]));
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
  config.finalPackage = let
    inherit (builtins) attrNames isPath toString;
    inherit (lib.attrsets) filterAttrs mapAttrs;
    # mkShell.env values can be derivations, strings, booleans or integers.
    # path and null values are separated for special handling.
    simpleEnv = filterAttrs (_: v: !(v == null || isPath v)) config.env;
    pathEnv = filterAttrs (_: isPath) config.env;
    envVarsToUnset = attrNames (filterAttrs (_: v: v == null) config.env);
    env = simpleEnv // mapAttrs (_: toString) pathEnv;
  in
    pkgs.mkShell (
      lib.recursiveUpdate
      {
        inherit env;
        inherit (config) name packages inputsFrom;
        shellHook = config.shellHook + "\nunset ${lib.concatStringsSep " " envVarsToUnset}";
      }
      config.additionalArguments
    );
}
