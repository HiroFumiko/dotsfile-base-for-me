# Personal preferences shared across Macs. Secrets belong in local.zsh.

# OpenMP build settings for Apple Silicon Homebrew.
if [[ -d /opt/homebrew/opt/libomp ]]; then
  export LDFLAGS="-L/opt/homebrew/opt/libomp/lib"
  export CPPFLAGS="-I/opt/homebrew/opt/libomp/include"
fi
