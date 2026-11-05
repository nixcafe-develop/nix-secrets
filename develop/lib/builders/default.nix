# Build helpers for age-encrypted derivations produced by `nix build`.
#
# `generatedAgeFiles` (consumed by `nix run .#update-secrets`) resolves the
# package → secret mapping declared in `lib/settings`, deriving and validating
# each `dest` against the secrets layout so it can never drift.
{ lib, ... }:
let
  settings = import ../settings/default.nix { inherit lib; };
  secrets = import ../secrets/default.nix { inherit lib; };
  inherit (secrets) mkSharedSecretDest mkSharedSecretRecipients;

  # Resolve the declared mapping to repo paths, validating that every target
  # file is declared in the secrets layout.
  generatedAgeFiles = map (
    entry:
    entry
    // {
      dest = mkSharedSecretDest entry.user entry.program entry.file;
    }
  ) settings.generatedAgeFiles;

  # Plaintext + age-encrypted derivation with multiple outputs:
  #   out        → the plaintext (for inspection)
  #   encrypted  → age-encrypted armored file
  mkAgeEncrypted =
    {
      pkgs,
      name,
      text,
      recipients,
    }:
    pkgs.runCommand name
      {
        outputs = [
          "out"
          "encrypted"
        ];
        nativeBuildInputs = [ pkgs.age ];
        source = pkgs.writeText "plaintext" text;
        recipientsFile = pkgs.writeText "age-recipients" (lib.concatStringsSep "\n" recipients + "\n");
      }
      ''
        cat "$source" > "$out"
        age -a -R "$recipientsFile" -o "$encrypted" "$source"
      '';

  # Package-side entry point: build the age-encrypted derivation for the
  # caller, looking up its own entry in `generatedAgeFiles` to get the
  # recipients that `secrets.nix` declares for its target file.
  mkGeneratedAgeEncrypted =
    {
      pkgs,
      name,
      text,
      package,
    }:
    let
      entry = lib.findFirst (e: e.package == package) null generatedAgeFiles;
    in
    if entry == null then
      throw "package ${package} not in generatedAgeFiles"
    else
      mkAgeEncrypted {
        inherit pkgs name text;
        recipients = mkSharedSecretRecipients entry.dest;
      };

  # Hydra build machines with a `publicHostKey` derived from the raw
  # `publicKey` line in `settings.buildMachines`.
  #
  # nix's SSHMaster `base64::decode`s the machines-file publicHostKey and
  # writes the decoded bytes verbatim into a temp known_hosts file, so the
  # field must be base64 of the *full* host key line ("ssh-ed25519 <base64>",
  # i.e. the contents of ssh_host_*.pub), not of the bare key blob. Since nix
  # has no `builtins.base64Encode`, the encoding is computed in a derivation
  # (same pattern as atticd.nix / qemu-vm.nix). Callers pass `pkgs`.
  mkBuildMachines =
    pkgs:
    map (
      m:
      lib.removeAttrs m [ "publicKey" ]
      // (
        if m.publicKey == null then
          { }
        else
          {
            publicHostKey = builtins.readFile (
              pkgs.runCommand "base64-host-key-${m.hostName}" { } ''
                printf '%s' "${m.publicKey}" | base64 -w0 > $out
              ''
            );
          }
      )
    ) settings.buildMachines;
in
{
  inherit
    generatedAgeFiles
    mkAgeEncrypted
    mkGeneratedAgeEncrypted
    mkBuildMachines
    ;
}
