# agenix / ragenix entry point: turns the secrets declared in
# `develop/lib/settings/default.nix` into the attribute set of
# `"path" -> { publicKeys }` that the tooling expects. Do not edit the file
# list here — edit `develop/lib/settings/default.nix` instead.
let
  pkgs = import <nixpkgs> { };
  keys = import ./develop/lib/keys/default.nix { inherit (pkgs) lib; };
  lib = {
    inherit keys;
  }
  // pkgs.lib;

  inherit
    (import ./develop/lib/secrets/default.nix {
      inherit lib;
    })
    config
    mkHostSecrets
    mkSharedSecrets
    ;
in
lib.listToAttrs (
  lib.flatten ((lib.mapAttrsToList mkHostSecrets config.hosts) ++ (mkSharedSecrets config.shared))
)
