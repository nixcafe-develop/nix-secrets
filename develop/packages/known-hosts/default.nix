{
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) keys;

  # Generator settings from the central config (`lib/settings.ssh`).
  cfg = lib.settings.ssh;

  # Collect host entries from keys.nix
  machineHosts = lib.listToAttrs (
    map (name: {
      inherit name;
      value = keys.hosts.${keys.machines.${name}.host};
    }) cfg.fromMachines
  );

  # Merge machine hosts with extra entries
  allHosts = machineHosts // cfg.knownHostsExtra;

  # Convert entries into known_hosts lines
  toLines =
    entry:
    if cfg.format == "compact" then
      let
        hosts = lib.concatStringsSep "," entry.hostNames;
      in
      map (key: "${hosts} ${key}") entry.publicKeys
    else
      lib.flatten (map (host: map (key: "${host} ${key}") entry.publicKeys) entry.hostNames);

  lines = lib.flatten (map toLines (lib.attrValues allHosts));
  text = lib.concatStringsSep "\n" lines + "\n";
in
lib.builders.mkGeneratedAgeEncrypted {
  inherit pkgs text;
  name = "known_hosts";
  package = "known-hosts";
}
