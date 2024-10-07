{
  inputs,
  pkgs,
  mkShell,
  system,
  ...
}:
mkShell {
  packages =
    [
      (inputs.agenix.packages.${system}.default.override {
        # On non-Windows, non-macOS systems, 
        # you need to ensure that the pcscd service is installed and running. 
        # `services.pcscd.enable = true;`
        plugins = [ pkgs.age-plugin-yubikey ];
      })
    ]
    ++ (with pkgs; [
      vim
      neovim
      nano
    ]);

  inherit (inputs.self.checks.${system}.pre-commit-check) shellHook;
  buildInputs = inputs.self.checks.${system}.pre-commit-check.enabledPackages;
}
