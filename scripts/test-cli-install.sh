#!/bin/bash
# Mock vendor installers: never download or install tools on this Mac.
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
    echo "download" >&2
    case "$2" in
      https://cursor.com/install) pending_cli='cursor-agent agent' ;;
      https://antigravity.google/cli/install.sh) pending_cli=agy ;;
      https://claude.ai/install.sh) pending_cli=claude ;;
      *) return 99 ;;
    esac
    [[ "$scenario" != *download-failure ]] || return 22
    # mktemp already created the empty file; bash below is also a mock.
  }
  bash() {
    echo "install" >&2
    [[ "$scenario" != *install-failure ]] || return 7
    if [[ "$scenario" != *missing-command ]]; then
      installed="$installed $pending_cli"
    fi
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
echo 'CLI installer regression checks passed.'
