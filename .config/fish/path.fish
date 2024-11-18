# path

fish_add_path $HOME/.cargo/bin
fish_add_path $HOME/flutter/bin
fish_add_path $HOME/go/bin
fish_add_path $HOME/.local/bin
fish_add_path /opt/homebrew/bin/

set -gx USER "miyoshi_s"
set -gx NIX_PATH $HOME/.nix-defexpr/channels /nix/var/nix/profiles/per-user/root/channels $NIX_PATH
if test -e $HOME/.nix-profile/etc/profile.d/nix.sh
  source $HOME/.nix-profile/etc/profile.d/nix.sh
end
set -gx NIX_CONF_DIR $HOME/.config/nix

# fish_add_path $HOME/.local/bin 
