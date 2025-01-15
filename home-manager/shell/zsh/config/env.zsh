# XDG Base Directory

# User
export USER=$(whoami)
export DARWIN_USER=$(whoami)

# Nix
export NIX_PATH=$XDG_STATE_HOME/nix/defexpr/channels:/nix/var/nix/profiles/per-user/root/channels${NIX_PATH:+:$NIX_PATH}
if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi
export NIX_CONF_DIR=$XDG_CONFIG_HOME

# Less
export LESSHISTFILE="$XDG_STATE_HOME"/less/history
