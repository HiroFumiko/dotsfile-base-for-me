#!/bin/bash
# Print the per-step outcome of the last chezmoi apply. Exits nonzero when
# any step failed or never reported, so bootstrap/checks can surface it.
# Included by the run_after_99 hook (which presets dotfiles_repo_dir) and run
# directly by regression tests (which resolve the repo via BASH_SOURCE).
set -euo pipefail

repo_dir="${dotfiles_repo_dir:-$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)}"
status_dir="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-install"
steps_file="$repo_dir/scripts/install-steps.txt"

failures=0
total=0
while IFS='|' read -r step label || [[ -n "${step:-}" ]]; do
  if [[ -z "$step" ]]; then
    continue
  fi
  total=$((total + 1))
  status_file="$status_dir/$step.status"
  if [[ -f "$status_file" ]]; then
    detail="$(cat "$status_file")"
  else
    detail="missing (step did not report)"
  fi
  case "$detail" in
    ok*)
      printf 'ok      %s %s\n' "$step" "$label"
      ;;
    *)
      printf 'fail    %s %s (%s)\n' "$step" "$label" "$detail"
      failures=$((failures + 1))
      ;;
  esac
done < "$steps_file"

printf '\nInstall summary: %d failed of %d steps.\n' "$failures" "$total"
if (( failures > 0 )); then
  printf 'Fix the causes above, then re-run: chezmoi apply\n'
  exit 1
fi
printf 'All install steps succeeded.\n'
