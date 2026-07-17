{
  inputs,
  pkgs,
  system,
  ...
}:
let
  commitCheck = inputs.self.checks.${system}.git-hooks.shellHook;
in
pkgs.mkShell {
  packages =
    [
      (inputs.agenix.packages.${system}.default.override {
        plugins = [ pkgs.age-plugin-yubikey ];
      })
    ]
    ++ (with pkgs; [
      vim
      neovim
      nano
    ]);

  shellHook = ''
    ${commitCheck}

    if command -v code > /dev/null 2>&1 && [[ -z $SSH_CONNECTION ]]; then
      export EDITOR='code --wait'
    fi
  '';
  buildInputs = inputs.self.checks.${system}.git-hooks.enabledPackages;
}
