{lib, ...}: let
  packageOption = description:
    lib.mkOption {
      inherit description;
      default = [];
      type = lib.types.listOf lib.types.package;
    };
in {
  options = lib.mapAttrs (_: desc: packageOption desc) {
    inputsFrom = "Packages whose inputs are available in the shell environment.";
    nativeBuildInputs = "Packages available in the shell environment.";
    packages = "Packages available in the shell environment. An alias of `nativeBuildInputs`";
  };
}
