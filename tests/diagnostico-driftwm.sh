#!/usr/bin/env bash
set -euo pipefail

script=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/diagnostico-driftwm.sh
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
export XDG_STATE_HOME="$scratch/state" CALLS="$scratch/calls"

tty() { echo /dev/tty3; }
systemctl() { [[ $GREETD_ACTIVE == true ]]; }
sudo() {
  if [[ $* == 'timeout 10s cat -- /dev/input/event7' ]]; then
    printf 'events'
    return 124
  fi
  if [[ $* == 'journalctl -k -b --no-pager' ]]; then
    printf 'i2c_hid_acpi i2c-PIXA3848: failed probe\nLog unrelated\n'
    return
  fi
  printf '%s\n' "$*" >>"$CALLS"
}
udevadm() { printf 'E: DEVNAME=/dev/input/event2\nE: ID_INPUT_KEYBOARD=1\n\nE: DEVNAME=/dev/input/event7\nE: ID_INPUT_TOUCHPAD=1\n'; }
driftwm() { return 1; }
nixos-version() { echo test; }
find() { printf '%s\n' 'i2c-PIXA3848:01'; }
dbus-run-session() {
  [[ $RUST_LOG == driftwm=debug,smithay=debug && $* == '-- timeout --foreground --kill-after=5s 20s driftwm --backend udev' ]] || return 99
  echo 'No GPU with connected displays found'
  return 1
}
gh() {
  [[ $GH_PROMPT_DISABLED == 1 && $1 == issue && $2 == create ]] || return 99
  [[ $3 == --repo && $4 == EstebanCasadei/nixos-acer-driftwm && $7 == --body-file ]] || return 99
  grep -Eq 'No GPU with connected displays found|event7: 6 bytes recibidos' "$8" || return 99
  echo 'issue create' >>"$CALLS"
  [[ $UPLOAD_OK == true ]] || return 1
  echo 'https://github.com/EstebanCasadei/nixos-acer-driftwm/issues/123'
}
export -f tty systemctl sudo udevadm driftwm nixos-version find dbus-run-session gh

UPLOAD_OK=true GREETD_ACTIVE=true bash "$script" >"$scratch/output"
[[ $(cat "$CALLS") == $'systemctl stop greetd.service\nsystemctl start greetd.service\nissue create' ]]
grep -q 'Código de salida `1`' "$XDG_STATE_HOME"/driftwm/*.md
grep -q '/issues/123' "$scratch/output"

: >"$CALLS"
if XDG_STATE_HOME="$scratch/failure" UPLOAD_OK=false GREETD_ACTIVE=false bash "$script" >"$scratch/error" 2>&1; then
  exit 1
fi
[[ $(cat "$CALLS") == 'issue create' ]]
grep -q 'Falló el envío' "$scratch/error"
grep -q 'No GPU with connected displays found' "$scratch/failure"/driftwm/*.md

XDG_STATE_HOME="$scratch/touchpad" UPLOAD_OK=true GREETD_ACTIVE=false bash "$(dirname -- "$script")/pad.sh" >"$scratch/output"
grep -q '/sys/bus/i2c/drivers/i2c_hid_acpi i2c-PIXA3848:01' "$CALLS"
grep -q 'Reinicio del controlador completado' "$scratch/touchpad"/driftwm/*.md
grep -q 'event7: 6 bytes recibidos' "$scratch/touchpad"/driftwm/*.md
grep -q 'Mensajes de error del controlador detectados: 1' "$scratch/touchpad"/driftwm/*.md
if grep -Eq 'failed probe|Log unrelated' "$scratch/touchpad"/driftwm/*.md; then exit 1; fi
grep -q '/issues/123' "$scratch/output"
