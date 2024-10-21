{ config, lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options = {
    env = mkOption {
      default = { };
      description = ''
        An attribute set to control environment variables in the shell environment.

        If the value of an attribute is `null`, the variable of that attribute's name is `unset`.  Otherwise the variable of the attribute name is set to the attribute's value.  Integer, path, and derivation values are converted to strings.  The boolean true value is converted to the string `"1"`, and the boolean false value is converted to the empty string `""`.
      '';
      example = lib.literalExpression ''
        {
          VARIABLE_NAME = "variable value";
          UNSET = null;
          EMPTY = false;
          TWO = 2;
          PATH_TO_NIX_STORE_FILE = ./my-file;
          COWSAY = pkgs.cowsay
        }
      '';
      type = types.attrsOf (
        types.nullOr (
          types.oneOf [
            types.bool
            types.int
            types.package
            types.path
            types.str
          ]
        )
      );
    };
    finalEnv = mkOption {
      readOnly = true;
      internal = true;
      # mkShell.env values can be derivations, strings, booleans or integers.
      # path and null values are separated for special handling.
      type = types.attrsOf (
        types.oneOf [
          types.bool
          types.int
          types.str
          types.package
        ]
      );
      default =
        let
          inherit (builtins) isPath toString;
          inherit (lib.attrsets) filterAttrs mapAttrs;
          simpleEnv = filterAttrs (_: v: !(v == null || isPath v)) config.env;
          pathEnv = filterAttrs (_: isPath) config.env;
        in
        simpleEnv // mapAttrs (_: toString) pathEnv;
    };
  };
  config =
    let
      inherit (builtins) attrNames concatStringsSep;
      inherit (lib) mkIf;
      inherit (lib.attrsets) filterAttrs;
      envVarsToUnset = attrNames (filterAttrs (_: v: v == null) config.env);
    in
    mkIf (envVarsToUnset != [ ]) {
      shellHook = "unset ${concatStringsSep " " envVarsToUnset}";
    };
}
