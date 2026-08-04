{ lib, ... }:
let
  # ──────────────────────────────────────────────────────────────────────────
  # Placeholder keys — REPLACE EVERYTHING below with your real recipient keys.
  # These are throwaway public keys that make the template buildable out of
  # the box; the private counterparts are NOT shipped.
  # ──────────────────────────────────────────────────────────────────────────
  keys = {
    # recovery key (must be saved offline)
    recoveryKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM9h3ddGd803EXjfK7rpRnxqnhx70/XzErizWQmJKqg+"
    ];

    # user keys
    users = {
      alice = {
        publicKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEh/h9mfUBi4dzC5Ix2otCyjo6XPyV5vgxQHR4HpCXvr"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMVrnYbK00GsP2h/x7XdeN1qXMexZ4mvjyKzMO5h7utY"
        ];
      };

      bob = {
        publicKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB+QYNfSxUPxPD3cD3Knpj66hTIjJwCDhljQ82dWi5rh"
        ];
      };
    };

    # host keys
    hosts = {
      hostname = {
        hostNames = [
          "hostname"
          "hostname.local"
        ];

        publicKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHNxSkLdWTgr/frAOoAqrk46oqgMeC9ixz3kEPHYXfJI"
        ];

        endpoint = {
          hostName = "hostname.local";
          port = 22;
          user = "root";
        };
      };

      hostname2 = {
        hostNames = [
          "hostname2"
          "hostname2.local"
        ];

        publicKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP/8iuoWZ1QjG/Q9Xe0tmRXr/HEAuGNmcaQRhhxlJhgw"
        ];

        endpoint = {
          hostName = "10.0.0.12";
          port = 2222;
          user = "root";
        };
      };
    };

    machines = {
      hostname = {
        host = "hostname";
        users = [ "alice" ];
      };

      hostname2 = {
        host = "hostname2";
        users = [
          "alice"
          "bob"
        ];
      };
    };

    computed =
      let
        perMachine = lib.mapAttrs (
          _: m:
          let
            h = keys.hosts.${m.host};
            hostKeys = keys.hosts.${m.host}.publicKeys;
            userKeys = lib.flatten (map (u: keys.users.${u}.publicKeys) m.users);
          in
          {
            inherit hostKeys userKeys;
            keys = hostKeys ++ userKeys ++ keys.recoveryKeys;
            endpoint = h.endpoint or null;
          }
        ) keys.machines;

        allKeys = lib.unique (
          keys.recoveryKeys ++ lib.flatten (map (m: m.keys) (lib.attrValues perMachine))
        );
      in
      perMachine
      // {
        inherit allKeys;
      };
  };
in
keys
