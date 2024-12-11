# Shell Modules

A Shell Module is either an attribute set of shell options, or a function which has a single attribute set parameter and returns an attribute set of shell options.

## Parameters

If you write your modules as a function, these are the attributes in the set it is passed.

### `options`

The combined set of option declarations in the modules being evaluated.  You don't need this very often.

### `config`

The final evaluated set of option definitions.  You need this if you want to conditionally define otions depending on other options.  See the section on the `options` option below for a longer explanation, including an example.

### `pkgs`

The nixpkgs package set which `make-shell` is using.  You need this if you want to add packages to the shell environment, or refer to them in another way.

### `lib`

The `lib` attribute of the `pkgs` parameter.  You need this if you want to use [any of the functions in lib](https://nixos.org/manual/nixpkgs/stable/#id-1.4).  You could also use the `pkgs` parameter and write `pkgs.lib` everywhere instead, but I don't know why you would.

### `inputs` (flake-parts only)

The inputs set of the flake.  You need this if you want to reference one of the outputs of your inputs.  This may not happen very often.  Maybe if a flake exposed a `lib` output you wanted to use?

### `self` and `self'` (flake-parts only)

These are both the attribute set of the flake's outputs, but the trailing `'`, pronounced "prime", only includes the outputs for the system currently being evaluated.

For example, on my M1 Macbook:
```nix
self.packages.aarch64-darwin.default == self'.packages.default.
```

You'll need this if your flake defines outputs that you'd like to have in your devShell.  If your flake has `lib` outputs, you can use them with `self.lib`. If your flake has packages outputs, you can add all their build dependencies tersely using the `inputsFrom` option.

Like this:
```nix
outputs = inputs:
  inputs.flake-parts.lib.mkFlake {inherit inputs;} (_: {
    imports = [inputs.make-shell.flakeModules.default];
    systems = ["x86_64-linux" "aarch64-darwin"];
    flake.lib.emphasize = s: s + "!"; # add a lib output
    perSystem = {pkgs, ...}: {
      packages.default = pkgs.hello; # add some perSystem packages outputs
      make-shells.default = {
        shellHook = "echo $GREETINGS";
        imports = [
          ({self, ...}: {env.GREETINGS = self.lib.emphasize "Hello from a merged shell";}) # self.lib
          ({self', ...}: {inputsFrom = [self'.packages.default];}) # self'.packages
        ];
```

## Basic Options

These options correspond with common `mkShell` parameters.

### `env` : Attribute Set of Strings (or things easily converted to strings)

When you add attributes to this set, environment variables with matching names and values are present in the shell.  `true` is converted to the string `"1"`, and `false` is converted to the empty string `""`.

This differs from the `mkShell` and `mkDerivation` parameter of the same name in two ways:
- If the attribute value is `null`, `mkShell` errors, but `make-shell` `unset`s the environment variable of that name
- If the attribute value is a path, `mkShell` errors, but `make-shell` converts the path to a string

Multiple definitions of this option are merged.  If attributes of the same name are defined multiple times, evaluation errors.

### `nativeBuildInputs`: Array of Derivations

When you add packages to this, they are present in the shell.  This means several things, including that any `bin` outputs are present in the `PATH` variable.

Multiple definitions of this option are concatenated.

### `packages`: Array of Derivations

As with the `mkShell` parameters of the same names, this option has identical behavior to `nativeBuildInputs`.

### `inputsFrom`: Array of Derivations

When you add derivations to this, their build and runtime dependencies are present in the shell.

Multiple definitions of this option are concatenated.

### `shellHook`: String

This string is evaluated by bash when the shell starts.

Multiple definitions of this option are concatenated, separated by newline characters.

### `name`: String

The name of the shell environment package.

If this option is defined multiple times, evaluation errors.

### `additionalArguments`: Attribute Set

Arbitrary arguments to pass to the function creating the shell environment package.

Multiple definitions of this option are merged.  If attributes of the same name are defined multiple times, evaluation errors.

## Module Options

### `stdenv`: [The standard build environment](https://nixos.org/manual/nixpkgs/stable/#chap-stdenv), or something similar to it

`make-shell` passes the final evaluated module configuration to the `stdenv.mkDerivation` function, and returns whatever that returns.  You can change this to `pkgs.stdenvNoCC`, or any other standard environment variation you like.

If this option is defined multiple times, evaluation errors.

### `imports`: Array of Shell Modules

All modules in this array are evaluated and merged with the top-level definitions.

Multiple definitions of this option are concatenated.

### `config`: Attribute Set of Option Definitions

You can nest an option definition in this set, and it will have the same effect as keeping it at the "top level".

For example:
```nix
pkgs.make-shell { packages = [pkgs.git]; } == pkgs.make-shell { config.packages = [pkgs.git]; }
```

So when would you use `config`?  When you want to _conditionally_ add to the configuration.  You can do that by either returning an empty `config` set, or one with an option set in it, which you can and you need to return either an empty `config` option, or one with a value set in it.

```
# include macvim if building on MacOS
pkgs.make-shell {
  config = if pkgs.stdenv.hostPlatform.isDarwin {packages = [pkgs.macvim];} else {};
}
```

But most usefully, a module can define options on `config` _depending on the definitions of other options_.  Read the next section to see the whys and hows of this.

Multiple definitions of `config` are merged, and attriutes of the same name in those definitions are merged according to their own rules.

### `options`: Attribute Set of Option Declarations

When a module returns an option declaration, it adds a new option that modules evaluated with it can define, extending the interface of `make-shell` however you like!

Option declarations have their own [extensive section of the NixOS manual](https://nixos.org/manual/nixos/stable/#sec-option-declarations), but here's a simple example:

```nix
```nix
# basics.nix
{ # Module parameters are documented below but I'll explain the ones we need for this example
pkgs, # The nixpkgs set for the current system.  We need it because we're going to conditionally add some packages to the `packages` option
lib, # Equivalent to `nixpkgs.lib`.  We need it because it has functions for declaring and defining options.
config, # The evaluated configuration of all modules.  We need this to _read_ the definition of our new option.
...
}: {
  # lib.mkEnableOption creates an option which is false by default
  # but can be defined as true. It takes a description string as an argument.
  options.basic-packages.enable = lib.mkEnableOption "Add modern cli tools";
  # lib.mkIf lets us conditionally set attributes on a config set.  It takes a condition and a set of config attributes as arguments.  In this case the condition is the option we declared, read from the _parameter_ `config`, and the attribute set adds to the `packages` option.
  config = lib.mkIf config.basic-packages.enable {
    # Here's some packages I like. Which ones would you add?
    packages = [pkgs.ripgrep pkgs.fd pkgs.exa pkgs.procs pkgs.jq ];
}
# in some other file:
pkgs.make-shell {
  imports = [./basics.nix];
  # Now i can define the option that i declared!
  nix-packages.enable = true;
}
```

Multiple definitions of this option are merged.  If attributes of the same name are defined multiple times, evaluation errors.
