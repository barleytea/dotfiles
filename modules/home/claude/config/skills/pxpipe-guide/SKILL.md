---
name: pxpipe-guide
description: pxpipe-proxy setup and usage guide for reducing Claude Code input tokens by rendering context as images, including security/accuracy caveats and opt-in claude-px launcher
---

# pxpipe Guide

[pxpipe](https://github.com/teamchong/pxpipe) は Claude Code の入力トークンを削減するローカルプロキシ。システムプロンプト・ツール定義・古い履歴などの密なテキストを PNG 画像に変換して Anthropic API に転送することで、入力トークン使用量を約59〜70%削減する。

---

## 重要な注意事項（導入前に必読）

### セキュリティ

- pxpipe は `ANTHROPIC_BASE_URL` を差し替えて **Claude Code ↔ Anthropic API 間のトラフィックをローカルでMITMするプロキシ**。API通信がサードパーティ製npmパッケージのコードを経由する
- `npx pxpipe-proxy` はその場でレジストリから最新版を取得するため、pin していないとサプライチェーンリスクがある。本リポジトリでは **`mise` で管理し、バージョンを固定してグローバルインストール** する運用にしている
- 常時有効化はせず、**オプトインの `claude-px` コマンドを明示的に打った時だけ**プロキシ経由になる設計にしてある（通常の `claude` コマンドは影響を受けない）

### 正確性（ロッシー圧縮）

- 画像化した内容はビジョンモデルによる再構成のため **非可逆**。公式ドキュメントでも「16進数12文字の再現率」でモデルによって 0/15〜13/15 とばらつくことが報告されている
- 誤りは「無音の幻覚」（エラーを出さず尤もらしい誤った値を返す）として現れる。**ハッシュ値・シークレット・トークンなどバイト正確な値が絡む作業では使わない**
- デフォルトで圧縮対象になるのは `PXPIPE_MODELS` で許可されたモデルのみ（公式デフォルトは Fable 5 系）。Opus/GPT系は読み誤り率が高く、オプトインが必要

---

## インストール

mise task として管理（`modules/home/mise/config.toml`）:

```toml
[tasks.npm-pxpipe]
description = "Install pxpipe-proxy globally"
run = ["npm install -g pxpipe-proxy"]
```

```bash
make mise-install-npm-pxpipe
# 内部で `mise run npm-pxpipe` を実行 → pxpipe-proxy をグローバルインストール
```

**注記**: [safe-chain](/safe-chain-guide) の `npm` ラッパーは `~/.zshrc_local` を読み込む対話シェルでのみ有効なシェル関数であり、`mise run` のタスク実行は非対話シェルのため素の `npm` が使われる（safe-chain によるインストール前チェックは通らない）。手動で保護したい場合は対話シェルで `npm install -g pxpipe-proxy` を実行すること。

---

## 使い方

### オプトイン起動: `claude-px`

`darwin/home-manager/shell/zsh/config/functions.zsh` / `nixos/home-manager/shell/zsh/config/functions.zsh` に定義済みのシェル関数：

```zsh
function claude-px() {
  local pxpipe_port=47821
  if ! curl -s -o /dev/null "http://127.0.0.1:${pxpipe_port}/"; then
    echo "[claude-px] starting pxpipe-proxy on :${pxpipe_port}"
    pxpipe-proxy &>/dev/null &
    disown
    sleep 1
  fi
  ANTHROPIC_BASE_URL="http://127.0.0.1:${pxpipe_port}" claude "$@"
}
```

```bash
# プロキシが起動していなければバックグラウンドで起動してから claude を起動
claude-px

# 通常の claude と同じ引数を渡せる
claude-px --add-dir ../other-repo
```

通常の `claude` コマンドはそのまま素通りで、pxpipe を経由しない。トークン節約とロッシー圧縮のリスクを引き受けたいセッションでのみ `claude-px` を使う。

### ダッシュボード

プロキシ起動中は `http://127.0.0.1:47821/` で節約トークン数などのダッシュボードを確認できる。

### 圧縮対象モデルの制御

```bash
# 圧縮対象モデルを明示指定（デフォルトはFable5系のみ）
export PXPIPE_MODELS=claude-fable-5

# 圧縮を完全に無効化（プロキシは通すが素通しにする）
export PXPIPE_MODELS=off
```

`~/.zshrc_local` に追記すれば `claude-px` 使用時にのみ適用される設定として永続化できる。

---

## 動作原理（概要）

1. `/v1/messages` エンドポイントをインターセプト
2. 密なテキストコンテンツを1928px幅でPNG画像に変換（約92,000文字/ページ）
3. 元テキストの推定トークンコストより画像化後のコストが低い場合のみ圧縮を適用
4. モデルの出力（レスポンス）は一切改変しない。リクエストのみ圧縮

圧縮対象になりやすいもの: 巨大な `tool_result`（ファイル読み取り、コマンド出力、ログ）、直近ターンを除く古い履歴、静的なシステムプロンプト・ツール定義。直近ターンやモデル出力は対象外。

---

## トラブルシューティング

### `claude-px` を実行してもプロキシに繋がらない

```bash
# pxpipe-proxy が実際にインストールされているか確認
command -v pxpipe-proxy

# ポートが埋まっていないか確認
lsof -i :47821
```

### 圧縮結果が信頼できない値を返した

ハッシュ値・シークレット・診断コマンドの出力などバイト正確な値を扱う作業では、通常の `claude`（pxpipe を経由しない）に戻すこと。`claude-px` はトークン節約が有効なワークロード（密なプレーンテキストの大量コンテキスト）に限定して使う。

### アンインストール

```bash
mise uninstall npm:pxpipe-proxy
# もしくは npm -g uninstall pxpipe-proxy
```
