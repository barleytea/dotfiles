# Git SSH Server

NixOSでSSH経由でアクセス可能なGitベアリポジトリサーバーを構築するモジュールです。

## 機能

- SSH公開鍵認証によるセキュアなアクセス
- 自動的なベアリポジトリの初期化
- git-shellによる制限されたシェルアクセス
- systemdサービスによる自動管理

## セットアップ

### 1. SSH公開鍵の準備

まず、アクセスするクライアントマシンでSSH鍵ペアを生成します（既に持っている場合はスキップ）：

```bash
# クライアントマシンで実行
ssh-keygen -t ed25519 -C "your_email@example.com"
```

公開鍵の内容を確認：
```bash
cat ~/.ssh/id_ed25519.pub
```

### 2. 設定の有効化

`nixos/configuration.nix`または別の設定ファイルに以下を追加：

```nix
{
  services.gitserver = {
    enable = true;

    # SSH公開鍵を追加（クライアントの公開鍵）
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExampleKey user@client-machine"
      # 複数のクライアントからアクセスする場合は、ここに追加
    ];

    # 初期化するリポジトリ名
    repositories = [
      "myproject.git"
      "dotfiles.git"
    ];
  };
}
```

### 3. 設定の適用

```bash
sudo nixos-rebuild switch --flake .#desktop
```

## 使用方法

### NixOSマシン上でのアクセス

NixOSマシン自体からアクセスする場合：

```bash
# クローン
git clone git@localhost:myproject.git

# または、ローカルパスを直接指定
git clone /var/lib/git/myproject.git
```

### リモートクライアントからのアクセス

別のマシンからSSH経由でアクセス：

```bash
# クローン（NixOSマシンのIPアドレスまたはホスト名を指定）
git clone git@nixos-hostname:myproject.git
git clone git@192.168.1.100:myproject.git

# 既存のリポジトリにリモートを追加
git remote add origin git@nixos-hostname:myproject.git
git push -u origin main
```

### 新しいリポジトリの追加

設定ファイルの`repositories`リストに追加して、再適用：

```nix
services.gitserver.repositories = [
  "myproject.git"
  "dotfiles.git"
  "newrepo.git"  # 追加
];
```

```bash
sudo nixos-rebuild switch --flake .#desktop
```

### 手動でリポジトリを作成

設定ファイルを変更せずに手動で作成することも可能：

```bash
# gitユーザーとして実行
sudo -u git git init --bare /var/lib/git/newrepo.git
```

## トラブルシューティング

### SSHアクセスのテスト

```bash
# クライアントマシンから
ssh git@nixos-hostname

# 成功すると以下のようなメッセージが表示されます：
# fatal: Interactive git shell is not enabled.
# hint: ~/git-shell-commands should exist and have read and execute access.
# Connection to nixos-hostname closed.
```

これは正常な動作です。git-shellは対話的なシェルアクセスを許可しません。

### リポジトリの確認

```bash
# NixOSマシン上で実行
sudo ls -la /var/lib/git/
```

### SSH鍵の確認

```bash
# NixOSマシン上でgitユーザーの公開鍵を確認
sudo cat /var/lib/git/.ssh/authorized_keys
```

### ファイアウォールの確認

```bash
# SSH ポート（22）が開いているか確認
sudo nix-instantiate --eval -E '(import <nixpkgs> {}).networking.firewall.allowedTCPPorts'
```

## 設定オプション

### services.gitserver.enable
- 型: `boolean`
- デフォルト: `false`
- 説明: Git SSH サーバーを有効化

### services.gitserver.user
- 型: `string`
- デフォルト: `"git"`
- 説明: Gitリポジトリ用のユーザー名

### services.gitserver.group
- 型: `string`
- デフォルト: `"git"`
- 説明: Gitリポジトリ用のグループ名

### services.gitserver.repoDir
- 型: `path`
- デフォルト: `"/var/lib/git"`
- 説明: Gitベアリポジトリの保存ディレクトリ

### services.gitserver.authorizedKeys
- 型: `listOf string`
- デフォルト: `[]`
- 説明: SSH公開鍵のリスト
- 例: `["ssh-ed25519 AAAAC3... user@host"]`

### services.gitserver.repositories
- 型: `listOf string`
- デフォルト: `[]`
- 説明: 初期化するベアリポジトリ名のリスト
- 例: `["myproject.git", "dotfiles.git"]`

## セキュリティ

- パスワード認証は無効化されています
- 公開鍵認証のみが許可されます
- gitユーザーはgit-shellに制限されており、通常のシェルアクセスはできません
- rootログインは無効化されています

## バックアップ

リポジトリのバックアップは`/var/lib/git/`ディレクトリ全体をコピーするだけです：

```bash
# バックアップ
sudo tar czf git-backup-$(date +%Y%m%d).tar.gz /var/lib/git/

# リストア
sudo tar xzf git-backup-20231225.tar.gz -C /
sudo chown -R git:git /var/lib/git/
```
