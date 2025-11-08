{ config, lib, ... }:
let
  inherit (lib) mkOption types;
  singleType = types.nullOr (
    types.oneOf [
      types.bool
      types.int
      types.package
      types.path
      types.str
    ]
  );
in
{
  options = {
    env = mkOption {
      default = { };
      description = ''
        An attribute set to control environment variables in the shell environment.

        If the value of an attribute is `null`, the variable of that attribute's name is `unset`.  Otherwise the variable of the attribute name is set to the attribute's value.  Integer, path, and derivation values are converted to strings.  The boolean true value is converted to the string `"1"`, and the boolean false value is converted to the empty string `""`.

        Multiple declarations for the same environment variable are allowed.
        The merge strategy can be configured via the `envStrategies` option.
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
      type = types.attrsOf (types.coercedTo singleType (v: [ v ]) (types.listOf singleType));
    };

    envStrategies = mkOption {
      default = {
        LD_LIBRARY_PATH = {
          strategy = "append";
          separator = ":";
        };
      };
      description = "Merge strategies for environment variables with multiple definitions.";
      example = lib.literalExpression ''
        {
          PATH = {
            strategy = "append";
            separator = ":";
          };
        }
      '';
      type = types.attrsOf (
        types.submodule {
          options = {
            strategy = mkOption {
              type = types.enum [
                "append"
                "error"
              ];
              default = "error";
              description = "Merge strategy: 'append' or 'error' (default).";
            };
            separator = mkOption {
              type = types.str;
              default = ":";
              description = "Separator for 'append' strategy.";
            };
          };
        }
      );
    };

    mergedEnv = mkOption {
      internal = true;
      readOnly = true;
      default = lib.mapAttrs (
        name: values:
        let
          cfg = config.envStrategies.${name} or { };
          strategy = cfg.strategy or "error";
          separator = cfg.separator or ":";
          isUnset = (lib.last values) == null;
          definedValues = lib.filter (v: v != null) values;
        in
        if isUnset then
          null
        else if builtins.length definedValues > 1 && strategy == "error" then
          throw "The environment variable '${name}' has multiple definitions. Please specify a merge strategy using 'envStrategies.${name}.strategy'."
        else if strategy == "append" then
          lib.concatStringsSep separator (map builtins.toString definedValues)
        # strategy is "error" with 0 or 1 value
        else
          lib.last definedValues
      ) config.env;
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
          simpleEnv = filterAttrs (_: v: !(v == null || isPath v)) config.mergedEnv;
          pathEnv = filterAttrs (_: isPath) config.mergedEnv;
        in
        simpleEnv // mapAttrs (_: toString) pathEnv;
    };
  };
  config =
    let
      inherit (builtins) attrNames concatStringsSep;
      inherit (lib) mkIf;
      inherit (lib.attrsets) filterAttrs;
      envVarsToUnset = attrNames (filterAttrs (_: v: v == null) config.mergedEnv);
    in
    mkIf (envVarsToUnset != [ ]) {
      shellHook = "unset ${concatStringsSep " " envVarsToUnset}";
    };
}
