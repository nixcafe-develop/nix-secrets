{ lib, namespace, ... }:
let
  inherit (lib.${namespace}) keys;

  mkPath = parts: lib.concatStringsSep "/" parts;
in
{
  inherit mkPath;

  mkHostSecrets =
    hostname: hostCfg:
    let
      hostKeys = keys.computed.${hostname}.keys;
    in
    lib.flatten (
      # global
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
      # users
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

  mkSharedSecrets =
    sharedCfg:
    let
      inherit (keys.computed) allKeys;
    in
    lib.flatten (
      # global
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
      # users
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

}
