{
  flake-parts-lib,
  inputs,
  self,
  specialArgs,
  ...
}: let
  inherit
    (flake-parts-lib)
    mkPerSystemOption
    ;
in {
  options.perSystem = mkPerSystemOption ({
      config,
      lib,
      options,
      pkgs,
      self',
      ...
    } @ args: let
      inherit (lib.types) attrsOf listOf submoduleWith raw;
    in {
      options.make-shell.sharedModules = lib.mkOption {
        description = "Modules to import into all shells created using `make-shells`";
        default = [];
        type = listOf raw;
      };
      options.make-shells = lib.mkOption {
        description = "For each attribute in this set, make-shell is called with the value, and the resulting package is added to the flake as a devShell attribute with the same name, and a check attribute the same name to the flake, and check named \${attribute name}-devshell with the devShell as its value.";
        default = {};
        type = attrsOf (submoduleWith {
          specialArgs = specialArgs // {inherit inputs self;};
          modules =
            [
              {_module = {inherit args;};}
              ./shell-module.nix
            ]
            ++ config.make-shell.sharedModules;
        });
      };
      config = {
        devShells = lib.mapAttrs (name: cfg: cfg.finalPackage.overrideAttrs {name = "${name}-shell";}) config.make-shells;
        checks =
          lib.mapAttrs' (name: cfg: {
            name = "${name}-shell";
            value = cfg.finalPackage;
          })
          config.make-shells;
      };
    });
}
