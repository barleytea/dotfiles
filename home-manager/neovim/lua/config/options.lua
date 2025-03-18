-- LazyVimのカスタムオプション設定
vim.g.lazyvim_version = "11.2"
vim.g.lazyvim_check_order = false -- インポート順序チェックを無効化

-- LazyVimのデフォルトオプションを上書き
vim.opt.autowrite = true -- ファイルの自動保存を有効化
vim.opt.clipboard = "unnamedplus" -- システムクリップボードとの連携
vim.opt.completeopt = "menu,menuone,noselect"
vim.opt.conceallevel = 2 -- Markdownなどでの特殊文字の非表示
vim.opt.confirm = true -- 保存せずに終了する前に確認
vim.opt.cursorline = true -- カーソル行のハイライト
vim.opt.expandtab = true -- タブをスペースに変換
vim.opt.formatoptions = "jcroqlnt" -- テキスト整形オプション
vim.opt.grepformat = "%f:%l:%c:%m"
vim.opt.grepprg = "rg --vimgrep"
vim.opt.ignorecase = true -- 検索時に大文字小文字を区別しない
vim.opt.inccommand = "nosplit" -- インクリメンタル置換のプレビュー
vim.opt.laststatus = 3 -- グローバルステータスライン
vim.opt.list = true -- 不可視文字を表示
vim.opt.mouse = "a" -- すべてのモードでマウスを使用可能
vim.opt.number = true -- 行番号を表示
vim.opt.relativenumber = true -- 相対行番号
vim.opt.scrolloff = 4 -- スクロール時に表示する余白の行数
vim.opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
vim.opt.shiftround = true -- インデントを丸める
vim.opt.shiftwidth = 2 -- インデントの幅
vim.opt.shortmess:append({ W = true, I = true, c = true, C = true })
vim.opt.showmode = false -- モード表示を非表示
vim.opt.sidescrolloff = 8 -- 水平スクロール時に表示する余白の列数
vim.opt.signcolumn = "yes" -- 常に符号列を表示
vim.opt.smartcase = true -- ignorecase=trueの場合、大文字が含まれていれば大文字小文字を区別
vim.opt.smartindent = true -- スマートインデント
vim.opt.spelllang = { "en", "jp" }
vim.opt.splitbelow = true -- 水平分割は下に開く
vim.opt.splitkeep = "screen"
vim.opt.splitright = true -- 垂直分割は右に開く
vim.opt.tabstop = 2 -- タブの幅
vim.opt.termguicolors = true -- 24ビットカラーサポート
vim.opt.timeoutlen = 300 -- キーコードの待機時間
vim.opt.undofile = true -- 永続的なundo履歴
vim.opt.undolevels = 10000
vim.opt.updatetime = 200 -- スワップファイルを書き込む間隔
vim.opt.wildmode = "longest:full,full" -- コマンドライン補完
vim.opt.winminwidth = 5 -- 最小ウィンドウ幅
vim.opt.wrap = false -- テキストの折り返しなし

-- fillcharsの設定を修正
-- 1文字だけ使用するように設定を修正
vim.opt.fillchars = {
  fold = " ",
  foldsep = " ",
  diff = "╱",
  eob = " ",
}

-- Neovim 0.10以上の場合は追加設定を行う
if vim.fn.has("nvim-0.10") == 1 then
  vim.opt.fillchars:append({
    foldopen = "▾",
    foldclose = "▸",
  })
end 