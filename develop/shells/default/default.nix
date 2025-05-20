{
  inputs,
  pkgs,
  mkShell,
  system,
  ...
}:
let
  commitCheck = inputs.self.checks.${system}.pre-commit-check.shellHook;
in
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

  # If you are using vscode, I will automatically set EDITOR for easy editing.
  shellHook = ''
    ${commitCheck}

    if command -v code > /dev/null 2>&1 && [[ -z $SSH_CONNECTION ]]; then
      # If you want to open in a new window, add `--new-window`
      export EDITOR='code --wait'
    fi
  '';
  buildInputs = inputs.self.checks.${system}.pre-commit-check.enabledPackages;
}
