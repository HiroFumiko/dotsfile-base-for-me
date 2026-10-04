#!/bin/bash
# Install mise-managed language runtimes. Skips when the rendered mise config
# checksum matches the last success. Needs DOTFILES_INPUT_CHECKSUM from the
# hook wrapper and lib-install-status.sh loaded by the caller. Exits nonzero
# on failure; the hook wrapper records the outcome and always continues.
set -euo pipefail

step="30-mise-install"
if [[ -n "${DOTFILES_INPUT_CHECKSUM:-}" ]] && dotfiles_already_ok "$step" "$DOTFILES_INPUT_CHECKSUM"; then
  printf 'ok      mise install (config unchanged, skipping)\n'
  exit 0
fi
mise install --yes
if [[ -n "${DOTFILES_INPUT_CHECKSUM:-}" ]]; then
  dotfiles_mark_ok "$step" "$DOTFILES_INPUT_CHECKSUM"
fi
