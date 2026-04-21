# Renovate Guide

mise config.toml のバージョンを自動更新する Renovate Bot の導入・運用ガイド。

---

## What is Renovate?

[Renovate](https://github.com/renovatebot/renovate) は依存関係のバージョンを自動で更新し、PR を作成するツール。mise の `config.toml` を公式サポートしており、npm パッケージ・言語ランタイム等のバージョンアップを検知して PR を自動作成する。

---

## このリポジトリでの設定

### ファイル構成

```
renovate.json                                  # Renovate 設定（リポジトリルート）
darwin/home-manager/mise/config.toml           # Renovate がスキャンする mise 設定
```

### renovate.json

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended"],
  "schedule": ["before 9am on monday"],
  "packageRules": [
    {
      "groupName": "mise tools",
      "matchManagers": ["mise"],
      "automerge": false
    }
  ]
}
```

- **スケジュール**: 毎週月曜 9時前に PR 作成
- **グルーピング**: mise 管理ツールを 1 PR にまとめる
- **automerge**: 無効（手動レビューが必要）

### mise/config.toml と Renovate の関係

Renovate の `mise` manager は `config.toml` の `[tools]` セクションを自動認識する：

```toml
[tools]
"npm:aws-cdk" = "2.1034.0"   # → npm registry でバージョンチェック
"npm:@redocly/cli" = "1.34.4"
go = "1.24.5"                  # → Go リリースでバージョンチェック
```

---

## GitHub App インストール手順

1. https://github.com/apps/renovate にアクセス
2. **Install** をクリック
3. **Only select repositories** を選択して `barleytea/dotfiles` を指定
4. インストール完了後、Renovate が自動で dependency dashboard issue を作成

初回は既存バージョンのスキャン PR（"Configure Renovate"）が作成される。

---

## 動作確認

### 手動で PR をトリガーする場合

リポジトリの Issues に Renovate が作成する "Dependency Dashboard" issue から手動実行できる。

### ログ確認

```bash
# GitHub Actions タブで Renovate の実行ログを確認
gh run list --workflow=renovate
```

---

## バージョン更新の運用フロー

```
毎週月曜
  └─ Renovate が config.toml のバージョンを確認
       └─ 更新があれば PR を自動作成（mise tools グループでまとめて 1 PR）
            └─ PR をレビューして merge
                 └─ home-manager-apply で設定を反映
                      └─ mise install で新バージョンをインストール
```

```bash
# merge 後の適用手順
make home-manager-apply
mise install
```

---

## カスタマイズ

### スケジュール変更

```json
// renovate.json
"schedule": ["before 9am on monday"]     // 毎週月曜（現在）
"schedule": ["at any time"]              // 随時
"schedule": ["on the first day of the month"]  // 毎月1日
```

### automerge を有効にする場合（非推奨）

```json
"packageRules": [
  {
    "groupName": "mise tools",
    "matchManagers": ["mise"],
    "automerge": true,
    "automergeType": "pr"
  }
]
```

### 特定パッケージを除外する場合

```json
"packageRules": [
  {
    "matchPackageNames": ["aws-cdk"],
    "enabled": false
  }
]
```

---

## 関連ファイル

- `renovate.json` — Renovate 本体の設定
- `darwin/home-manager/mise/config.toml` — スキャン対象の mise ツール定義
- `darwin/home-manager/mise/default.nix` — config.toml を `~/.config/mise/config.toml` に配置
