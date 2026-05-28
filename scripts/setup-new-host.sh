#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/setup-new-host.sh
  scripts/setup-new-host.sh --interactive
  scripts/setup-new-host.sh \
    --host-dir <name> \
    --system-hostname <hostname> \
    --user-name <name> \
    [--flake-host <Name>] \
    [--module-prefix <Prefix>] \
    [--user-description <text>] \
    [--with-power-management] \
    [--force]

Required:
  --host-dir            Directory under modules/hosts (e.g. desktop-main)
  --system-hostname     networking.hostName value
  --user-name           users.users attr name

Optional:
  --flake-host          default: derived from host-dir (e.g. desktop-main -> desktopMain)
  --module-prefix       default: same as flake-host
  --interactive         ask questions step-by-step
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

prompt_with_default() {
  local __var_name="$1"
  local prompt="$2"
  local default="${3-}"
  local input=""

  while true; do
    if [[ -n "$default" ]]; then
      read -r -p "$prompt [$default]: " input || exit 1
      input="${input:-$default}"
    else
      read -r -p "$prompt: " input || exit 1
    fi

    if [[ -n "$input" ]]; then
      printf -v "$__var_name" '%s' "$input"
      return 0
    fi

    echo "value is required"
  done
}

prompt_yes_no() {
  local __var_name="$1"
  local prompt="$2"
  local default="${3:-n}"
  local input=""

  while true; do
    read -r -p "$prompt [y/n] (default: $default): " input || exit 1
    input="${input:-$default}"
    case "$input" in
      y|Y|yes|YES)
        printf -v "$__var_name" '1'
        return 0
        ;;
      n|N|no|NO)
        printf -v "$__var_name" '0'
        return 0
        ;;
      *)
        echo "please answer y or n"
        ;;
    esac
  done
}

require_ident() {
  local value="$1"
  local label="$2"
  if [[ ! "$value" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
    die "$label must match ^[A-Za-z_][A-Za-z0-9_]*$, got: $value"
  fi
}

derive_camel_ident() {
  local value="$1"
  value="$(echo "$value" | tr -cs '[:alnum:]' ' ')"
  read -r -a words <<<"$value"
  [[ ${#words[@]} -gt 0 ]] || return 1

  local out="${words[0],,}"
  local i w
  for (( i = 1; i < ${#words[@]}; i++ )); do
    w="${words[i],,}"
    out+="${w^}"
  done

  if [[ ! "$out" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
    return 1
  fi

  printf '%s' "$out"
}

host_dir=""
flake_host=""
module_prefix=""
system_hostname=""
user_name=""
user_description=""
with_power_management=0
force=0
interactive=0
arg_count=$#

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
    --interactive)
      interactive=1
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

if (( arg_count == 0 )); then
  interactive=1
fi

if (( interactive == 1 )); then
  echo "setup-new-host wizard"
  echo

  prompt_with_default host_dir "Host directory (under modules/hosts)" "${host_dir:-}"
  if [[ -z "$flake_host" ]]; then
    flake_host="$(derive_camel_ident "$host_dir" || true)"
  fi
  prompt_with_default flake_host "Flake host attr name (nixosConfigurations.<Name>)" "${flake_host:-}"
  prompt_with_default module_prefix "Module prefix (nixosModules.<Prefix>...)" "${module_prefix:-$flake_host}"
  prompt_with_default system_hostname "System hostname" "${system_hostname:-$host_dir}"
  prompt_with_default user_name "User name" "${user_name:-${USER:-me}}"
  prompt_with_default user_description "User description" "${user_description:-$user_name}"

  if (( with_power_management == 1 )); then
    prompt_yes_no with_power_management "Include power management module?" "y"
  else
    prompt_yes_no with_power_management "Include power management module?" "n"
  fi
else
  [[ -n "$host_dir" ]] || die "--host-dir is required"
  [[ -n "$system_hostname" ]] || die "--system-hostname is required"
  [[ -n "$user_name" ]] || die "--user-name is required"
  if [[ -z "$flake_host" ]]; then
    flake_host="$(derive_camel_ident "$host_dir")" || die "could not derive --flake-host from --host-dir; set --flake-host explicitly"
  fi
  if [[ -z "$module_prefix" ]]; then
    module_prefix="$flake_host"
  fi
  [[ -n "$user_description" ]] || user_description="$user_name"
fi

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
  if (( interactive == 1 )); then
    echo "these files already exist:"
    printf '  %s\n' "${existing[@]}"
    prompt_yes_no force "Overwrite these files?" "n"
  fi

  if (( force == 0 )); then
    {
      echo "refusing to overwrite existing files (use --force):"
      printf '  %s\n' "${existing[@]}"
    } >&2
    exit 1
  fi
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
