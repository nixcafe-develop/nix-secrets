# Helpers that turn the secrets declared in `lib/settings` into per-file
# recipient keys, and (via root `secrets.nix`) into the agenix/ragenix
# secret attribute set.
{ lib, ... }:
let
  keys = import ../keys/default.nix { inherit lib; };

  # The secrets layout declared centrally in `lib/settings`.
  config = (import ../settings/default.nix).secrets;

  mkPath = parts: lib.concatStringsSep "/" parts;

  # Repo-relative path of a shared user secret, validated against `config`
  # so it can never drift from the declared file list.
  mkSharedSecretDest =
    user: program: file:
    let
      path = mkPath [
        "shared"
        "users"
        user
        program
        file
      ];
      files =
        config.shared.users.${user}.${program}
          or (throw "user ${user} program ${program} not declared in shared secrets config");
    in
    if lib.elem file files then
      path
    else
      throw "file ${file} not in shared secrets config for user ${user} program ${program}";

  # Recipient keys for a shared secret, looked up by its repo path.
  mkSharedSecretRecipients =
    path:
    let
      entries = lib.listToAttrs (mkSharedSecrets config.shared);
    in
    entries.${path}.publicKeys;

  # Per-host secrets: global files use the host's computed key set, user files
  # use that user's keys.
  mkHostSecrets =
    hostname: hostCfg:
    let
      hostKeys = keys.computed.${hostname}.keys;
    in
    lib.flatten (
      lib.mapAttrsToList (
        program: files:
        map (file: {
          name = mkPath [
            "hosts"
            hostname
            "global"
            program
            file
          ];
          value.publicKeys = hostKeys;
        }) files
      ) hostCfg.global or { }
    )
    ++ lib.flatten (
      lib.mapAttrsToList (
        user: userCfg:
        let
          userKeys = keys.users.${user}.publicKeys;
        in
        lib.flatten (
          lib.mapAttrsToList (
            program: files:
            map (file: {
              name = mkPath [
                "hosts"
                hostname
                "users"
                user
                program
                file
              ];
              value.publicKeys = userKeys;
            }) files
          ) userCfg
        )
      ) hostCfg.users or { }
    );

  # Shared secrets: global files use all machine keys, user files use that
  # user's keys.
  mkSharedSecrets =
    sharedCfg:
    let
      inherit (keys.computed) allKeys;
    in
    lib.flatten (
      lib.mapAttrsToList (
        program: files:
        map (file: {
          name = mkPath [
            "shared"
            "global"
            program
            file
          ];
          value.publicKeys = allKeys;
        }) files
      ) sharedCfg.global or { }
    )
    ++ lib.flatten (
      lib.mapAttrsToList (
        user: userCfg:
        let
          ukeys = keys.users.${user}.publicKeys;
        in
        lib.flatten (
          lib.mapAttrsToList (
            program: files:
            map (file: {
              name = mkPath [
                "shared"
                "users"
                user
                program
                file
              ];
              value.publicKeys = ukeys;
            }) files
          ) userCfg
        )
      ) sharedCfg.users or { }
    );
in
{
  inherit
    mkPath
    config
    mkSharedSecretDest
    mkSharedSecretRecipients
    mkHostSecrets
    mkSharedSecrets
    ;
}
