#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID == 0 || ! $(tty) =~ ^/dev/tty[0-9]+$ ]]; then
  echo 'Ejecuta este script con tu usuario habitual desde una TTY del Acer.' >&2
  exit 1
fi

if [[ ${1:-} != touchpad ]] && ! command -v driftwm >/dev/null; then
  echo 'driftwm no está disponible en la sesión actual.' >&2
  exit 1
fi

umask 077
report_dir="${XDG_STATE_HOME:-$HOME/.local/state}/driftwm"
mkdir -p -- "$report_dir"
report=$(mktemp "$report_dir/diagnostico-XXXXXX.md")
log=$(mktemp)
restore_greetd=false

cleanup() {
  rm -f -- "$log"
  if "$restore_greetd" && ! sudo systemctl start greetd.service; then
    echo 'No se pudo restaurar greetd. Ejecuta sudo systemctl start greetd.service.' >&2
    exit 1
  fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

if systemctl is-active --quiet greetd.service; then
  restore_greetd=true
  sudo systemctl stop greetd.service
fi

status=0
if [[ ${1:-} == touchpad ]]; then
  section='Eventos del touchpad'
  title='Diagnóstico del touchpad en el Acer'
  device=$(udevadm info --export-db | awk -v RS='' '
    /(^|\n)E: ID_INPUT_TOUCHPAD=1(\n|$)/ && match($0, /E: DEVNAME=\/dev\/input\/event[0-9]+/) && !found {
      print substr($0, RSTART + 11, RLENGTH - 11)
      found = 1
    }
  ')
  if [[ -n $device ]]; then
    sudo -v
    echo 'Mueve un dedo por el touchpad durante 10 segundos.'
    bytes=$(sudo timeout 10s cat -- "$device" | wc -c) || status=$?
    printf '%s: %s bytes recibidos del kernel\n' "$device" "$bytes" >"$log"
  else
    echo 'udev no enumeró ningún dispositivo como touchpad.' >"$log"
  fi
else
  section='Arranque de driftwm'
  title='Diagnóstico de driftwm en el Acer'
  echo 'Probando driftwm durante un máximo de 20 segundos.'
  RUST_LOG=driftwm=debug,smithay=debug dbus-run-session -- \
    timeout --foreground --kill-after=5s 20s driftwm --backend udev >"$log" 2>&1 || status=$?
fi

{
  printf '## Sistema\n\n- NixOS `%s`\n- Kernel `%s`\n' "$(nixos-version)" "$(uname -r)"
  printf '\n## GPU y conectores\n\n'
  if command -v lspci >/dev/null; then
    lspci -nnk | grep -EA3 'VGA|3D|Display' | sed 's/^/    /' || true
  else
    ls -l /sys/class/drm/card*/device/driver 2>/dev/null | sed 's/^/    /' || true
  fi
  grep -H . /sys/class/drm/card*-*/status 2>/dev/null | sed 's/^/    /' || true
  printf '\n## %s\n\nCódigo de salida `%s` (124 indica que se alcanzó el límite de tiempo).\n\n' "$section" "$status"
  tail -n 60 -- "$log" | sed 's/^/    /'
} >"$report"

printf '\nInforme guardado en %s\n' "$report"
trap - EXIT
cleanup

github=(gh)
if ! command -v gh >/dev/null; then
  github=(nix shell nixpkgs#gh --command gh)
fi

echo 'Publicando el informe en GitHub…'
if ! GH_PROMPT_DISABLED=1 "${github[@]}" issue create \
  --repo EstebanCasadei/nixos-acer-driftwm \
  --title "$title" --body-file "$report"; then
  echo 'Falló el envío. El informe sigue guardado en el Acer.' >&2
  exit 1
fi
