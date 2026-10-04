#!/bin/bash
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"

if ! xcode-select -p >/dev/null 2>&1; then
  echo "Xcode Command Line Tools are required. Starting the installer..."
  xcode-select --install
  echo "Finish the installer, then run this script again."
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  homebrew_installer="$(mktemp -t dotfiles-homebrew)"
  trap 'rm -f "$homebrew_installer"' EXIT
  curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$homebrew_installer"
  /bin/bash "$homebrew_installer"
fi

eval "$(/opt/homebrew/bin/brew shellenv)"
brew install chezmoi

chezmoi --source "$repo_dir" init
chezmoi diff
# Every install step runs even when an earlier one fails; apply exits nonzero
# when the final summary reports a failure. Surface that instead of aborting
# silently under set -e so the user sees which steps need a re-run.
set +e
chezmoi apply --verbose
apply_rc=$?
set -e
if (( apply_rc != 0 )); then
  echo "chezmoi apply finished with failures (exit $apply_rc)."
  echo "See the install summary above, fix the causes, then re-run: chezmoi apply"
  exit "$apply_rc"
fi

echo "Installation complete. See docs/post-install-checklist.md for manual checks."
