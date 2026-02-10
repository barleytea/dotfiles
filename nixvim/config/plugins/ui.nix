{...}: {
  plugins = {
    # Status line
    lualine = {
      enable = true;
    };

    # File explorer
    neo-tree = {
      enable = true;
    };

    # Telescope fuzzy finder
    telescope = {
      enable = true;
      keymaps = {
        "<leader>ff" = "find_files";
        "<leader>fg" = "live_grep";
        "<leader>fb" = "buffers";
        "<leader>fh" = "help_tags";
      };
      extensions = {
        fzf-native = {
          enable = true;
        };
      };
    };

    # Buffer line
    bufferline = {
      enable = true;
    };

    # Notification UI
    notify = {
      enable = true;
    };

    # Enhanced UI
    noice = {
      enable = true;
    };

    # Web dev icons
    web-devicons = {
      enable = true;
    };

    # Indent guides
    indent-blankline = {
      enable = true;
    };
  };
}
