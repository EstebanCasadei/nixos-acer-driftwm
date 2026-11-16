#!/usr/bin/env bash
set -euo pipefail

script=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/escritorio.sh
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
export XDG_CONFIG_HOME="$scratch" CALLS="$scratch/calls"

sudo() { [[ $* == 'nixos-rebuild test --flake path:'*'#nixos --no-update-lock-file' ]]; }
driftwm() { [[ $* == '--config /etc/driftwm/acer.toml --check-config' && $CONFIG_OK == true ]]; }
ln() { printf '%s\n' "$*" >"$CALLS"; }
export -f sudo driftwm ln

mkdir "$scratch/driftwm"
printf 'personal\n' >"$scratch/driftwm/config.toml"
if CONFIG_OK=false bash "$script"; then exit 1; fi
[[ ! -e $CALLS ]]
CONFIG_OK=true bash "$script"
grep -qx personal "$scratch"/driftwm/respaldo.*/config.toml
grep -Fq '/etc/driftwm/acer.toml' "$CALLS"
