# nixos_conf

Personal NixOS flake with a modular structure.

This repo is used to:
- keep host files small
- reuse shared features across devices
- manage system config declaratively with flakes

## Project structure

```text
.
├── flake.nix
└── modules
    ├── parts.nix
    ├── features/
    │   ├── base-system.nix
    │   ├── locale-and-time.nix
    │   ├── plasma-desktop.nix
    │   ├── audio-pipewire.nix
    │   ├── fonts-thai.nix
    │   ├── desktop-apps.nix
    │   ├── keyboard.nix
    │   ├── ssh-agent.nix
    │   ├── niri.nix
    │   └── noctalia.nix
    └── hosts/x1carbon/
        ├── default.nix
        ├── configuration.nix
        ├── identity.nix
        └── hardware.nix
```

How it connects:
- `flake.nix` loads everything under `modules/` using `flake-parts` + `import-tree`.
- `hosts/<host>/default.nix` defines `nixosConfigurations.<HostName>`.
- `hosts/<host>/configuration.nix` should mostly be `imports = [ ... ]`.
- shared behavior lives in `modules/features/*.nix`.
- machine-specific disk/kernel config lives in `hosts/<host>/hardware.nix`.

## Common Nix commands

Run from repo root:

```bash
# show available flake outputs (hosts/modules/packages)
nix flake show .

# evaluate one value from a host config
nix eval .#nixosConfigurations.x1Carbon.config.networking.hostName

# build only (safe check, no activation)
sudo nixos-rebuild build --flake .#x1Carbon

# build + activate for current boot (recommended before switch)
sudo nixos-rebuild test --flake .#x1Carbon

# apply and persist as current system generation
sudo nixos-rebuild switch --flake .#x1Carbon

# build and set as next boot generation (without switching now)
sudo nixos-rebuild boot --flake .#x1Carbon

# list generations
sudo nix-env -p /nix/var/nix/profiles/system --list-generations
```

Notes:
- if you add new untracked files, `nix eval .#...` may not see them yet because flakes read Git-tracked content.
- use `path:.#...` for local eval while files are untracked, or stage files with `git add`.

## Setup new host script

Use the scaffold script from repo root.  
If you prefer step-by-step prompts, run it with no arguments:

```bash
./scripts/setup-new-host.sh
```

You can still use full CLI args:

```bash
./scripts/setup-new-host.sh \
  --host-dir desktop-main \
  --system-hostname desktop-main \
  --user-name me \
  --user-description "me"
```

Useful flags:
- `--flake-host` if you want to override the default derived from host dir.
- `--module-prefix` if you want module attr names different from flake host.
- `--force` to overwrite existing host files.
- `--with-power-management` to include `self.nixosModules.powerManagement` in the generated host profile (off by default for desktop-safe scaffolds).

## Adding a new device

1. Create the host directory:

```bash
mkdir -p modules/hosts/<new-host>
```

2. Add host files:
- `modules/hosts/<new-host>/default.nix`
- `modules/hosts/<new-host>/configuration.nix`
- `modules/hosts/<new-host>/identity.nix`
- `modules/hosts/<new-host>/hardware.nix`

3. In `default.nix`, define the host in `flake.nixosConfigurations`:
- `flake.nixosConfigurations.<HostName> = inputs.nixpkgs.lib.nixosSystem { ... };`
- keep `<HostName>` exactly how you want to call rebuild, e.g. `.#desktop` or `.#workLaptop`.

4. In `configuration.nix`, keep it thin:
- import hardware + identity + shared features
- example style: same as current `x1carbon/configuration.nix`

5. Generate hardware config on the new machine:

```bash
sudo nixos-generate-config --show-hardware-config
```

Copy relevant output into `modules/hosts/<new-host>/hardware.nix`.

6. Build the new host:

```bash
sudo nixos-rebuild build --flake .#<HostName>
sudo nixos-rebuild switch --flake .#<HostName>
```
