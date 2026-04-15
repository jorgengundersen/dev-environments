#!/usr/bin/env bash
set -euo pipefail

if ! command -v nix >/dev/null 2>&1; then
  echo "Error: nix is required but not found in PATH." >&2
  exit 1
fi

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Running nix flake check for ./environments/default"
nix flake check "${repo_root}/environments/default"
