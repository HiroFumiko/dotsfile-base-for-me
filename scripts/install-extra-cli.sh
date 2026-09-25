#!/bin/bash
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"
installer_file="$(mktemp -t dotfiles-cli-installer)"
trap 'rm -f "$installer_file"' EXIT

install_cli() {
  local cli="$1"
  local url="$2"
  if command -v "$cli" >/dev/null 2>&1; then
    printf 'ok      %s already available\n' "$cli"
    return
  fi

  printf 'Installing %s from %s\n' "$cli" "$url"
  # Download fully before executing; a failed transfer must never run a partial script.
  curl -fsSL "$url" -o "$installer_file"
  bash "$installer_file"
  if ! command -v "$cli" >/dev/null 2>&1; then
    printf 'Installer finished but %s is not on PATH.\n' "$cli" >&2
    exit 1
  fi
}

install_cli cursor-agent https://cursor.com/install
command -v agent >/dev/null 2>&1 || { echo 'Cursor Agent alias agent is missing.' >&2; exit 1; }
install_cli agy https://antigravity.google/cli/install.sh
install_cli claude https://claude.ai/install.sh
