#!/bin/bash
set -euo pipefail

failures=0

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
export PATH="$HOME/.local/bin:$PATH"

check_command() {
  if command -v "$1" >/dev/null 2>&1; then
    printf 'ok      %s\n' "$1"
  else
    printf 'missing %s\n' "$1"
    failures=$((failures + 1))
  fi
}

for command_name in brew chezmoi git gh vim mise node npm rustc cargo tmux uv agent cursor-agent agy claude; do
  check_command "$command_name"
done

for vim_file in "$HOME/.vimrc" "$HOME/.vim_runtime/install_awesome_vimrc.sh" \
  "$HOME/.vim_runtime/vimrcs/basic.vim" "$HOME/.vim_runtime/vimrcs/filetypes.vim" \
  "$HOME/.vim_runtime/vimrcs/plugins_config.vim" "$HOME/.vim_runtime/vimrcs/extended.vim"; do
  if [[ ! -r "$vim_file" ]]; then
    printf 'missing %s\n' "$vim_file"
    failures=$((failures + 1))
  fi
done

if command -v brew >/dev/null 2>&1; then
  if brew bundle check --global; then
    echo "ok      Brewfile"
  else
    echo "missing Brewfile packages"
    failures=$((failures + 1))
  fi
fi

if (( failures > 0 )); then
  echo "$failures checks failed."
  exit 1
fi

echo "Installation presence check passed. App operation must be checked manually."
