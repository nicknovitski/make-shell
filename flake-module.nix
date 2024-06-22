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
    } @ args: {
      options.make-shells = lib.mkOption {
        description = "Creates devShells and checks with make-shell";
        default = {};
        type = let
          inherit (lib.types) attrsOf submoduleWith;
        in
          attrsOf (submoduleWith {
            specialArgs = specialArgs // {inherit inputs self;};
            modules = [
              {_module = {inherit args;};}
              (import ./shell-module.nix)
            ];
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
