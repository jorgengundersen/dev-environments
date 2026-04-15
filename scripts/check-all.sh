#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v git >/dev/null 2>&1; then
  echo "Error: git is required but not found in PATH." >&2
  exit 1
fi

echo "Running repository checks"
"${repo_root}/scripts/check-environment-flakes.sh"

if command -v nixfmt >/dev/null 2>&1; then
  echo "Checking Nix formatting"
  mapfile -d '' -t nix_files < <(git -C "${repo_root}" ls-files -z '*.nix')
  if ((${#nix_files[@]} > 0)); then
    (
      cd -- "${repo_root}"
      nixfmt --check "${nix_files[@]}"
    )
  fi
else
  echo "Skipping nixfmt --check (nixfmt not found in PATH)"
fi

if command -v statix >/dev/null 2>&1; then
  echo "Running statix"
  statix check "${repo_root}"
else
  echo "Skipping statix (not found in PATH)"
fi

if command -v deadnix >/dev/null 2>&1; then
  echo "Running deadnix"
  deadnix --fail "${repo_root}"
else
  echo "Skipping deadnix (not found in PATH)"
fi

echo "All requested checks finished."
