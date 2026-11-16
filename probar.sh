#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
nix flake lock "path:$PWD"
sudo nixos-rebuild test --flake "path:$PWD#nixos" --no-update-lock-file
bash ./diagnostico-driftwm.sh
