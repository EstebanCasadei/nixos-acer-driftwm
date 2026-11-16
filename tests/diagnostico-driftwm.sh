#!/usr/bin/env bash
set -euo pipefail

script=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/diagnostico-driftwm.sh
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
export XDG_STATE_HOME="$scratch/state" CALLS="$scratch/calls"

tty() { echo /dev/tty3; }
systemctl() { [[ $GREETD_ACTIVE == true ]]; }
sudo() { printf '%s\n' "$*" >>"$CALLS"; }
driftwm() { return 1; }
nixos-version() { echo test; }
dbus-run-session() {
  [[ $RUST_LOG == driftwm=debug,smithay=debug && $* == '-- timeout --foreground --kill-after=5s 20s driftwm --backend udev' ]] || return 99
  echo 'No GPU with connected displays found'
  return 1
}
export -f tty systemctl sudo driftwm nixos-version dbus-run-session

GREETD_ACTIVE=true bash "$script" >"$scratch/output"
[[ $(cat "$CALLS") == $'systemctl stop greetd.service\nsystemctl start greetd.service' ]]
grep -q 'Código de salida `1`' "$XDG_STATE_HOME"/driftwm/*.md
grep -q 'No GPU with connected displays found' "$XDG_STATE_HOME"/driftwm/*.md
publish=$(sed -n '/^  if \[\[/,/^  fi/p' "$scratch/output")
gh() {
  case "$1 $2" in
    'repo view') echo "$PRIVATE" ;;
    'issue create') echo 'issue create' >>"$CALLS" ;;
    *) return 1 ;;
  esac
}
export -f gh

: >"$CALLS"
GREETD_ACTIVE=false bash "$script" >/dev/null
PRIVATE=false bash -c "$publish" >/dev/null
[[ ! -s $CALLS ]]
PRIVATE=true bash -c "$publish"
[[ $(cat "$CALLS") == 'issue create' ]]
