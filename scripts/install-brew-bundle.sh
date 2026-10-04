#!/bin/bash
# Apply the global Brewfile. Skips when the rendered Brewfile checksum matches
# the last success. Needs DOTFILES_INPUT_CHECKSUM from the hook wrapper and
# lib-install-status.sh loaded by the caller. Exits nonzero on failure; the
# hook wrapper records the outcome and always continues with the next step.
set -euo pipefail

step="20-brew-bundle"
if [[ -n "${DOTFILES_INPUT_CHECKSUM:-}" ]] && dotfiles_already_ok "$step" "$DOTFILES_INPUT_CHECKSUM"; then
  printf 'ok      brew bundle (Brewfile unchanged, skipping)\n'
  exit 0
fi
brew bundle --global
if [[ -n "${DOTFILES_INPUT_CHECKSUM:-}" ]]; then
  dotfiles_mark_ok "$step" "$DOTFILES_INPUT_CHECKSUM"
fi
