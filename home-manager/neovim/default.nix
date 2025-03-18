{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (builtins) readFile;
  pwd = (import ../pwd.nix { inherit config; }).pwd;
  configFile = file: {
    "nvim/${file}".source = pkgs.substituteAll (
      {
        src = ./. + "/${file}";
      }
    );
  };
  configFiles = files: builtins.foldl' (x: y: x // y) { } (map configFile files);
in {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    extraPackages = with pkgs; [
      lua-language-server
      nil
      stylua
      # TODO
    ];
    plugins = with pkgs.vimPlugins; [
      # 基本プラグイン
      lazy-nvim
      LazyVim
      
      # UI関連
      dracula-nvim
      nvim-web-devicons
      lualine-nvim
      nvim-notify
      noice-nvim
      nui-nvim
      
      # 補完関連
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      cmp-cmdline
      luasnip
      cmp_luasnip
      
      # LSP関連
      nvim-lspconfig
      mason-nvim
      mason-lspconfig-nvim
      
      # フォーマッターとリンター
      conform-nvim
      nvim-lint
      none-ls-nvim
      
      # エディタ機能
      indent-blankline-nvim
      copilot-vim
      copilot-cmp
      gitsigns-nvim
      telescope-nvim
      plenary-nvim
      telescope-fzf-native-nvim
      
      # その他の便利なプラグイン
      which-key-nvim
      nvim-treesitter
      nvim-treesitter-textobjects
      comment-nvim
      neo-tree-nvim
      bufferline-nvim
    ];

    extraLuaConfig =
      let
        plugins = with pkgs.vimPlugins; [
          # プラグインは上記のplugins = with pkgs.vimPlugins;で定義
        ];
        mkEntryFromDrv = drv:
          if lib.isDerivation drv then
            { name = "${lib.getName drv}"; path = drv; }
          else
            drv;
        lazyPath = pkgs.linkFarm "lazy-plugins" (builtins.map mkEntryFromDrv plugins);
      in
      ''
        -- LazyVimのインポート順序チェックを無効化（Nixでの管理のため）
        vim.g.lazyvim_check_order = false

        -- Set up vim options
        require("config.base")

        -- Set up lazy.nvim
        local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
        local lazy = require("lazy")

        -- Set up completion
        require("config.cmp")

        -- Create custom event for compatibility
        vim.api.nvim_create_autocmd("BufReadPost", {
          callback = function()
            vim.api.nvim_exec_autocmds("User", { pattern = "LazyFile" })
          end,
        })
        vim.api.nvim_create_autocmd("BufNewFile", {
          callback = function()
            vim.api.nvim_exec_autocmds("User", { pattern = "LazyFile" })
          end,
        })

        -- Configure colorscheme
        vim.cmd("colorscheme dracula")

        -- Configure lazy.nvim with the correct import order
        lazy.setup({
          -- spec
          spec = {
            -- LazyVimのコアプラグイン（最初に読み込み）
            { "LazyVim/LazyVim", import = "lazyvim.plugins" },
            -- LazyVim extras（次に読み込み）
            { import = "lazyvim.plugins.extras.lsp.none-ls" },
            -- カスタムプラグイン（最後に読み込み）
            { import = "plugins" },
          },
          -- デフォルト設定
          defaults = {
            lazy = true,
            version = false,
          },
          -- インストール設定
          install = { colorscheme = { "dracula", "tokyonight", "habamax" } },
          -- チェッカー設定
          checker = { enabled = true },
          -- パフォーマンス設定
          performance = {
            rtp = {
              disabled_plugins = {
                "gzip",
                "matchit",
                "matchparen",
                "netrwPlugin",
                "tarPlugin",
                "tohtml",
                "tutor",
                "zipPlugin",
              },
            },
          },
          -- デバッグ設定
          debug = false,
          -- 開発用設定
          dev = {
            path = "${lazyPath}",
            patterns = { "." },
            fallback = true,
          },
        })
      '';
  };

  xdg.configFile."nvim/lua" = {
    source = config.lib.file.mkOutOfStoreSymlink "${pwd}/neovim/lua";
  };

  imports = [
    ./treesitter-parser.nix
  ];
}