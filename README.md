# Nix Flake · Secrets Management

> purr · git-hooks · agenix · age · yubikey · nix-flake

Nix flake template for age-encrypted secret management — scaffold per-host and shared secret trees, lock them with hardware-backed keys, generate age files straight from `nix build` packages, and keep the repo linted with pre-commit hooks.

Part of the [develop-templates](https://github.com/nixcafe/develop-templates) collection (`nix flake init`-ready).

## Quick Start

### `nix flake init`

```bash
nix flake init -t "github:nixcafe/develop-templates#secrets" --refresh
```

Register an alias:
```bash
nix registry add beans "github:nixcafe/develop-templates"
nix flake init -t beans#secrets
```

> **Tip**: With [cattery-modules](https://github.com/nixcafe/cattery-modules), `beans` is pre-registered.

### Create from Template

```bash
gh repo create my-secrets --template nixcafe/nix-secrets --clone
```

### Enter the Dev Shell

```bash
direnv allow       # or: nix develop
```

## Configuration

Everything user-configurable lives in **one file**: `develop/lib/settings/default.nix`. Machine identities / keys / endpoints live in `develop/lib/keys/default.nix`.

### Keys (`develop/lib/keys/default.nix`)

Replace the shipped **placeholder keys** with your real age/SSH recipient keys:

| Field | Meaning |
|-------|---------|
| `recoveryKeys` | offline recovery keys |
| `users.<name>.publicKeys` | per-user recipient keys |
| `hosts.<name>.publicKeys` | per-host recipient keys (also used for `known_hosts`) |
| `hosts.<name>.endpoint` | SSH endpoint used by the `match-blocks` generator |
| `machines.<name>` | which host / users map to which machine |

### Central settings (`develop/lib/settings/default.nix`)

| Section | Purpose |
|---------|---------|
| `secrets` | which encrypted `.age` files exist and how they are scoped (host / user keys) |
| `ssh` | inputs for the `known-hosts` / `match-blocks` generators (`fromMachines`, `format`, extras) |
| `generatedAgeFiles` | which `nix build` package output installs to which secret file |

`secrets.nix` (ragenix entry point) and the generated-file recipients are both derived from `secrets` — you never edit the file list in two places.

## Generated Secrets

Some secrets are produced by `nix build` rather than hand-encrypted. Each package builds a derivation with two outputs:

```bash
nix build .#known-hosts            # result = plaintext (for inspection)
nix build '.#known-hosts^encrypted' # result = age-encrypted file
```

To (re)generate and install **all** declared generated secrets into the repo:

```bash
nix run .#update-secrets           # all generated age files
nix run .#update-secrets -- known-hosts   # just one package
```

Recipients come from `secrets.nix` automatically, so a generated file can never drift from the declared layout. To add a new generated secret, add one entry to `settings.generatedAgeFiles` (plus the matching file in `settings.secrets`) and drop a package in `develop/packages/`.

## What's Inside

| Tool | Purpose |
|------|---------|
| `agenix` (ragenix) | age-encrypted secret management |
| `age-plugin-yubikey` | YubiKey hardware-backed encryption |
| `age` | encryption used at build time by generated secrets |
| `nixfmt` / `deadnix` / `statix` | Nix code quality (pre-commit hooks) |
| `vim` / `neovim` / `nano` | Editors available in the dev shell |

## Customizing

### Secrets layout

Edit `settings.secrets` to declare which `.age` files belong to each host and service. The template ships with example entries for `hostname` / `hostname2` under two categories:

- **hosts** — per-machine secrets (`global/` for system-wide, `users/<username>/` for user-scoped)
- **shared** — secrets shared across all hosts (same `global/` / `users/` split)

### Dev shell

Override or extend the shell in `develop/shells/default/`. Add packages, environment variables, or extra shell hooks as needed.

### Git hooks

Hooks live in `develop/checks/git-hooks/`. The defaults are:

| Hook | What it checks |
|------|----------------|
| `nixfmt` | Canonical Nix formatting |
| `deadnix` | Unused lambda bindings / dead code |
| `statix` | Lints and anti-patterns |

Tweak `statix.toml` to relax or tighten lint rules.

## Project Structure

```
.
├── flake.nix                     # Flake hub entrypoint (purr + git-hooks + ragenix)
├── secrets.nix                   # ragenix entry point (derived from lib/settings)
├── statix.toml                   # statix linter config
├── .envrc                        # direnv integration
├── .gitignore
│
├── develop/                      # flake src (= ./develop)
│   ├── checks/
│   │   └── git-hooks/            # pre-commit hooks (nixfmt, deadnix, statix)
│   ├── shells/
│   │   └── default/              # Dev shell definition + agenix + editors
│   ├── lib/
│   │   ├── keys/                 # Recipient public keys (REPLACE placeholders!)
│   │   ├── settings/             # Central config: secrets layout + ssh + generatedAgeFiles
│   │   ├── secrets/              # mkHostSecrets / mkSharedSecrets / recipient resolution
│   │   └── builders/             # mkAgeEncrypted (multi-output) + generatedAgeFiles
│   ├── packages/
│   │   ├── known-hosts/          # Generates known_hosts (plaintext + age-encrypted)
│   │   └── match-blocks/         # Generates SSH config blocks
│   └── apps/
│       └── update-secrets/       # nix run .#update-secrets → install generated .age files
│
├── hosts/                        # Per-host encrypted secrets
│   ├── hostname/
│   │   ├── global/               #   System-wide secrets
│   │   └── users/                #   User-scoped secrets
│   └── hostname2/                #   (multi-host example)
│
└── shared/                       # Secrets shared across all hosts
    ├── global/
    └── users/
```

## Dependencies

- [purr](https://flakehub.com/f/nixcafe/purr) — flake utility kit
- [ragenix](https://github.com/yaxitech/ragenix) — age-encrypted secrets for NixOS
- [git-hooks.nix](https://flakehub.com/f/cachix/git-hooks.nix) — pre-commit hook automation
- [age-plugin-yubikey](https://github.com/str4d/age-plugin-yubikey) — YubiKey plugin for age

## License

MIT — go build something reproducible.
