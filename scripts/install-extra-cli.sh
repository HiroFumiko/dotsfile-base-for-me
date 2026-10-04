#!/bin/bash
# Best-effort installer: each CLI is attempted even when an earlier one fails.
# The run_before_15 hook records the overall outcome; exit status is nonzero
# when any CLI is still unavailable. Keeps set -e semantics for unexpected
# errors outside install_cli by guarding only the per-CLI invocations.
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"
installer_file="$(mktemp -t dotfiles-cli-installer)"
trap 'rm -f "$installer_file"' EXIT
failures=0

install_cli() {
  local cli="$1"
  local url="$2"
  if command -v "$cli" >/dev/null 2>&1; then
    printf 'ok      %s already available\n' "$cli"
    return
  fi

  printf 'Installing %s from %s\n' "$cli" "$url"
  # Download fully before executing; a failed transfer must never run a partial script.
  curl -fsSL "$url" -o "$installer_file" || return 1
  bash "$installer_file" || return 1
  command -v "$cli" >/dev/null 2>&1
}

install_cli cursor-agent https://cursor.com/install || failures=$((failures + 1))
if ! command -v agent >/dev/null 2>&1; then
  echo 'Cursor Agent alias agent is missing.' >&2
  failures=$((failures + 1))
fi
install_cli agy https://antigravity.google/cli/install.sh || failures=$((failures + 1))
install_cli claude https://claude.ai/install.sh || failures=$((failures + 1))

if (( failures > 0 )); then
  printf '%d extra CLI(s) unavailable.\n' "$failures" >&2
  exit 1
fi
