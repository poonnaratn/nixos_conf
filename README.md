# nixos_conf

Personal NixOS flake config with a modular layout.

Main goals:
- keep host files lean
- reuse features across machines
- move from KDE Plasma toward Niri + Noctalia

## Current status

- Active host target: `x1Carbon`
- Declarative keyboard remap is enabled via `services.keyd`
- Niri/Noctalia modules exist but are still WIP

## Repo layout

```text
.
├── flake.nix
└── modules
    ├── parts.nix
    ├── features
    │   ├── keyboard.nix
    │   ├── niri.nix
    │   ├── noctalia.nix
    │   └── noctalia.json
    └── hosts
        └── x1carbon
            ├── default.nix
            ├── configuration.nix
            └── hardware.nix
```

## How this setup works

- `flake.nix` uses `flake-parts` + `import-tree` to load everything under `modules/`.
- `modules/hosts/<host>/default.nix` defines a host under `nixosConfigurations`.
- `modules/hosts/<host>/configuration.nix` composes features using `imports = [ ... ]`.
- `modules/features/*.nix` contains reusable feature modules.
- `modules/hosts/<host>/hardware.nix` is machine-specific hardware config.

## Common commands

From repo root:

```bash
# evaluate host options from working tree
nix eval path:.#nixosConfigurations.x1Carbon.config.services.keyd.enable

# dry test activation (recommended first)
sudo nixos-rebuild test --flake .#x1Carbon

# apply configuration
sudo nixos-rebuild switch --flake .#x1Carbon
```

Notes:
- Use `path:.#...` for evaluation when files are new/untracked.
- If you omit `--flake`, `nixos-rebuild` falls back to `/etc/nixos`.

## Useful Nix websites

- `https://search.nixos.org/options`  
  Find NixOS options and their exact config paths (`services.*`, `programs.*`, etc).

- `https://search.nixos.org/packages`  
  Find package names for `environment.systemPackages` and check availability by system.

- `https://wiki.nixos.org`  
  Official community wiki with practical setup guides and examples.

- `https://nixos.org/manual/nixos/stable/`  
  NixOS manual (official reference for modules, services, and system behavior).

- `https://home-manager-options.extranix.com/`  
  Search Home Manager options quickly when configuring user-level programs.

- `https://mynixos.com/`  
  Community search UI for packages and options with examples.

## Adding a new machine

1. Create host directory:

```bash
mkdir -p modules/hosts/<new-host>
```

2. Add:
- `modules/hosts/<new-host>/default.nix`
- `modules/hosts/<new-host>/configuration.nix`
- `modules/hosts/<new-host>/hardware.nix`

3. Generate hardware on that machine:

```bash
sudo nixos-generate-config --show-hardware-config
```

4. Build that host:

```bash
sudo nixos-rebuild switch --flake .#<new-host>
```

## Refactor direction

Target state: `modules/hosts/x1carbon/configuration.nix` should be close to imports + host identity only.

### TODO

- [ ] Create `modules/features/base.nix` for shared system defaults
- [ ] Create `modules/features/software.nix` as single software inventory
- [ ] Create `modules/features/desktop/plasma.nix`
- [ ] Create `modules/features/desktop/niri.nix`
- [ ] Move user definition to `modules/features/users/me.nix`
- [ ] Move audio block to `modules/features/audio.nix`
- [ ] Move printing/networking defaults into feature modules
- [ ] Keep host config lean: imports + hostname + `system.stateVersion`
- [ ] Introduce a `mkHost` helper in `flake.nix` to reduce host boilerplate
- [ ] Add second host (`desktop`) reusing shared feature modules

## Style rules for this repo

- one concern per module
- avoid over-splitting into too many tiny files
- test each move with `nixos-rebuild test` before `switch`
- make small commits (one concern per commit)

## Next immediate step

Refactor pass 1 with no behavior change:
1. extract `audio` module
2. extract `software` module
3. extract `plasma` module
4. keep `x1carbon/configuration.nix` as composition only
