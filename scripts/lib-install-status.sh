# Best-effort install step helpers. Included into chezmoi run_ hook templates
# via {{ include }} and sourced directly by regression tests, so this file
# MUST stay dependency-free, MUST NOT exit, and MUST stay macOS bash 3.2
# compatible (no associative arrays, no mapfile).
dotfiles_status_dir="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-install"
dotfiles_ok_dir="$dotfiles_status_dir/ok"

dotfiles_begin_step() {
  mkdir -p "$dotfiles_status_dir" "$dotfiles_ok_dir"
  rm -f "$dotfiles_status_dir/$1.status"
}

dotfiles_record_ok() {
  printf 'ok\n' >"$dotfiles_status_dir/$1.status"
}

dotfiles_record_fail() {
  printf 'fail %s\n' "$2" >"$dotfiles_status_dir/$1.status"
}

# Put Homebrew-managed tools on PATH. Prefers PATH, falls back to the Apple
# Silicon prefix. Returns nonzero when brew is unavailable. Captures the
# shellenv output first: eval alone would mask a failing brew invocation.
dotfiles_load_brew_env() {
  brew_bin="$(command -v brew 2>/dev/null || true)"
  if [[ -z "$brew_bin" && -x /opt/homebrew/bin/brew ]]; then
    brew_bin="/opt/homebrew/bin/brew"
  fi
  if [[ -z "$brew_bin" ]]; then
    return 127
  fi
  brew_env="$("$brew_bin" shellenv)" || return $?
  eval "$brew_env"
}

# Skip-work fast path for expensive idempotent steps. $1 step id,
# $2 input checksum. Returns 0 when the same input already succeeded.
dotfiles_already_ok() {
  local marker="$dotfiles_ok_dir/$1.sha"
  [[ -f "$marker" ]] && [[ "$(cat "$marker")" == "$2" ]]
}

dotfiles_mark_ok() {
  printf '%s' "$2" >"$dotfiles_ok_dir/$1.sha"
}
