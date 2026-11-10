# age-encrypted secrets template

This flake stores age-encrypted secrets for hosts, users, and shared scopes. The secret layout lives in `develop/lib/settings/default.nix`, recipient keys live in `develop/lib/keys/default.nix`, and some files are generated from Nix packages and installed with `nix run .#update-secrets`. The development shell provides ragenix and the age YubiKey plugin, and the repository uses pre-commit hooks.

It is part of the [develop-templates](https://github.com/nixcafe/develop-templates) collection. The template name there is `secrets`.

## Quick start

### Create from the flake template

```bash
nix flake init -t "github:nixcafe/develop-templates#secrets" --refresh
```

If you use the templates often, register the collection once:

```bash
nix registry add beans "github:nixcafe/develop-templates"
nix flake init -t beans#secrets
```

On systems that import cattery-modules, the `beans` registry entry is already configured.

### Create a GitHub repository from the template

```bash
gh repo create my-secrets --template nixcafe-develop/nix-secrets --clone
```

### Enter the development shell

```bash
direnv allow   # or: nix develop
```

## Configuration

Most settings are in `develop/lib/settings/default.nix`. Recipient keys, host names, and SSH endpoints are in `develop/lib/keys/default.nix`.

### Keys and machines

Replace the placeholder keys in `develop/lib/keys/default.nix` with your real recipients. The private keys are not part of the repository.

| Field | Meaning |
|-------|---------|
| `recoveryKeys` | Recovery recipients that should be stored offline. |
| `users.<name>.publicKeys` | Recipient keys for a user. |
| `hosts.<name>.hostNames` | Host names written to `known_hosts`. |
| `hosts.<name>.publicKeys` | Recipient keys for a host. |
| `hosts.<name>.endpoint` | SSH `hostName`, `port`, and `user` used by `match-blocks` and the `hosts` map. |
| `machines.<name>.host` | Host entry used by a machine. |
| `machines.<name>.users` | Users allowed on a machine. |

`keys.computed` combines each machine's host keys, user keys, and the recovery keys.

### Central settings

| Section | Purpose |
|---------|---------|
| `secrets` | The encrypted `.age` files under `hosts/` and `shared/`, grouped by host, user, and program. |
| `ssh` | Inputs for the `known-hosts` and `match-blocks` generators: `fromMachines`, `format`, `knownHostsExtra`, and `matchBlocksExtra`. |
| `generatedAgeFiles` | Maps a package and output to a shared user secret file. |
| `buildMachines` | Optional Hydra build machine entries for `lib.builders.mkBuildMachines`. |
| `hosts` | An IP to hostname map derived from the endpoints in `lib/keys`. |

The root `secrets.nix` and the recipient lists for generated files both read from `secrets`, so the file list is declared once.

## Secrets layout

Files are stored in four scopes:

```
hosts/<host>/global/<program>/<file>
hosts/<host>/users/<user>/<program>/<file>
shared/global/<program>/<file>
shared/users/<user>/<program>/<file>
```

Recipients are chosen by scope:

| Scope | Recipients |
|-------|------------|
| Host global | Host keys, the host's user keys, and recovery keys. |
| Host user | That user's keys. |
| Shared global | All machine keys and recovery keys. |
| Shared user | That user's keys. |

To add a secret, place the `.age` file in the matching directory and add it to `settings.secrets`.

## Generated secrets

Some secrets are produced by `nix build` instead of being encrypted by hand. Each generated package has two outputs:

```bash
nix build .#known-hosts             # plaintext output, useful for inspection
nix build '.#known-hosts^encrypted' # age-encrypted output
```

Install all generated files into the repository:

```bash
nix run .#update-secrets
```

The `update-secrets` script installs every entry in `settings.generatedAgeFiles`. It does not accept a package argument. Run it from inside the repository because it finds the repository root with `git rev-parse`.

To add a generated secret, add the target file to `settings.secrets`, add a package under `develop/packages/`, and add an entry to `settings.generatedAgeFiles` with the package name, output, user, program, and file.

## What's included

| Tool or component | Purpose |
|-------------------|---------|
| `ragenix` | age-encrypted secret management for NixOS. |
| `age-plugin-yubikey` | YubiKey support for age. |
| `age` | Encryption used at build time by generated secrets. |
| `known-hosts` package | Generates a `known_hosts` file from host keys. |
| `match-blocks` package | Generates SSH config blocks from host endpoints. |
| `update-secrets` app | Installs the encrypted package outputs into the repository. |
| `nixfmt`, `deadnix`, `statix` | Nix formatting, dead-code removal, and linting through pre-commit hooks. |
| `vim`, `neovim`, `nano` | Editors available in the development shell. |

## Customizing

### Secrets layout

Edit `settings.secrets` to declare which `.age` files belong to each host and to the shared scopes. The template includes example entries for `hostname` and `hostname2`, with `global/` for system-wide files and `users/<name>/` for user-scoped files.

### Dev shell

Change `develop/shells/default/default.nix` to add packages, environment variables, or shell hooks. The shell includes ragenix, age-plugin-yubikey, editors, and the git hook installation.

### Git hooks

Hooks live in `develop/checks/git-hooks/default.nix`. The defaults are:

| Hook | What it checks |
|------|----------------|
| `nixfmt` | Canonical Nix formatting. |
| `deadnix` | Unused lambda bindings and dead code. |
| `statix` | Lints and anti-patterns. |

Adjust `statix.toml` to change the lint rules.

## Project structure

```
.
├── flake.nix                     # flake entrypoint (purr and git-hooks)
├── secrets.nix                   # ragenix/agenix entry point derived from lib/settings
├── statix.toml
├── .envrc
├── .gitignore
│
├── develop/                      # flake source directory (= ./develop)
│   ├── checks/
│   │   └── git-hooks/            # pre-commit hooks
│   ├── shells/
│   │   └── default/              # development shell
│   ├── lib/
│   │   ├── keys/                 # recipient public keys, replace the placeholders
│   │   ├── settings/             # secret layout, SSH settings, generated files
│   │   ├── secrets/              # mkHostSecrets, mkSharedSecrets, recipient lookup
│   │   └── builders/             # mkAgeEncrypted and generatedAgeFiles
│   ├── packages/
│   │   ├── known-hosts/          # known_hosts generator
│   │   └── match-blocks/         # SSH config block generator
│   └── apps/
│       └── update-secrets/       # installs generated .age files
│
├── hosts/                        # per-host encrypted secrets
│   ├── hostname/
│   │   ├── global/
│   │   └── users/
│   └── hostname2/
│
└── shared/                       # secrets shared across hosts
    ├── global/
    └── users/
```

## Dependencies

Flake inputs:

- [purr](https://flakehub.com/f/nixcafe/purr): flake framework used by `flake.nix`
- [git-hooks.nix](https://flakehub.com/f/cachix/git-hooks.nix): pre-commit hook runner

Tools:

- [ragenix](https://github.com/yaxitech/ragenix): age-encrypted secrets for NixOS
- [age-plugin-yubikey](https://github.com/str4d/age-plugin-yubikey): YubiKey plugin for age
- `age` from nixpkgs: encryption used by generated packages

## License

MIT
