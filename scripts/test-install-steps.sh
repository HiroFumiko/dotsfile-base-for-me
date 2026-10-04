#!/bin/bash
# Best-effort regression checks: every step must run even when an earlier one
# fails, statuses must be recorded, and the summary must fail the apply only
# at the end. Uses stub commands and an isolated HOME/state; never touches
# the real install locations or the network.
#
# Scenario exit codes are baked into the stubs at creation time (the stubs
# are plain scripts), so no runtime env plumbing is needed.
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
chezmoi_bin="$(command -v chezmoi)"

render_hook() {
  "$chezmoi_bin" --source "$repo_dir" execute-template "$(cat "$repo_dir/$1")"
}

run_apply() {
  local scenario="$1"
  local fixture="$2"
  local fake_home="$fixture/home"
  local fake_state="$fixture/state"
  local fake_bin="$fixture/bin"
  local brew_rc=0 git_rc=0
  case "$scenario" in
    middle-failure) brew_rc=9 ;;
    zinit-failure) git_rc=7 ;;
  esac
  mkdir -p "$fake_home" "$fake_state" "$fake_bin"
  cat > "$fake_bin/brew" <<EOF
#!/bin/bash
if [[ "\$1" == shellenv ]]; then
  echo 'export PATH="$fake_bin:\$PATH"'
  exit 0
fi
echo "brew \$*"
exit $brew_rc
EOF
  cat > "$fake_bin/mise" <<'EOF'
#!/bin/bash
echo "mise $*"
exit 0
EOF
  cat > "$fake_bin/git" <<EOF
if [[ "\${1:-}" == "-C" ]]; then
  if [[ -d "\$2/.git" ]]; then
    echo "fake-sha-for-test"
    exit 0
  fi
  exit 1
fi
if [[ "\${1:-}" == "clone" ]]; then
  echo "git \$*"
  dest="\${@: -1}"
  # zinit-failure only breaks the zinit clone; vim must still install.
  if [[ "\$dest" == *zinit.git && $git_rc -ne 0 ]]; then
    exit $git_rc
  fi
  mkdir -p "\$dest/.git" "\$dest/vimrcs"
  cat > "\$dest/install_awesome_vimrc.sh" <<'INSTALLER_EOF'
#!/bin/sh
exit 0
INSTALLER_EOF
  mkdir -p "\$HOME/.local/share/zinit/zinit.git"
  exit 0
fi
echo "git \$*"
exit $git_rc
EOF
  cat > "$fake_bin/curl" <<'EOF'
#!/bin/bash
echo "download $*"
out=""
prev=""
for arg in "$@"; do
  if [[ "$prev" == "-o" ]]; then
    out="$arg"
  fi
  prev="$arg"
done
[[ -n "$out" ]] && printf 'stub installer\n' > "$out"
exit 0
EOF
  cat > "$fake_bin/bash" <<EOF
#!/bin/bash
echo "install \$*"
for cli in cursor-agent agent agy claude; do
  printf '#!/bin/bash\nexit 0\n' > "$fake_bin/\$cli"
  chmod +x "$fake_bin/\$cli"
done
exit 0
EOF
  # The vim step invokes the upstream installer via sh(1). Stub it out.
  cat > "$fake_bin/sh" <<'EOF'
#!/bin/bash
echo "sh $*"
mkdir -p "$HOME/.vim_runtime/vimrcs"
for f in basic.vim filetypes.vim plugins_config.vim extended.vim; do
  printf 'stub\n' > "$HOME/.vim_runtime/vimrcs/$f"
done
printf 'stub vimrc\n' > "$HOME/.vimrc"
exit 0
EOF
  chmod +x "$fake_bin"/{brew,mise,git,curl,bash,sh}
  export HOME="$fake_home" XDG_STATE_HOME="$fake_state"
  export PATH="$fake_bin:/usr/bin:/bin"
  for hook in run_before_10-install-zinit.sh.tmpl run_before_15-install-extra-cli.sh.tmpl run_after_20-brew-bundle.sh.tmpl run_after_30-mise-install.sh.tmpl run_after_40-install-vim.sh.tmpl; do
    render_hook "$hook" > "$fixture/hook.sh"
    /bin/bash "$fixture/hook.sh"
  done
  dotfiles_repo_dir="$repo_dir" /bin/bash "$repo_dir/scripts/install-summary.sh"
}

fresh_fixture="$(mktemp -d -t dotfiles-steps-fresh)"
set +e
fresh_output="$(run_apply fresh "$fresh_fixture" 2>&1)"
fresh_rc=$?
set -e
[[ $fresh_rc -eq 0 ]] || { echo "fresh apply should succeed: $fresh_output" >&2; exit 1; }
[[ "$fresh_output" == *'Install summary: 0 failed of 5 steps.'* ]] || { echo "fresh summary wrong: $fresh_output" >&2; exit 1; }

fail_fixture="$(mktemp -d -t dotfiles-steps-fail)"
set +e
fail_output="$(run_apply middle-failure "$fail_fixture" 2>&1)"
fail_rc=$?
set -e
[[ $fail_rc -ne 0 ]] || { echo "brew failure should fail the summary" >&2; exit 1; }
[[ "$fail_output" == *'Install summary: 1 failed of 5 steps.'* ]] || { echo "failure summary wrong: $fail_output" >&2; exit 1; }
[[ "$fail_output" == *'fail    20-brew-bundle'* ]] || { echo "brew step not marked failed: $fail_output" >&2; exit 1; }
[[ "$fail_output" == *'ok      30-mise-install'* ]] || { echo "mise did not run after brew failure: $fail_output" >&2; exit 1; }
[[ "$fail_output" == *'ok      40-vim'* ]] || { echo "vim did not run after brew failure: $fail_output" >&2; exit 1; }
[[ "$(cat "$fail_fixture/state/dotfiles-install/20-brew-bundle.status")" == 'fail exit 9' ]] || { echo "brew status file wrong" >&2; exit 1; }
[[ "$(cat "$fail_fixture/state/dotfiles-install/30-mise-install.status")" == 'ok' ]] || { echo "mise status file wrong" >&2; exit 1; }

zin_fixture="$(mktemp -d -t dotfiles-steps-zinit)"
set +e
zin_output="$(run_apply zinit-failure "$zin_fixture" 2>&1)"
zin_rc=$?
set -e
[[ $zin_rc -ne 0 ]] || { echo "zinit failure should fail the summary" >&2; exit 1; }
[[ "$zin_output" == *'fail    10-zinit'* ]] || { echo "zinit step not marked failed: $zin_output" >&2; exit 1; }
[[ "$zin_output" == *'ok      40-vim'* ]] || { echo "vim did not run after zinit failure: $zin_output" >&2; exit 1; }
echo "Install step regression checks passed. Fixtures: $fresh_fixture $fail_fixture $zin_fixture"
