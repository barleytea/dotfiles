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
      (nvim-notify.overrideAttrs (old: {
        doCheck = false;
        checkPhase = "true";  # Skip all checks
        buildPhase = ''
          runHook preBuild
          runHook postBuild
        '';
        installPhase = ''
          runHook preInstall
          mkdir -p $out
          cp -r . $out/
          runHook postInstall
        '';
      }))
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

      # 追加のプラグイン
      nvim-surround
      comment-nvim
      which-key-nvim
      nvim-treesitter
      nvim-treesitter-textobjects
      neo-tree-nvim
      bufferline-nvim
    ];

    extraLuaConfig = ''
      -- LazyVimのインポート順序チェックを無効化
      vim.g.lazyvim_check_order = false

      if not vim.g.vscode then
        -- VSCodeモードでない場合のみ読み込み
        pcall(function() require('shared.options').setup() end)
        pcall(function() require('shared.keymaps').setup() end)
      end

      -- Snacks変数が存在しないエラーを解決するために、より適切なダミーの実装を提供
      Snacks = {
        toggle = function(opts)
          -- 空の関数を返して、chainingできるようにする
          return {
            map = function(mapKey)
              -- ここでmapKeyは文字列であることを確認
              if type(mapKey) == "string" then
                -- GitSignsの表示/非表示を切り替えるキーマッピング
                vim.keymap.set("n", mapKey, function()
                  require("gitsigns").toggle_signs()
                end, { desc = "Toggle Git Signs" })
              end
              -- チェーン可能なオブジェクトを返す
              return {}
            end
          }
        end
      }

      -- 問題のあるキーマッピングをオーバーライドする関数
      -- これは元のvim.keymap.setをラップして、テーブルが渡された場合の処理を追加
      local original_keymap_set = vim.keymap.set
      vim.keymap.set = function(mode, lhs, rhs, opts)
        -- テーブルが渡された場合はスキップ
        if type(lhs) == "table" then
          -- エラーを避けるために何もせずに返す
          return
        end
        -- それ以外は通常通り処理
        return original_keymap_set(mode, lhs, rhs, opts)
      end

      -- 基本的なオプション設定
      require("config.base")

      -- lazy.nvimのセットアップ
      local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
      local lazy = require("lazy")

      -- 補完設定のセットアップ
      require("config.cmp")

      -- カスタムイベントの作成（互換性のため）
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

      -- カラースキームを設定
      vim.cmd("colorscheme dracula")

      -- lazy.nvimの設定
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
