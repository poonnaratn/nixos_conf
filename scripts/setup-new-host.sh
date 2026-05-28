#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/setup-new-host.sh \
    --host-dir <name> \
    --flake-host <Name> \
    --module-prefix <Prefix> \
    --system-hostname <hostname> \
    --user-name <name> \
    [--user-description <text>] \
    [--with-power-management] \
    [--force]

Required:
  --host-dir            Directory under modules/hosts (e.g. desktop-main)
  --flake-host          flake.nixosConfigurations attr name (e.g. desktopMain)
  --module-prefix       nixosModules prefix (e.g. desktopMain)
  --system-hostname     networking.hostName value
  --user-name           users.users attr name

Optional:
  --user-description    defaults to --user-name
  --with-power-management
  --force               overwrite existing target files
  -h, --help
EOF
}

die() {
  echo "error: $*" >&2
  exit 1
}

require_ident() {
  local value="$1"
  local label="$2"
  if [[ ! "$value" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
    die "$label must match ^[A-Za-z_][A-Za-z0-9_]*$, got: $value"
  fi
}

host_dir=""
flake_host=""
module_prefix=""
system_hostname=""
user_name=""
user_description=""
with_power_management=0
force=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host-dir)
      [[ $# -ge 2 ]] || die "--host-dir requires a value"
      host_dir="$2"
      shift 2
      ;;
    --flake-host)
      [[ $# -ge 2 ]] || die "--flake-host requires a value"
      flake_host="$2"
      shift 2
      ;;
    --module-prefix)
      [[ $# -ge 2 ]] || die "--module-prefix requires a value"
      module_prefix="$2"
      shift 2
      ;;
    --system-hostname)
      [[ $# -ge 2 ]] || die "--system-hostname requires a value"
      system_hostname="$2"
      shift 2
      ;;
    --user-name)
      [[ $# -ge 2 ]] || die "--user-name requires a value"
      user_name="$2"
      shift 2
      ;;
    --user-description)
      [[ $# -ge 2 ]] || die "--user-description requires a value"
      user_description="$2"
      shift 2
      ;;
    --with-power-management)
      with_power_management=1
      shift
      ;;
    --force)
      force=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

[[ -n "$host_dir" ]] || die "--host-dir is required"
[[ -n "$flake_host" ]] || die "--flake-host is required"
[[ -n "$module_prefix" ]] || die "--module-prefix is required"
[[ -n "$system_hostname" ]] || die "--system-hostname is required"
[[ -n "$user_name" ]] || die "--user-name is required"
[[ -n "$user_description" ]] || user_description="$user_name"

require_ident "$flake_host" "--flake-host"
require_ident "$module_prefix" "--module-prefix"

if [[ "$host_dir" = */* ]] || [[ "$host_dir" = .* ]] || [[ "$host_dir" = "" ]]; then
  die "--host-dir must be a simple directory name under modules/hosts"
fi

if [[ ! -f "flake.nix" ]] || [[ ! -d "modules/hosts" ]]; then
  die "run this script from the repo root (needs flake.nix and modules/hosts)"
fi

host_path="modules/hosts/$host_dir"
default_path="$host_path/default.nix"
configuration_path="$host_path/configuration.nix"
identity_path="$host_path/identity.nix"
hardware_path="$host_path/hardware.nix"

existing=()
for path in "$default_path" "$configuration_path" "$identity_path" "$hardware_path"; do
  if [[ -e "$path" ]]; then
    existing+=("$path")
  fi
done

if (( ${#existing[@]} > 0 )) && (( force == 0 )); then
  {
    echo "refusing to overwrite existing files (use --force):"
    printf '  %s\n' "${existing[@]}"
  } >&2
  exit 1
fi

mkdir -p "$host_path"

power_import_line=""
if (( with_power_management == 1 )); then
  power_import_line='      self.nixosModules.powerManagement'
fi

cat > "$default_path" <<EOF
{ self, inputs, ... }: {
  flake.nixosConfigurations.$flake_host = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.${module_prefix}Configuration
    ];
  };
}
EOF

cat > "$configuration_path" <<EOF
{ self, ... }: {
  flake.nixosModules.${module_prefix}Configuration = { ... }: {
    imports = [
      self.nixosModules.${module_prefix}Hardware
      self.nixosModules.${module_prefix}Identity

      self.nixosModules.baseSystem
      self.nixosModules.localeAndTime
      # self.nixosModules.plasmaDesktop
      self.nixosModules.audioPipewire
      self.nixosModules.fontsThai
      self.nixosModules.desktopApps
      self.nixosModules.cliTools
$power_import_line

      self.nixosModules.keyboard
      self.nixosModules.sshAgent
      self.nixosModules.niri
    ];
  };
}
EOF

cat > "$identity_path" <<EOF
{ ... }: {
  flake.nixosModules.${module_prefix}Identity = { pkgs, ... }: {
    networking.hostName = "$system_hostname";

    users.users."$user_name" = {
      isNormalUser = true;
      description = "$user_description";
      extraGroups = [ "networkmanager" "wheel" ];
      packages = with pkgs; [
      ];
    };
  };
}
EOF

hardware_expr=""
hardware_source=""
if command -v nixos-generate-config >/dev/null 2>&1; then
  if hardware_expr="$(nixos-generate-config --show-hardware-config 2>/dev/null)"; then
    hardware_source="nixos-generate-config"
  elif command -v sudo >/dev/null 2>&1 && hardware_expr="$(sudo nixos-generate-config --show-hardware-config 2>/dev/null)"; then
    hardware_source="sudo nixos-generate-config"
  fi
fi

if [[ -n "$hardware_expr" ]]; then
  {
    cat <<EOF
{ self, inputs, ... }: {
  flake.nixosModules.${module_prefix}Hardware =
EOF
    printf '%s\n' "$hardware_expr" | sed 's/^/    /'
    cat <<'EOF'
  ;
}
EOF
  } > "$hardware_path"
else
  cat > "$hardware_path" <<EOF
{ self, inputs, ... }: {
  flake.nixosModules.${module_prefix}Hardware = { config, lib, pkgs, modulesPath, ... }: {
    # TODO: populate from:
    #   sudo nixos-generate-config --show-hardware-config
    imports = [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];
  };
}
EOF
fi

if ! check_out="$(nix eval --json "path:.#nixosConfigurations.${flake_host}.config.networking.hostName" 2>&1)"; then
  {
    echo "generated files, but host eval failed for nixosConfigurations.${flake_host}"
    echo "output:"
    echo "$check_out"
  } >&2
  exit 1
fi

echo "created host scaffold at: $host_path"
echo "files:"
echo "  $default_path"
echo "  $configuration_path"
echo "  $identity_path"
echo "  $hardware_path"
if [[ -n "$hardware_source" ]]; then
  echo "hardware source: $hardware_source"
else
  echo "hardware source: TODO stub (hardware generation command unavailable/failed)"
fi
echo "eval result: $check_out"
echo
echo "next steps:"
echo "  sudo nixos-rebuild build --flake .#${flake_host}"
echo "  sudo nixos-rebuild switch --flake .#${flake_host}"
