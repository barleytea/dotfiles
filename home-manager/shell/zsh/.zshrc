# Load all configuration files
for config_file ($ZDOTDIR/config/*.zsh) source $config_file
for tool_config ($ZDOTDIR/config/tools/*.zsh) source $tool_config

# Load local configuration if exists
if [[ -f ~/.zshrc_local ]]; then
  source ~/.zshrc_local
fi
