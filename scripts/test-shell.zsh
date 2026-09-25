#!/bin/zsh -f
# Exercise shell settings without loading host plugins, secrets, or runtimes.
set -eu
repo_dir=${0:A:h:h}
unset ENABLE_LSP_TOOL CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS OPEN_CLAUDE_CODE_USE_OPENAI OCC_OPENAI_BASE_URL OCC_OPENAI_MODEL

mise() { print ':'; }
zinit() {
  [[ "$*" != *romkatv/powerlevel10k* ]] || { echo 'Powerlevel10k must not be installed by Zinit.' >&2; exit 1; }
}
# dot_zshrc initializes completion after loading plugins. Keep this unit-style
# test isolated from the real completion cache; test-completion.zsh exercises
# the system compinit implementation with a temporary ZDOTDIR.
compinit() { typeset -gA _comps; }
agy-ide() { :; }
personal_loaded=0
local_loaded=0
powerlevel10k_loaded=0
source() {
  if [[ $1 == "$HOME/.config/zsh/personal.zsh" ]]; then
    builtin source "$repo_dir/private_dot_config/zsh/personal.zsh"
    personal_loaded=1
  elif [[ $1 == /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme ]]; then
    powerlevel10k_loaded=1
  elif [[ $1 == "$HOME/.config/zsh/local.zsh" ]]; then
    [[ $personal_loaded == 1 ]] || return 1
    DOTFILES_TEST_OVERRIDE=local-test-value
    local_loaded=1
  fi
  return 0
}

# The production config intentionally permits unset optional environment values.
unsetopt nounset errexit
builtin source "$repo_dir/dot_zshrc"
setopt nounset errexit

[[ ! -v 'aliases[yolo]' ]]
[[ ! -v 'aliases[start-competition]' ]]
[[ ! -v 'aliases[code]' ]]
[[ ! -v ENABLE_LSP_TOOL && ! -v CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS ]]
[[ ! -v OPEN_CLAUDE_CODE_USE_OPENAI && ! -v OCC_OPENAI_BASE_URL && ! -v OCC_OPENAI_MODEL ]]
if (( local_loaded )); then
  [[ $DOTFILES_TEST_OVERRIDE == local-test-value ]]
fi
[[ $personal_loaded == 1 ]]
[[ $powerlevel10k_loaded == 1 ]]
# Check the override order even on a host without a local.zsh file.
rc_text=$(<"$repo_dir/dot_zshrc")
[[ $rc_text == *'source "$HOME/.config/zsh/personal.zsh"'*'source "$HOME/.config/zsh/local.zsh"'* ]]
[[ ${path[(Ie)$HOME/.local/bin]} -gt 0 ]]
if [[ -d /opt/homebrew/opt/libomp ]]; then
  [[ $LDFLAGS == -L/opt/homebrew/opt/libomp/lib ]]
  [[ $CPPFLAGS == -I/opt/homebrew/opt/libomp/include ]]
fi
print 'Shell settings regression checks passed.'
