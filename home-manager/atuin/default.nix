{
  programs.atuin = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;

    flags = [ "--disable-up-arrow" ];

    settings = {
      auto_sync = false;
      style = "compact";
      enter_accept = false;
      keymap_mode = "vim-normal";
      search_mode = "fuzzy";
      filter_mode = "host"; # global, host, session, directory
    };
  };
}
