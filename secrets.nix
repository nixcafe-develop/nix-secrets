let
  lib = import lib/lists.nix;

  # recovery key (must be saved offline)
  recoveryKeys = [
    "ssh-ed25519 AAAAAAAAAAAAA......"
  ];

  # user keys
  user = {
    example = [
      # sudo cat ~/.ssh/id_ed25519.pub
      "ssh-ed25519 AAAAAAAAAAAAA......"
    ];
    example2 = [
      # sudo cat ~/.ssh/id_ed25519.pub
      "ssh-ed25519 AAAAAAAAAAAAA......"
    ];
  };

  # host keys
  system = {
    # sudo ssh-keygen -A; sudo cat /etc/ssh/ssh_host_ed25519_key.pub
    hostname = "ssh-ed25519 AAAAAAAAAAAAA......";
    hostname2 = "ssh-ed25519 AAAAAAAAAAAAA......";
  };

  # category list
  owners = recoveryKeys ++ user.example; # Used to manage all files, recoveryKeys must contain.
  users = builtins.concatLists (builtins.attrValues user); # All user keys
  systems = builtins.attrValues system; # All host keys

  # ===============  Only the following key sets are allowed in the file  ================

  # keys list
  userKeys = lib.unique (owners ++ users);
  allKeys = lib.unique (owners ++ users ++ systems);

  # host keys list
  hostname = {
    keys = lib.unique (owners ++ [ system.hostname ]);
    userKeys = lib.unique (owners ++ user.example);
  };
  hostname2 = {
    keys = lib.unique (owners ++ [ system.hostname2 ]);
    userKeys = lib.unique (owners ++ user.example2);
  };
in
{
  # Usage: `agenix -e path/to/secrets.nix` or `agenix -r`
  # Demo: `agenix -e hosts/hostname/global/wireguard/example.conf.age`

  # private config
  # ================  hostname   ================
  "hosts/hostname/global/wireguard/example.conf.age".publicKeys = hostname.keys;
  "hosts/hostname/users/example/wireguard/example.conf.age".publicKeys = hostname.userKeys;
  # ================  hostname2   ================
  "hosts/hostname2/global/wireguard/example.conf.age".publicKeys = hostname2.keys;
  "hosts/hostname2/users/example/wireguard/example.conf.age".publicKeys = hostname2.userKeys;

  # shared config
  "shared/global/wireguard/example.conf.age".publicKeys = allKeys;
  "shared/users/example/wireguard/example.conf.age".publicKeys = userKeys;
}
