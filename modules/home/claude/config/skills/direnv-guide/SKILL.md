# direnv Guide

direnv はディレクトリに入ったとき `.envrc` を自動で評価し、環境変数をシェルにロードするツール。

## このdotfilesでの設定

### インストール・Hook

`direnv` は `home.packages` でインストール済み、zsh hook も自動設定済み：
- パッケージ: `darwin/home-manager/packages/packages.nix`
- zsh hook: `darwin/home-manager/shell/zsh/config/direnv.zsh`

### グローバル direnvrc

`~/.config/direnv/direnvrc` に `dotenv_if_exists` が設定済み：
- 設定: `darwin/home-manager/shell/zsh/default.nix` の `xdg.configFile."direnv/direnvrc"`
- 効果: `.envrc` があるディレクトリに `.env` があれば自動ロードされる

### グローバル gitignore

`.envrc` はグローバル gitignore（`~/.config/git/ignore`）で除外済み。
各プロジェクトで `.gitignore` に追記しなくてもリポジトリには含まれない。

## 基本的な使い方

### .env ファイルを自動ロードする

```bash
# プロジェクトディレクトリで
echo 'DATABASE_URL=postgres://localhost/mydb' >> .env
echo 'SECRET_KEY=abc123' >> .env

# .envrc を作成（空でも dotenv_if_exists がグローバルで効く）
touch .envrc

# direnv に許可を与える（初回 or .envrc 変更時に必要）
direnv allow .

# ディレクトリに入ると自動ロード
cd .
echo $DATABASE_URL  # => postgres://localhost/mydb
```

### .envrc に直接環境変数を書く

```bash
cat > .envrc << 'EOF'
export APP_ENV=development
export PORT=3000
EOF

direnv allow .
```

### .env と .envrc を組み合わせる

```bash
# .env: 実際の値（gitignore対象）
echo 'API_KEY=secret' > .env

# .envrc: ロジック（git管理してもよい場合）
cat > .envrc << 'EOF'
# .env は dotenv_if_exists でグローバルに読まれる
# 追加でパスを通したい場合などはここに書く
PATH_add ./bin
EOF

direnv allow .
```

## よく使う direnv stdlib 関数

| 関数 | 説明 |
|------|------|
| `dotenv` | `.env` をロード（ファイルなければエラー） |
| `dotenv_if_exists` | `.env` をロード（ファイルなければスキップ） |
| `dotenv_if_exists .env.local` | 別ファイルを指定してロード |
| `PATH_add ./bin` | `./bin` を PATH に追加 |
| `export VAR=value` | 環境変数を直接セット |
| `use node 20` | mise/asdf でランタイムを切り替え |

## `direnv allow` が必要なタイミング

- `.envrc` を新規作成したとき
- `.envrc` を編集したとき

```bash
direnv allow .    # カレントディレクトリの .envrc を許可
direnv deny .     # 許可を取り消す
direnv status     # 現在の状態確認
direnv reload     # 強制再評価
```

## トラブルシューティング

### 変数がロードされない

```bash
direnv status         # .envrc が allow されているか確認
cat ~/.config/direnv/direnvrc  # グローバル設定確認（dotenv_if_exists があるはず）
```

### .envrc の変更が反映されない

```bash
direnv allow .   # 再許可が必要
```

### 特定のファイルを指定してロードしたい

```bash
# .envrc に追記
dotenv_if_exists .env.local
dotenv_if_exists .env.development
```

## ファイル管理指針

| ファイル | Git管理 | 用途 |
|----------|---------|------|
| `.env` | 除外推奨 | 実際のシークレット・設定値 |
| `.env.example` | 管理する | 変数名の一覧（値なし） |
| `.envrc` | グローバルgitignoreで除外済み | direnvの評価スクリプト |
