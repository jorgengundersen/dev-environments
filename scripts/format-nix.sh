#!/usr/bin/env bash
set -euo pipefail

if ! command -v git >/dev/null 2>&1; then
  echo "Error: git is required but not found in PATH." >&2
  exit 1
fi

if ! command -v nixfmt >/dev/null 2>&1; then
  echo "Error: nixfmt is required but not found in PATH." >&2
  exit 1
fi

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

mapfile -d '' -t nix_files < <(git -C "${repo_root}" ls-files -z '*.nix')

if ((${#nix_files[@]} == 0)); then
  echo "No tracked .nix files found."
  exit 0
fi

echo "Formatting ${#nix_files[@]} .nix file(s) with nixfmt"
(
  cd -- "${repo_root}"
  nixfmt "${nix_files[@]}"
)
