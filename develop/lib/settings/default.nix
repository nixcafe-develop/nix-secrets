# ────────────────────────────────────────────────────────────────────────────
# Central configuration for this repository.
#
# Every user-configurable value lives here so that:
#   - `secrets.nix` / agenix(ragenix) read `secrets`
#   - the age-encrypted build outputs read `generatedAgeFiles`
#   - the SSH config generators read `ssh`
#
# Machine identities / keys / endpoints are declared separately in `lib/keys`.
# ────────────────────────────────────────────────────────────────────────────
{
  # ---------------------------------------------------------------------------
  # Secrets layout
  # ---------------------------------------------------------------------------
  # Which encrypted (`.age`) files exist for each host / shared scope, and how
  # each file is scoped (host keys vs user keys). This is the single source of
  # truth consumed by root `secrets.nix` and by the recipient resolution in
  # `lib/secrets`.
  #
  #   hosts.<host>.global.<program>       → encrypted with that host's keys
  #   hosts.<host>.users.<user>.<program> → encrypted with that user's keys
  #   shared.global.<program>             → encrypted with all machine keys
  #   shared.users.<user>.<program>       → encrypted with that user's keys
  secrets = {
    hosts = {
      hostname = {
        global = {
          wireguard = [ "example.conf.age" ];
        };

        users = {
          alice = {
            wireguard = [ "example.conf.age" ];
          };
        };
      };

      hostname2 = {
        global = {
          wireguard = [ "example.conf.age" ];
        };

        users = {
          alice = {
            wireguard = [ "example.conf.age" ];
          };
        };
      };
    };

    shared = {
      global = {
        wireguard = [ "example.conf.age" ];
      };

      users = {
        alice = {
          wireguard = [ "example.conf.age" ];
          ssh = [
            "known_hosts.age"
            "block_config.age"
          ];
        };
      };
    };
  };

  # ---------------------------------------------------------------------------
  # SSH config generators (`known-hosts` / `match-blocks` packages)
  # ---------------------------------------------------------------------------
  ssh = {
    # Machine names (as declared in `lib/keys`) to include in the generated files.
    fromMachines = [
      "hostname"
      "hostname2"
    ];

    # known_hosts line layout.
    #   "compact"  → comma-separated host names per line
    #   "expanded" → one host per line
    format = "compact";

    # Extra known_hosts entries (hosts not present in `lib/keys`).
    knownHostsExtra = {
      example-host = {
        hostNames = [
          "example-host.example"
        ];
        publicKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILdwqN7Kpo87IKdlLAfTjaKIjCa0UtYhFchZ4/f34njR"
        ];
      };
    };

    # Extra SSH config blocks (hosts not covered by `lib/keys` endpoints).
    matchBlocksExtra = {
      example-host = {
        endpoint = {
          hostName = "10.0.0.99";
          port = 22;
          user = "root";
        };
      };
    };
  };

  # ---------------------------------------------------------------------------
  # Age files generated from `nix build` packages
  # ---------------------------------------------------------------------------
  # Maps each flake package to one of its outputs and to the shared user secret
  # file it produces. `dest` is derived from `secrets` above (and validated in
  # `lib/builders`), so it can never drift from what `secrets.nix` declares.
  generatedAgeFiles = [
    {
      package = "known-hosts";
      output = "encrypted";
      user = "alice";
      program = "ssh";
      file = "known_hosts.age";
    }
    {
      package = "match-blocks";
      output = "encrypted";
      user = "alice";
      program = "ssh";
      file = "block_config.age";
    }
  ];
}
