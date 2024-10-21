{
  description = "A simple flake using the make-shell overlay";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    make-shell.url = "github:nicknovitski/make-shell";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      make-shell,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = { };
          overlays = [ make-shell.overlays.default ];
        };
      in
      {
        devShells.default = pkgs.make-shell {
          packages = [
            pkgs.curl
            pkgs.git
            pkgs.jq
            pkgs.wget
          ];
        };
      }
    );
}
