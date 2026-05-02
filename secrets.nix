let
  pkgs = import <nixpkgs> { };
  keys = import ./develop/lib/keys/default.nix { inherit (pkgs) lib; };
  namespace = "secrets";
  lib = {
    ${namespace} = { inherit (keys) keys; };
  }
  // pkgs.lib;

  inherit
    (import ./develop/lib/secrets/default.nix {
      inherit lib;
      inherit namespace;
    })
    mkHostSecrets
    mkSharedSecrets
    ;

  secrets = {
    hosts = {
      hostname = {
        global = {
          wireguard = [
            "example.conf.age"
            "conf/example.conf.age"
          ];
        };

        users = {
          example = {
            wireguard = [
              "example.conf.age"
              "conf/example.conf.age"
            ];
          };
        };
      };
    };

    shared = {
      global = {
        wireguard = [
          "example.conf.age"
          "conf/example.conf.age"
        ];
      };

      users = {
        example = {
          wireguard = [
            "example.conf.age"
          ];
        };
      };
    };
  };
in
lib.listToAttrs (
  lib.flatten ((lib.mapAttrsToList mkHostSecrets secrets.hosts) ++ (mkSharedSecrets secrets.shared))
)
