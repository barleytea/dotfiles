if [ -e "$XDG_STATE_HOME/nix/profiles/profile/share/asdf-vm/asdf.sh" ]; then
  . "$XDG_STATE_HOME/nix/profiles/profile/share/asdf-vm/asdf.sh"
fi

# Enable completions
if [ -e "$XDG_STATE_HOME/nix/profiles/profile/share/asdf-vm/completions" ]; then
  fpath=(${XDG_STATE_HOME}/nix/profiles/profile/share/asdf-vm/completions $fpath)
fi
