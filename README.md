# Nix Flake · Secrets Management

> purr · git-hooks · agenix · ragenix · age · yubikey · reproducible · nix-flake

Nix flake template for age-encrypted secret management — scaffold per-host and shared secret trees, lock them with hardware-backed keys, and keep the repo linted with pre-commit hooks.

## What's Inside

| Tool | Purpose |
|------|---------|
| `agenix` (ragenix) | age-encrypted secret management |
| `age-plugin-yubikey` | YubiKey hardware-backed encryption |
| `nixfmt` / `deadnix` / `statix` | Nix code quality (pre-commit hooks) |
| `vim` / `neovim` / `nano` | Editors available in the dev shell |

The dev shell provides `agenix` (with `age-plugin-yubikey`), a curated editor suite, and git hooks wired via **purr**. The shell hook automatically sets `EDITOR='code --wait'` when VS Code is detected outside an SSH session.

## Quick Start

```sh
# Enter the dev shell
nix develop

# Add your public age key(s) to develop/lib/keys/default.nix

# Encrypt a secret for a host
agenix -e hosts/<hostname>/global/<service>/secret.age

# Edit an existing secret
agenix -e hosts/<hostname>/users/<user>/<service>/secret.age

# Verify git hooks pass before commit
nix flake check
```

## Customizing

### Secrets layout

Edit `secrets.nix` to declare which `.age` files belong to each host and service. The template ships with example entries for `hostname` / `hostname2` under two categories:

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

### Keys

Add recipient public keys in `develop/lib/keys/default.nix`. The flake consumes these through `develop/lib/secrets/default.nix` so that `agenix` re-encrypts for every listed key automatically.

## Project Structure

```
.
├── flake.nix                     # Flake hub entrypoint (purr + git-hooks + ragenix)
├── secrets.nix                   # Age file declarations (hosts & shared)
├── statix.toml                   # statix linter config
├── .envrc                        # direnv integration
│
├── develop/                      # flake src (= ./develop)
│   ├── checks/
│   │   └── git-hooks/            # pre-commit hooks (nixfmt, deadnix, statix)
│   ├── shells/
│   │   └── default/              # Dev shell definition + agenix + editors
│   └── lib/
│       ├── keys/                 # Recipient public keys
│       └── secrets/              # mkHostSecrets / mkSharedSecrets builders
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
