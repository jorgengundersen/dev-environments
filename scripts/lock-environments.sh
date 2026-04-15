#!/usr/bin/env bash
set -euo pipefail

if ! command -v nix >/dev/null 2>&1; then
  echo "Error: nix is required but not found in PATH." >&2
  exit 1
fi

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
environments_dir="${repo_root}/environments"

use_update=0
lock_args=()

for arg in "$@"; do
  if [[ "${arg}" == "--recreate-lock-file" ]]; then
    use_update=1
    continue
  fi
  lock_args+=("${arg}")
done

if ((use_update == 1)); then
  echo "Info: '--recreate-lock-file' is deprecated in Nix; using 'nix flake update' instead."
fi

shopt -s nullglob
environment_dirs=("${environments_dir}"/*)
shopt -u nullglob

if ((${#environment_dirs[@]} == 0)); then
  echo "No environment directories found in ${environments_dir}."
  exit 0
fi

locked=0

for environment_dir in "${environment_dirs[@]}"; do
  if [[ ! -d "${environment_dir}" || ! -f "${environment_dir}/flake.nix" ]]; then
    continue
  fi

  locked=$((locked + 1))
  environment_name="$(basename -- "${environment_dir}")"

  if ((use_update == 1)); then
    echo "[${locked}] nix flake update --flake ./environments/${environment_name} ${lock_args[*]}"
    nix flake update --flake "${environment_dir}" "${lock_args[@]}"
  else
    echo "[${locked}] nix flake lock ./environments/${environment_name} ${lock_args[*]}"
    nix flake lock "${lock_args[@]}" "${environment_dir}"
  fi
done

if ((locked == 0)); then
  echo "No environment flakes found under ${environments_dir}."
  exit 1
fi

echo "Updated lock files for ${locked} environment flake(s)."
