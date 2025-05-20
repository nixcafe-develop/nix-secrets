# copy from nixpkgs: https://github.com/NixOS/nixpkgs/blob/nixos-24.05/lib/lists.nix
rec {
  inherit (builtins) elem;

  foldl' = op: acc: builtins.seq acc (builtins.foldl' op acc);

  unique = foldl' (acc: e: if elem e acc then acc else acc ++ [ e ]) [ ];
}
