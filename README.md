# How to use Develop my secrets

### [use template repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template)

## TODO: doc pending

### Directory structure
```
.
│
├── flake.nix
│
│   # Common functions: foldl', unique
├── lib 
│   └── lists.nix
│
│   # Check if your nix file is formatted before uploading
├── checks 
│   └── pre-commit-check
│       └── default.nix
│
│   # agenix command support
├── shells
│   └── default
│       └── default.nix│
│
│   # direnv: https://github.com/direnv/direnv/wiki/Nix
├── .envrc
│
│   # statix: https://github.com/oppiliappan/statix?tab=readme-ov-file#configuration
├── statix.toml 
│
│   # Each host has its own secrets
├── hosts 
│   │
│   │   # Hostname of the machine
│   ├── hostname 
│   │   │
│   │   │   # Global secrets for all users
│   │   ├── global 
│   │   │   └── wireguard
│   │   │       └── example.conf.age
│   │   │
│   │   │   # User specific secrets
│   │   └── users 
│   │       └── example
│   │           └── wireguard
│   │               └── example.conf.age
│   │
│   │   # Same as above, just to show that multiple hosts can be supported
│   └── hostname2 
│       ├── global
│       │   └── wireguard
│       │       └── example.conf.age
│       └── users
│           └── example
│               └── wireguard
│                   └── example.conf.age
│   
│   # Shared secrets for all hosts and users
├── shared
│   │
│   │   # Global secrets for all hosts
│   ├── global 
│   │   └── wireguard
│   │       └── example.conf.age
│   │
│   │   # User specific secrets for all users
│   └── users 
│       └── example
│           └── wireguard
│               └── example.conf.age
│
│   # Configure all the file paths to be encrypted here
└── secrets.nix
```