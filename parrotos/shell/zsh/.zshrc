# Load all configuration files
for config_file ($ZDOTDIR/config/*.zsh) source $config_file

# Load local configuration if exists
if [[ -f ~/.zshrc_local ]]; then
  source ~/.zshrc_local
  echo "[zsh] Local configuration loaded"
fi
