-- VSCodeからの同期で生成された設定ファイル
-- 警告: このファイルは自動生成されます。手動編集はバックアップを取ってから行ってください。

local M = {}

function M.setup()
  -- 基本設定
  vim.opt.number = true          -- 行番号表示
  vim.opt.relativenumber = true  -- 相対行番号
  vim.opt.cursorline = true      -- カーソル行をハイライト
  vim.opt.cursorcolumn = true    -- カーソル列をハイライト
  vim.opt.wrap = false           -- 行の折り返しをしない
  vim.opt.tabstop = 2            -- タブ幅
  vim.opt.shiftwidth = 2         -- インデント幅
  vim.opt.expandtab = true       -- タブをスペースに展開
  vim.opt.smartindent = true     -- スマートインデント
  vim.opt.autoindent = true      -- 自動インデント

  -- 検索設定
  vim.opt.hlsearch = true        -- 検索結果のハイライト
  vim.opt.ignorecase = true      -- 大文字小文字を区別しない
  vim.opt.smartcase = true       -- 検索語に大文字が含まれる場合は区別

  -- システム設定
  vim.opt.backup = false         -- バックアップファイルを作成しない
  vim.opt.writebackup = false    -- 書き込み時のバックアップを作成しない
  vim.opt.swapfile = false       -- スワップファイルを作成しない
  vim.opt.updatetime = 50        -- 更新間隔
  vim.opt.clipboard = "unnamedplus" -- クリップボード連携

  -- VSCodeモードでの特殊設定
  if vim.g.vscode then
    -- VSCodeでは一部の設定を上書き
    vim.opt.hlsearch = false     -- VSCode側でハイライト
    vim.opt.cursorline = false   -- VSCode側でハイライト
    vim.opt.cursorcolumn = false -- VSCode側でハイライト
  end
end

return M
