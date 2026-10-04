#!/bin/bash
# Install the Zinit plugin manager. Exits nonzero on failure; the run_ hook
# wrapper records the outcome and always continues with the next step.
set -euo pipefail

zinit_home="$HOME/.local/share/zinit/zinit.git"
if [[ -d "$zinit_home/.git" ]]; then
  printf 'ok      zinit already present\n'
  exit 0
fi
mkdir -p "$(dirname "$zinit_home")"
git clone https://github.com/zdharma-continuum/zinit.git "$zinit_home"
