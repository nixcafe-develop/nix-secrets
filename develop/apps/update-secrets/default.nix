{
  pkgs,
  lib,
  inputs,
  system,
  ...
}:
let
  generated = lib.builders.generatedAgeFiles;

  script = pkgs.writeShellScriptBin "update-secrets" ''
    set -euo pipefail
    root="$(git rev-parse --show-toplevel)"

    ${lib.concatMapStringsSep "\n" (file: ''
      install -m 0644 "${
        inputs.self.packages.${system}.${file.package}.${file.output}
      }" "$root/${file.dest}"
    '') generated}
  '';
in
{
  type = "app";
  program = "${script}/bin/update-secrets";
  meta.description = "Install the age-encrypted outputs of the packages in lib.builders.generatedAgeFiles into the repo";
}
