{
  config,
  lib,
  pkgs,
  ...
}: let

in {
  programs.fish = {
    enable = true;

    plugins = [
      { name = "z"; src = pkgs.fishPlugins.z.src; }
      { name = "fish-bd"; src = pkgs.fishPlugins.fish-bd.src; }
    ];

    interactiveShellInit = ''
      # XDG
      set -gx XDG_CONFIG_HOME $HOME/.config
      set -gx XDG_CACHE_HOME $HOME/.cache
      set -gx XDG_DATA_HOME $HOME/.local/share
      set -gx XDG_STATE_HOME $HOME/.local/state

      # path
      fish_add_path $XDG_STATE_HOME/nix/profiles/profile/bin
      fish_add_path $HOME/.cargo/bin
      fish_add_path $HOME/flutter/bin
      fish_add_path $HOME/go/bin
      fish_add_path $HOME/.local/bin
      fish_add_path /opt/homebrew/bin

      set -gx USER "miyoshi_s"
      set -gx NIX_PATH (echo $NIX_PATH:)nixpkgs=$XDG_STATE_HOME/nix/defexpr/channels/nixpkgs
      if test -e $XDG_STATE_HOME/nix/profiles/profile/etc/profile.d/nix.sh
        source $XDG_STATE_HOME/nix/profiles/profile/etc/profile.d/nix.sh
      end
      set -gx NIX_CONF_DIR $XDG_CONFIG_HOME


      # alias
      alias e='eza --icons --git'
      alias l=e
      alias ls=e
      alias ea='eza -a --icons --git'
      alias la=ea
      alias ee='eza -aahl --icons --git'
      alias ll=ee
      alias et='eza -T -L 3 -a -I "node_modules|.git|.cache" --icons'
      alias lt=et
      alias eta='eza -T -a -I "node_modules|.git|.cache" --color=always --icons | less -r'
      alias lta=eta
      alias l='clear && ls'
      alias vim=nvim
      alias g=git
      alias gmc='gitmoji -c'

      # commandline
      set fish_color_normal         brwhite
      set fish_color_autosuggestion brblack
      set fish_color_cancel         brcyan
      set fish_color_command        brgreen
      set fish_color_comment        brblack
      set fish_color_cwd            brred
      set fish_color_end            brwhite
      set fish_color_error          brred
      set fish_color_escape         brcyan
      set fish_color_host           brpurple
      set fish_color_host_remote    bryellow
      set fish_color_match          brcyan --underline
      set fish_color_operator       brpurple
      set fish_color_param          brred
      set fish_color_quote          brgreen
      set fish_color_redirection    brcyan
      set fish_color_search_match   --background=brblack
      set fish_color_selection      --background=brblack
      set fish_color_user           brblue

      # pager
      set fish_pager_color_progress              brblack --italics
      set fish_pager_color_secondary_background  # null
      set fish_pager_color_secondary_completion  brblack
      set fish_pager_color_secondary_description brblack
      set fish_pager_color_secondary_prefix      brblack
      set fish_pager_color_selected_background   --background=brblack
      set fish_pager_color_selected_completion   bryellow
      set fish_pager_color_selected_description  bryellow
      set fish_pager_color_selected_prefix       bryellow

      # bd
      complete -c bd -s c --description "Classic mode : goes back to the first directory named as the string"
      complete -c bd -s s --description "Seems mode : goes back to the first directory containing string"
      complete -c bd -s i --description "Case insensitive move (implies seems mode)"
      complete -c bd -s h -x --description "Display help and exit"
      complete -c bd -A -f
      complete -c bd -a '(__fish_bd_complete_dirs)'

      # asdf
      if test -f $XDG_STATE_HOME/nix/profiles/profile/share/asdf-vm/asdf.fish
        source $XDG_STATE_HOME/nix/profiles/profile/share/asdf-vm/asdf.fish
      end

      # local.fish
      if test -f $HOME/.config/fish/local.fish
        echo "local.fish loaded."
        source $XDG_CONFIG_HOME/fish/local.fish
      end
    '';

    functions = {

      fish_user_key_bindings = ''
        bind \cr 'peco_select_history'
        bind \cg 'ghq_repository_search'
        if bind -M insert >/dev/null 2>/dev/null
          bind -M insert \cg 'ghq_repository_search'
        end
      '';

      mkcd = ''
        if test -d $argv[1]
          cd $argv[1]
        else
          mkdir -p $argv[1]; cd $argv[1]
        end
      '';

      ghq_repository_search = ''
        ghq list --full-path | peco | read select
        [ -n "$select" ]; and cd "$select"
        commandline -f repaint
      '';

      peco_select_history = ''
        history | peco --query "$argv" | read -l select
        [ -n "$select" ]; and commandline -r "$select"
        commandline -f repaint
      '';
    };
  };
}
