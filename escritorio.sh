#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID == 0 ]]; then
  echo 'Ejecuta este script con tu usuario habitual.' >&2
  exit 1
fi

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
sudo nixos-rebuild test --flake "path:$PWD#nixos" --no-update-lock-file

source_config=/etc/driftwm/acer.toml
driftwm --config "$source_config" --check-config
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/driftwm"
config="$config_dir/config.toml"
mkdir -p -- "$config_dir"

if [[ $(readlink -- "$config" || true) != "$source_config" ]]; then
  if [[ -d $config && ! -L $config ]]; then
    printf 'Se esperaba un archivo en %s, pero existe un directorio.\n' "$config" >&2
    exit 1
  fi
  if [[ -e $config || -L $config ]]; then
    backup=$(mktemp -d "$config_dir/respaldo.XXXXXX")
    cp -a -- "$config" "$backup/config.toml"
    printf 'Configuración anterior guardada en %s/config.toml\n' "$backup"
  fi
  ln -sfnT -- "$source_config" "$config"
fi

echo 'Vuelve a iniciar sesión en driftwm para probar el teclado, la barra y las notificaciones.'
