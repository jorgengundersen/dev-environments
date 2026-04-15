#!/usr/bin/env bash
set -euo pipefail

if ! command -v nix >/dev/null 2>&1; then
  echo "Error: nix is required but not found in PATH." >&2
  exit 1
fi

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
environments_dir="${repo_root}/environments"

shopt -s nullglob
environment_dirs=("${environments_dir}"/*)
shopt -u nullglob

if ((${#environment_dirs[@]} == 0)); then
  echo "No environment directories found in ${environments_dir}."
  exit 0
fi

checked=0

for environment_dir in "${environment_dirs[@]}"; do
  if [[ ! -d "${environment_dir}" || ! -f "${environment_dir}/flake.nix" ]]; then
    continue
  fi

  checked=$((checked + 1))
  environment_name="$(basename -- "${environment_dir}")"

  echo "[${checked}] nix flake check ./environments/${environment_name}"
  nix flake check "${environment_dir}"
done

if ((checked == 0)); then
  echo "No environment flakes found under ${environments_dir}."
  exit 1
fi

echo "Checked ${checked} environment flake(s)."
