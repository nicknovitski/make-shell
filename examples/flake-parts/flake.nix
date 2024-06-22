{
  description = "A simple flake using the make-shell flake module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    make-shell.url = "github:nicknovitski/make-shell";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} (_: {
      imports = [inputs.make-shell.flakeModules.default];
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      perSystem = {...}: {
        make-shells.default = {pkgs, ...}: {
          packages = [pkgs.curl pkgs.git pkgs.jq pkgs.wget];
        };
      };
    });
}
