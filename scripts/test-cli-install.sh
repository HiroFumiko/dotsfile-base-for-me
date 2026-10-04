#!/bin/bash
# Mock vendor installers: never download or install tools on this Mac.
# Also covers the new best-effort behavior: a failing CLI must not prevent
# later CLIs from being attempted.
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")/.." && pwd)"

run_case() (
  scenario="$1"
  installed=""
  command() {
    if [[ "${1:-}" == -v ]]; then
      case "${2:-}" in
        cursor-agent|agent|agy|claude)
          if [[ "$scenario" == claude-* && "$2" != claude ]]; then return 0; fi
          [[ "$scenario" == existing || " $installed " == *" $2 "* ]]
          return
          ;;
      esac
    fi
    builtin command "$@"
  }
  curl() {
    echo "download $2" >&2
    case "$2" in
      https://cursor.com/install) pending_cli='cursor-agent agent' ;;
      https://antigravity.google/cli/install.sh) pending_cli=agy ;;
      https://claude.ai/install.sh) pending_cli=claude ;;
      *) return 99 ;;
    esac
    case "$scenario" in
      *download-failure) return 22 ;;
      cursor-download-failure) [[ "$2" != https://cursor.com/install ]] || return 22 ;;
    esac
    # mktemp already created the empty file; bash below is also a mock.
  }
  bash() {
    echo "install $pending_cli" >&2
    case "$scenario" in
      *install-failure) return 7 ;;
      cursor-install-failure) [[ "$pending_cli" != *cursor-agent* ]] || return 7 ;;
    esac
    case "$scenario" in
      *missing-command|claude-missing-command) ;;
      cursor-missing-command) [[ "$pending_cli" != *cursor-agent* ]] || return 0 ;;
      *) installed="$installed $pending_cli" ;;
    esac
  }
  source "$repo_dir/scripts/install-extra-cli.sh"
)

output=$(run_case existing 2>&1)
[[ "$output" != *download* && "$output" != *install* ]]
output=$(run_case fresh 2>&1)
[[ "$output" == *download* && "$output" == *install* ]]
[[ "$output" == *'Installing cursor-agent'* && "$output" == *'Installing agy'* ]]
[[ "$output" == *'Installing claude from https://claude.ai/install.sh'* ]] || { echo 'Claude installer was not invoked.' >&2; exit 1; }
for scenario in download-failure install-failure missing-command claude-download-failure claude-install-failure claude-missing-command; do
  set +e
  output=$(run_case "$scenario" 2>&1)
  result=$?
  set -e
  [[ $result -ne 0 ]] || { echo "Expected failure: $scenario" >&2; exit 1; }
  if [[ "$scenario" == *download-failure ]]; then
    [[ "$output" != *$'\ninstall'* ]]
  fi
done
# A first-CLI failure must not skip the remaining CLIs.
for scenario in cursor-download-failure cursor-install-failure cursor-missing-command; do
  set +e
  output=$(run_case "$scenario" 2>&1)
  result=$?
  set -e
  [[ $result -ne 0 ]] || { echo "Expected failure: $scenario" >&2; exit 1; }
  [[ "$output" == *'download https://antigravity.google/cli/install.sh'* ]] || { echo "agy skipped after cursor failure: $scenario" >&2; exit 1; }
  [[ "$output" == *'download https://claude.ai/install.sh'* ]] || { echo "claude skipped after cursor failure: $scenario" >&2; exit 1; }
done
echo 'CLI installer regression checks passed.'
