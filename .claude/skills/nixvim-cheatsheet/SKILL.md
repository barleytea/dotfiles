---
name: nixvim-cheatsheet
description: Nixvim (Neovim) configuration cheatsheet including keybindings, plugins, LSP, Git operations, and text objects
---

# Nixvim チートシート

## 基本設定

### リーダーキー
- **Leader**: `Space`
- **LocalLeader**: `,`

### エディタ設定
- 相対行番号 + 絶対行番号表示
- カーソルライン・カラム表示
- タブ幅: 2スペース (expandtab)
- スマートインデント有効
- 検索: ignorecase + smartcase
- クリップボード: システム共有 (`unnamedplus`)
- Grep: `rg --vimgrep` (ripgrep)
- テーマ: Dracula (透過背景)
- Undo履歴保存 (10000レベル)

## 基本キーマップ

### Insert モード

| キー | 動作 |
|------|------|
| `jj` | Insert mode終了 |
| `C-h` | カーソル左移動 |
| `C-j` | カーソル下移動 |
| `C-k` | カーソル上移動 |
| `C-l` | カーソル右移動 |
| `C-f` | 文字削除（前方） |

### Normal モード

| キー | 動作 |
|------|------|
| `j` / `k` | 表示行単位で移動 (gj/gk) |
| `;` | コマンドライン |
| `:` | 文字検索リピート |
| `<Space>w` | ファイル保存 |
| `Esc` | 検索ハイライト消去 |
| `S-h` / `S-l` | 前/次のバッファ |
| `C-h/j/k/l` | ウィンドウ間移動 |

### Visual モード

| キー | 動作 |
|------|------|
| `<` | インデント解除（選択維持） |
| `>` | インデント（選択維持） |

### プレフィックスマッピング

| プレフィックス | マップ先 | 用途 |
|---------------|----------|------|
| `m` | `<Plug>(lsp)` | LSP操作（未使用） |
| `n` | `<Plug>(ff)` | ファインダー操作（未使用） |

## Telescope (ファジーファインダー)

| キー | 動作 |
|------|------|
| `<Space>ff` | ファイル検索 |
| `<Space>fg` | 全文検索 (live_grep) |
| `<Space>fb` | バッファ一覧 |
| `<Space>fh` | ヘルプタグ検索 |

**拡張機能**: fzf-native (高速検索)

## LSP (Language Server Protocol)

### 対応言語サーバー

| 言語 | LSP サーバー | 備考 |
|------|-------------|------|
| Nix | nil_ls | nixpkgs-unstable前提 |
| Lua | lua_ls | vim グローバル認識 |
| Go | gopls | 保存時自動フォーマット |

### LSPキーバインド

| キー | 動作 |
|------|------|
| `gd` | 定義へジャンプ |
| `gD` | 宣言へジャンプ |
| `gr` | 参照一覧 |
| `gI` | 実装へジャンプ |
| `gt` | 型定義へジャンプ |
| `K` | ホバー情報表示 |
| `<leader>ca` | コードアクション |
| `C-k` | シグネチャヘルプ |
| `<leader>rn` | シンボル名変更 |

### 診断 (Diagnostic)

| キー | 動作 |
|------|------|
| `[d` | 次の診断へ |
| `]d` | 前の診断へ |
| `<leader>e` | 診断フロート表示 |
| `<leader>q` | ロケーションリストに診断を設定 |

### フォーマッター (none-ls)

- **Lua**: stylua
- **Nix**: nixpkgs_fmt
- **Go**: gopls (保存時自動実行)

## Treesitter

### 増分選択 (Incremental Selection)

| キー | 動作 |
|------|------|
| `C-space` | 選択開始 / ノード拡張 |
| `BS` (Backspace) | ノード縮小 |

### テキストオブジェクト選択

| キー | 対象 |
|------|------|
| `aa` / `ia` | パラメータ (outer/inner) |
| `af` / `if` | 関数 (outer/inner) |
| `ac` / `ic` | クラス (outer/inner) |
| `ai` / `ii` | 条件文 (outer/inner) |
| `al` / `il` | ループ (outer/inner) |
| `at` | コメント (outer) |

### テキストオブジェクト移動

| キー | 動作 |
|------|------|
| `]m` | 次の関数開始位置 |
| `]M` | 次の関数終了位置 |
| `[m` | 前の関数開始位置 |
| `[M` | 前の関数終了位置 |
| `]]` | 次のクラス開始位置 |
| `][` | 次のクラス終了位置 |
| `[[` | 前のクラス開始位置 |
| `[]` | 前のクラス終了位置 |

### パラメータ入れ替え (Swap)

| キー | 動作 |
|------|------|
| `<leader>a` | 次のパラメータと入れ替え |
| `<leader>A` | 前のパラメータと入れ替え |

## コメント操作 (comment.nvim)

### トグル

| キー | 動作 |
|------|------|
| `gcc` | 行コメントトグル |
| `gbc` | ブロックコメントトグル |

### オペレーター

| キー | 動作 |
|------|------|
| `gc{motion}` | モーションで行コメント |
| `gb{motion}` | モーションでブロックコメント |

### 追加コメント

| キー | 動作 |
|------|------|
| `gcO` | 上にコメント行追加 |
| `gco` | 下にコメント行追加 |
| `gcA` | 行末にコメント追加 |

## Surround操作 (nvim-surround)

| キー | 動作 |
|------|------|
| `ys{motion}{char}` | テキストを囲む |
| `ds{char}` | 囲み文字を削除 |
| `cs{old}{new}` | 囲み文字を変更 |

例:
- `ysiw"` → 単語をダブルクォートで囲む
- `ds"` → ダブルクォートを削除
- `cs"'` → ダブルクォートをシングルクォートに変更

## Git操作

### Neogit (Gitクライアント)

| キー | 動作 |
|------|------|
| `<leader>gg` | Neogit起動 |

### Diffview

| キー | 動作 |
|------|------|
| `<leader>gd` | Diffview Open |
| `<leader>gh` | ファイル履歴表示 |
| `<leader>gc` | Diffview Close |

### Gitsigns (Hunk操作)

#### Hunkナビゲーション

| キー | 動作 |
|------|------|
| `]c` | 次のHunkへ |
| `[c` | 前のHunkへ |

#### Hunk操作

| キー | モード | 動作 |
|------|--------|------|
| `<leader>ghs` | Normal/Visual | Hunkをステージング |
| `<leader>ghr` | Normal/Visual | Hunkをリセット |
| `<leader>ghS` | Normal | バッファ全体をステージング |
| `<leader>ghu` | Normal | ステージング取消 |
| `<leader>ghR` | Normal | バッファ全体をリセット |
| `<leader>ghp` | Normal | Hunkプレビュー |

#### Blame操作

| キー | 動作 |
|------|------|
| `<leader>ghb` | Blame行表示（フル） |
| `<leader>gtb` | Blameトグル |

#### Diff操作

| キー | 動作 |
|------|------|
| `<leader>ghd` | Diffを表示 |
| `<leader>ghD` | Diff this ~ |
| `<leader>gtd` | 削除行トグル |

### Gitsigns表示記号

| 記号 | 意味 |
|------|------|
| `│` | 追加/変更 |
| `_` | 削除 |
| `‾` | 上部削除 |
| `~` | 変更削除 |
| `┆` | 未追跡 |

## Flash (高速ナビゲーション)

Flashプラグインはデフォルトキーバインドで動作:
- `s` - 順方向検索
- `S` - 逆方向検索
- `r` - リモートアクション
- `R` - Treesitterサーチ

## 補完 (nvim-cmp)

### 補完ソース

- **LSP**: LSPサーバーからの補完
- **Buffer**: 現在のバッファから
- **Path**: ファイルパス
- **Cmdline**: コマンドライン
- **Luasnip**: スニペット
- **Copilot**: GitHub Copilot

補完メニューは自動表示され、`<CR>` で選択、`<C-n>`/`<C-p>` で移動できます。

## UIプラグイン

### Neo-tree (ファイルエクスプローラー)

- 起動時に自動表示
- サイドバー形式でファイルツリー表示

### Bufferline

- タブバー形式でバッファ表示
- `S-h`/`S-l` でバッファ切替

### Lualine

- ステータスライン表示
- モード、ファイル名、Git情報等を表示

### Noice

- コマンドライン、通知、メッセージのUI強化
- ポップアップ形式での表示

### Notify

- 通知システム
- LSPプログレス表示等で使用

### Indent-blankline

- インデントガイド表示
- コードブロック構造の可視化

### Which-key

- キーバインドヒント表示
- Leader キー後に表示

## その他ツール

### LazyGit

LazyGitは有効化されていますが、明示的なキーバインドは未設定です。

### Toggleterm

ターミナル統合機能が有効です。

### Auto-session

セッション自動保存・復元が有効です。

### Autopairs

括弧・クォートの自動ペアが有効です。

## 設定ファイルパス

```
nixvim/config/
├── default.nix           # メインエントリポイント
├── options.nix           # エディタオプション
├── keymaps.nix           # 基本キーマップ
├── colorschemes.nix      # カラースキーム (Dracula)
└── plugins/
    ├── completion.nix    # 補完 (cmp, copilot)
    ├── editor.nix        # エディタ機能 (treesitter, surround, comment等)
    ├── git.nix           # Git統合 (gitsigns, neogit, diffview)
    ├── lsp.nix           # LSP設定
    └── ui.nix            # UI (telescope, neo-tree, lualine等)
```

## ターミナルコマンド

### カスタムコマンド

| コマンド | 動作 |
|----------|------|
| `:T <command>` | 下部20行のターミナル分割実行 |

### その他

- ターミナルモードは自動でInsertモードに移行
- `ColorScheme` 自動コマンドで透過背景を維持
- Goファイル保存時に自動フォーマット実行

## トラブルシューティング

### LSPが動作しない

1. 該当言語のLSPサーバーがインストールされているか確認
2. `:LspInfo` で接続状態を確認
3. `nil_ls` はnixpkgs-unstable前提なので、flake.lockを最新化

### Copilotが動作しない

1. GitHub Copilotサブスクリプション確認
2. `:Copilot setup` で認証

### Telescopeが遅い

- fzf-native拡張が有効なので、通常は高速です
- ripgrepがインストールされているか確認 (`rg --version`)

### 透過背景が効かない

- ターミナルエミュレータの透過設定を確認
- `ColorScheme` autocmdが透過背景を強制設定しています
