let 

tmuxConf = ''
  set -g default-terminal "screen-256color"
  set-option -sa terminal-overrides ',alacritty:RGB'

  set -g default-shell /bin/zsh
  set -g mouse on

  set-option -g status-left-length 20
  set-option -g status-right-length 60

  set-option -g status-left "#[fg=colour255,bg=colour241]Session: #S #[default]"
  set-option -g status-right "#[fg=colour255,bg=colour241] #h"
  set-window-option -g window-status-format " #I: #W "
  set-window-option -g window-status-current-format "#[fg=colour255,bg=colour27,bold] #I: #W #[default]"

  # vimのキーバインドでペインを移動
  bind h select-pane -L
  bind j select-pane -D
  bind k select-pane -U
  bind l select-pane -R

  # vimのキーバインドでペインをリサイズ
  bind -r H resize-pane -L 5
  bind -r J resize-pane -D 5
  bind -r K resize-pane -U 5
  bind -r L resize-pane -R 5

  bind-key r source-file ~/.tmux.conf\; display-message "$HOME/.tmux.conf reloaded!"
'';

in {
  programs.tmux = {
    enable = true;
    extraConfig = tmuxConf;
  };
}
