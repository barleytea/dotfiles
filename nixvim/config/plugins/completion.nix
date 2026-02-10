{...}: {
  plugins = {
    # Completion engine
    cmp = {
      enable = true;
      autoEnableSources = true;
    };

    # Snippet engine
    luasnip = {
      enable = true;
    };

    # LSP source for cmp
    cmp-nvim-lsp = {
      enable = true;
    };

    # Buffer source for cmp
    cmp-buffer = {
      enable = true;
    };

    # Path source for cmp
    cmp-path = {
      enable = true;
    };

    # Command line source for cmp
    cmp-cmdline = {
      enable = true;
    };

    # Luasnip source for cmp
    cmp_luasnip = {
      enable = true;
    };

    # Kind icons for completion
    lspkind = {
      enable = true;
    };

    # Copilot
    copilot-lua = {
      enable = true;
    };

    # Copilot cmp source
    copilot-cmp = {
      enable = true;
    };
  };
}
