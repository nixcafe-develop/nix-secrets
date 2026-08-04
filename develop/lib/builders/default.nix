# Build helpers for age-encrypted derivations produced by `nix build`.
#
# `generatedAgeFiles` (consumed by `nix run .#update-secrets`) resolves the
# package → secret mapping declared in `lib/settings`, deriving and validating
# each `dest` against the secrets layout so it can never drift.
{ lib, ... }:
let
  settings = import ../settings/default.nix;
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
in
{
  inherit generatedAgeFiles mkAgeEncrypted mkGeneratedAgeEncrypted;
}
