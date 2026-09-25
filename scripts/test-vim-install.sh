#!/bin/bash
# Exercise the installer in a temporary directory with Git and upstream sh mocked.
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
vim_fixture="$(mktemp -d -t dotfiles-vim-test)"
script_body="$(<"$repo_dir/scripts/install-vim.sh")"
# Redirect only the installer's destination paths; never change the real HOME.
script_body="${script_body//\$HOME/\$vim_test_home}"

run_case() (
  scenario="$1"
  vim_test_home="$vim_fixture/$scenario"
  mkdir -p "$vim_test_home"
  if [[ "$scenario" == existing || "$scenario" == foreign ]]; then
    mkdir -p "$vim_test_home/.vim_runtime/.git"
    cp "$repo_dir/scripts/install-vim.sh" "$vim_test_home/.vim_runtime/install_awesome_vimrc.sh"
    cp "$repo_dir/README.md" "$vim_test_home/.vimrc"
  fi
  git() {
    if [[ "$1" == clone ]]; then
      [[ "$scenario" != clone-failure ]] || return 9
      [[ "$*" == "clone --depth=1 https://github.com/amix/vimrc.git $vim_test_home/.vim_runtime" ]]
      mkdir -p "$vim_test_home/.vim_runtime/.git"
      cp "$repo_dir/scripts/install-vim.sh" "$vim_test_home/.vim_runtime/install_awesome_vimrc.sh"
    elif [[ "$scenario" == foreign ]]; then
      echo 'https://example.invalid/other.git'
    else
      echo 'https://github.com/amix/vimrc.git'
    fi
  }
  sh() {
    [[ "$1" == "$vim_test_home/.vim_runtime/install_awesome_vimrc.sh" ]]
    cp "$1" "$vim_test_home/.vimrc"
  }
  eval "$script_body"
  cmp "$vim_test_home/.vimrc" "$repo_dir/scripts/install-vim.sh"
  if [[ "$scenario" == existing ]]; then
    cmp "$repo_dir/README.md" "$vim_test_home"/.vimrc.before-amix.*
  fi
)

run_case fresh
run_case existing
for scenario in foreign clone-failure; do
  set +e
  (set -e; run_case "$scenario")
  result=$?
  set -e
  [[ $result -ne 0 ]]
done
cmp "$repo_dir/README.md" "$vim_fixture/foreign/.vimrc"
echo "Vim installer regression checks passed. Fixtures: $vim_fixture"
