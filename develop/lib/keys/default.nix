{ lib, ... }:
rec {
  keys = {

    # recovery key (must be saved offline)
    recoveryKeys = [
      "ssh-ed25519 AAAA_RECOVERY_1..."
      "ssh-ed25519 AAAA_RECOVERY_2..."
    ];

    # user keys
    users = {
      alice = {
        publicKeys = [
          "ssh-ed25519 AAAA_USER_ALICE_1..."
          "ssh-ed25519 AAAA_USER_ALICE_2..."
        ];
      };

      bob = {
        publicKeys = [
          "ssh-ed25519 AAAA_USER_BOB_1..."
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
          "ssh-ed25519 AAAA_HOST_HOSTNAME_1..."
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
          "ssh-ed25519 AAAA_HOST_HOSTNAME2_1..."
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
}
