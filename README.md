# make-shell

A modular almost-drop-in replacement for [the mkShell ("em-kay shell") function](https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-mkShell).

## "modular?"

I can't define nix modules any better than [nix.dev's excellent quick introduction](https://nix.dev/tutorials/module-system/a-basic-module/):

> - A module is a function that takes an attribute set and returns an attribute set.
> - It may declare options, telling which attributes are allowed in the final outcome.
> - It may define values, for options declared by itself or other modules.
> - When evaluated by the module system, it produces an attribute set based on the declarations and definitions.

`make-shell` evaluates its argument as a module, using [`lib.evalModules` from nixpkgs](https://nixos.org/manual/nixpkgs/unstable/#module-system-lib-evalModules), passes the result attribute set to [`mkShell`](https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-mkShell), and returns the result: a derivation suitable for use as a shell environment with `nix develop`.

If you're wondering whether you can benefit from this, check [this repository's WHY file](WHY.md).

## Installation

This repository is a nix flake with an overlay output that adds make-shell to a nixpkgs set.  It also has a flake module output which can be used with [flake-parts](https://flake.parts/), which lets you write your flakes using modules!).  You can use either to make `make-shell` available to your flake.

Either way, start by adding this flake to the inputs of your flake:
```nix
    inputs.make-shell.url = "github:nicknovitski/make-shell";
```

Then, to define a `devShells.default` flake output with the overlay:
```nix
  outputs = {
    nixpkgs,
    flake-utils,
    make-shell,
    ...,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config = {};
        overlays = [make-shell.overlays.default];
      };
    in {
      devShells.default = pkgs.make-shell {
        packages = [pkgs.curl pkgs.git pkgs.jq pkgs.wget];
      };
    });
```
To do the same thing with the flake module instead:
```nix
  outputs = inputs@{
    nixpkgs,
    flake-parts,
    make-shell,
    ...,
  }:
    flake-parts.lib.mkFlake {inherit inputs;} (_: {
      imports = [make-shell.flakeModules.default];
      systems = [ "aarch64-darwin" "aarch64-linux" "x86_64-darwin" "x86_64-linux" ];
      perSystem = {...}: {
        make-shells.default = {pkgs, ...}: {
          packages = [pkgs.curl pkgs.git pkgs.jq pkgs.wget];
        };
      };
    });
```

## Usage

`make-shell` has one parameter: a shell module.  A shell module is either an attribute set of shell options, or a function with an attribute set parameter which returns an attribute set of shell options. The parameters and options are documented in [SHELL_MODULES.md](SHELL_MODULES.md).

> *If you're using flake-parts*, the flake module options, which include all the shell module options, are also [documented on the flake.parts site](https://flake.parts/options/make-shell).

The most common attributes used with `mkShell` are also valid Shell Options!  That means that `make-shell` can often be a drop-in replacement for `mkShell`.  When it isn't, there's only two possible changes you need to make:

### `mkShell` arguments which are intended to be environment variables in the shell environment should be changed to attributes of the `env` option

For example:
```nix
pkgs.mkShell { GRADLE_OPTS = "-Dorg.gradle.appname="; } == pkgs.make-shell { env.GRADLE_OPTS = "-Dorg.gradle.appname="; }
```

### Arbitrary mkDerivation arguments should be changed to be attributes of the `additionalArguments` option

For example:
```nix
let
  args = {
    doCheck = true;
    phases = [ "buildPhase" "checkPhase" ];
    checkPhase = "echo seems fine!";
  };
in pkgs.mkShell args == pkgs.make-shell { additionalArguments = args; }
```
