#!/bin/zsh -f
# Verify completion initialization in two independent interactive shells without
# loading host plugins, secrets, runtimes, or prompt configuration.
set -eu

repo_dir=${0:A:h:h}
test_zdotdir=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-completion.XXXXXX")
trap 'rm -rf -- "$test_zdotdir"' EXIT INT TERM
mkdir "$test_zdotdir/completions"
# Only readability is needed; source() below intercepts this fixture.
cp "$repo_dir/scripts/test-completion.zsh" "$test_zdotdir/mock-zinit.zsh"

cat > "$test_zdotdir/completions/_dotfiles-review" <<'EOF'
#compdef dotfiles-review
_arguments '*:argument:->args'
EOF

cat > "$test_zdotdir/.zshrc" <<EOF
repo_dir=${(q)repo_dir}

zinit() {
  if [[ \$* == 'light zsh-users/zsh-completions' ]]; then
    fpath=("\$ZDOTDIR/completions" \$fpath)
  fi
}
mise() { print ':'; }

source() {
  case \$1 in
    (\$ZDOTDIR/mock-zinit.zsh|\$HOME/.p10k.zsh|/opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme|\$HOME/.config/zsh/personal.zsh|\$HOME/.config/zsh/local.zsh|*/p10k-instant-prompt-*.zsh)
      return 0
      ;;
    (*)
      print -u2 -- "Unexpected source: \$1"
      exit 1
      ;;
  esac
}

rc_text=\$(<"\$repo_dir/dot_zshrc")
original_zinit_path='\$HOME/.local/share/zinit/zinit.git/zinit.zsh'
fixture_zinit_path='\$ZDOTDIR/mock-zinit.zsh'
rc_text=\${rc_text//\$original_zinit_path/\$fixture_zinit_path}
eval "\$rc_text"
EOF

for run_number in 1 2; do
  env -u FPATH ZDOTDIR="$test_zdotdir" zsh -d -i -c '
    set -e
    (( ${+_comps} ))
    (( ${+_comps[git]} ))
    [[ ${_comps[dotfiles-review]-} == _dotfiles-review ]]
    (( ${+functions[_main_complete]} ))
    [[ ${_comps[zinit]-} == _zinit ]]
  '
  [[ -f "$test_zdotdir/.zcompdump" ]]
done

[[ -f "$test_zdotdir/.zcompdump" ]]

print 'Completion regression checks passed.'
