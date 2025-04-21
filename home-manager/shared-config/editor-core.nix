# 共通エディタ設定
# VSCodeとNeovimで共有する基本設定を定義

{ config, lib, pkgs, ... }:

with lib;
let
  # 共通の設定値
  commonSettings = {
    # テーマ設定
    theme = {
      name = "dracula";
      isDark = true;
    };

    # エディタ設定
    editor = {
      fontFamily = "'Hack Nerd Font Mono'";
      fontSize = 14;
      lineHeight = 1.5;
      tabSize = 2;
      insertSpaces = true;
      rulers = [];
      wordWrap = false;
      wordWrapColumn = 80;
      minimap = false;
    };

    # 検索設定
    search = {
      caseSensitive = false;
      useRegex = true;
    };

    # ターミナル設定
    terminal = {
      fontFamily = "'Hack Nerd Font Mono'";
      fontSize = 14;
      lineHeight = 1.0;
      scrollback = 10000;
    };

    # キーバインド設定
    keyBindings = {
      # リーダーキー
      leader = " ";

      # 基本的なエディタ操作
      save = "<leader>w";
      close = "<leader>q";
      fileExplorer = "<leader>e";
      quickOpen = "<leader>f";
      find = "<leader>s";
      replace = "<leader>r";

      # ウィンドウ操作
      navigateLeft = "<C-h>";
      navigateDown = "<C-j>";
      navigateUp = "<C-k>";
      navigateRight = "<C-l>";

      # バッファ/タブ操作
      nextBuffer = "<S-l>";
      prevBuffer = "<S-h>";

      # エスケープ
      escape = "jj";
    };
  };

  # VSCode向け設定変換関数
  toVSCodeSettings = settings: {
    # テーマ
    "workbench.colorTheme" = if settings.theme.name == "dracula" then "Dracula Theme" else settings.theme.name;

    # エディタ設定
    "editor.fontFamily" = settings.editor.fontFamily;
    "editor.fontSize" = settings.editor.fontSize;
    "editor.lineHeight" = settings.editor.lineHeight;
    "editor.tabSize" = settings.editor.tabSize;
    "editor.insertSpaces" = settings.editor.insertSpaces;
    "editor.rulers" = settings.editor.rulers;
    "editor.wordWrap" = if settings.editor.wordWrap then "on" else "off";
    "editor.wordWrapColumn" = settings.editor.wordWrapColumn;
    "editor.minimap.enabled" = settings.editor.minimap;

    # ターミナル設定
    "terminal.integrated.fontFamily" = settings.terminal.fontFamily;
    "terminal.integrated.fontSize" = settings.terminal.fontSize;
    "terminal.integrated.lineHeight" = settings.terminal.lineHeight;
    "terminal.integrated.scrollback" = settings.terminal.scrollback;

    # VSCode-Neovim拡張機能の設定
    "vscode-neovim.compositeKeys" = {
      "${settings.keyBindings.escape}" = {
        command = "vscode-neovim.escape";
      };
    };
  };

  # Neovim向け設定変換関数
  toNeovimSettings = settings: ''
    -- 基本設定
    vim.opt.tabstop = ${toString settings.editor.tabSize}
    vim.opt.shiftwidth = ${toString settings.editor.tabSize}
    vim.opt.expandtab = ${if settings.editor.insertSpaces then "true" else "false"}
    vim.opt.wrap = ${if settings.editor.wordWrap then "true" else "false"}

    -- 検索設定
    vim.opt.ignorecase = ${if !settings.search.caseSensitive then "true" else "false"}
    vim.opt.smartcase = true

    -- テーマ設定
    vim.opt.background = '${if settings.theme.isDark then "dark" else "light"}'

    -- キーマップ設定
    vim.g.mapleader = '${settings.keyBindings.leader}'
    vim.api.nvim_set_keymap('i', '${settings.keyBindings.escape}', '<Esc><Esc><Esc>', { noremap = true })

    -- ウィンドウ操作
    vim.api.nvim_set_keymap('n', '${settings.keyBindings.navigateLeft}', '<C-w>h', { noremap = true })
    vim.api.nvim_set_keymap('n', '${settings.keyBindings.navigateDown}', '<C-w>j', { noremap = true })
    vim.api.nvim_set_keymap('n', '${settings.keyBindings.navigateUp}', '<C-w>k', { noremap = true })
    vim.api.nvim_set_keymap('n', '${settings.keyBindings.navigateRight}', '<C-w>l', { noremap = true })

    -- バッファ操作
    vim.api.nvim_set_keymap('n', '${settings.keyBindings.nextBuffer}', ':bnext<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', '${settings.keyBindings.prevBuffer}', ':bprevious<CR>', { noremap = true, silent = true })

    -- ファイル操作
    vim.api.nvim_set_keymap('n', '${settings.keyBindings.save}', ':w<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', '${settings.keyBindings.close}', ':q<CR>', { noremap = true, silent = true })

    -- カラースキーム
    local colorscheme_ok, _ = pcall(vim.cmd, 'colorscheme ${settings.theme.name}')
    if not colorscheme_ok then
      vim.notify('Colorscheme ${settings.theme.name} not found!', vim.log.levels.WARN)
    end
  '';

in {
  # エクスポートする値
  inherit commonSettings toVSCodeSettings toNeovimSettings;

  # このモジュールを使用するための関数
  getCommonSettings = overrides:
    let
      mergedSettings = recursiveUpdate commonSettings overrides;
    in {
      vscode = toVSCodeSettings mergedSettings;
      neovim = toNeovimSettings mergedSettings;
    };
}
