#!/bin/bash
set -euo pipefail

vim_runtime="$HOME/.vim_runtime"
vim_source=https://github.com/amix/vimrc.git

if [[ ! -e "$vim_runtime" ]]; then
  git clone --depth=1 "$vim_source" "$vim_runtime"
elif [[ ! -d "$vim_runtime/.git" ]] || \
     [[ "$(git -C "$vim_runtime" remote get-url origin)" != "$vim_source" ]]; then
  echo "Existing $vim_runtime is not the expected amix/vimrc checkout." >&2
  exit 1
fi

if [[ ! -r "$vim_runtime/install_awesome_vimrc.sh" ]]; then
  echo "Missing official Vim installer in $vim_runtime." >&2
  exit 1
fi

# The upstream installer overwrites .vimrc. Preserve any existing file first.
if [[ -e "$HOME/.vimrc" || -L "$HOME/.vimrc" ]]; then
  vim_backup="$(mktemp "$HOME/.vimrc.before-amix.XXXXXX")"
  cp -p "$HOME/.vimrc" "$vim_backup"
  printf 'Previous .vimrc saved to %s\n' "$vim_backup"
fi

sh "$vim_runtime/install_awesome_vimrc.sh"
