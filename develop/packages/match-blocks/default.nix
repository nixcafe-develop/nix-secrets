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
  allHosts = machineHosts // cfg.matchBlocksExtra;

  # ssh block generator
  mkBlock =
    name:
    let
      h = allHosts.${name} or null;
      ep = if h != null then h.endpoint or null else null;

      hostName = if ep != null then ep.hostName or null else null;
    in
    if hostName == null then
      null
    else
      let
        lines = lib.filter (x: x != null) [
          "Host ${name}"
          "  HostName ${hostName}"
          (lib.optionalString (ep ? user && ep.user != null) "  User ${ep.user}")
          (lib.optionalString (ep ? port && ep.port != null) "  Port ${toString ep.port}")
          "  IdentityFile ${ep.identityFile or "~/.ssh/id_ed25519"}"
        ];
      in
      lib.concatStringsSep "\n" lines;

  blocks = lib.filter (x: x != null) (map mkBlock (lib.attrNames allHosts));
  text = lib.concatStringsSep "\n\n" blocks + "\n";
in
lib.builders.mkGeneratedAgeEncrypted {
  inherit pkgs text;
  name = "block_config";
  package = "match-blocks";
}
