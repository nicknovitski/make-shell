# "Why would I use this?"

The person who might benefit the most from `make-shell`:
1. is using nix flakes
2. is working on or across multiple `devShells`
3. has collaborators who are less familiar with nix
4. has no better alternatives

## `make-shell` requires nix flakes

`make-shell` is only usable on projects which are nix flakes.  If your project isn't already a nix flake, there are several command line tools which can quickly give you and your collaborators powerful nix-powered development environments, such as (in alphabetical order):
- [devbox](https://www.jetpack.io/devbox)
- [devenv](https://devenv.sh)
- [devshell](https://numtide.github.io/devshell/).

## `make-shell` helps you factor complex shell configuration into parts

Modules allow dividing a large and complex attribute set into a number of smaller ones that are merged together, and possibly in different combinations. If your project is a nix flake but it only needs one or two shell environments, then you could easily organize the code for those environments with `let` statements.  You could use `make-shell`, but it may not make a big difference.

## `make-shell` lets you create abstractions for complex shell configuration options

Module option declarations can abstract significant complexity, allowing people to write modules that only define options to achieve great things, without needing to understand every detail of the options implementation.  For example, in NixOS configuration, where modules have been used to great success, experts in nix and nginx configuration have worked for years on the [`services.nginx` option declarations](https://search.nixos.org/options?size=50&sort=relevance&query=services.nginx), with the result that many NixOS systems can be created that include a useful nginx server, possibly by someone unfamiliar with nix and/or nginx, possibly with no more effort than writing `services.nginx.enable = true;`.  So, if your project is a nix flake, and it has several devShells, but everyone collaborating on it is a nix expert, then maybe abstracting that complexity isn't as much of then I hope `make-shell` is still very useful to you, but maybe the interface separation it makes possible between defining and consuming module options will be less of an advantage.

## Someday, `make-shell` might be replaced

There are multiple ongoing projects experimenting with bringing a modular interface to nix packages generally (two I know are [nix-ux](https://github.com/tweag/nix-ux) and [drv-parts](https://github.com/davHau/drv-parts)).  If a project like that was successful, I'll go ahead and say you should use it instead of `make-shell`.

But in the meantime, like me, you might want something simple that makes sharing configuration across multiple devShells and multiple flakes simpler.
