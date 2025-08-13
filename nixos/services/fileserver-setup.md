# NixOS ファイルサーバ セットアップ手順

## 1. 初期設定適用

```bash
# 設定を適用
sudo nixos-rebuild switch

# 再起動（初回のみ推奨）
sudo reboot
```

## 2. Tailscale認証

```bash
# Tailscale認証（初回のみ）
sudo tailscale up --accept-routes --advertise-exit-node

# ブラウザでOAuth認証を実行
# → Google/GitHub等でログイン
```

## 3. Tailscale設定確認

```bash
# 接続状態確認
tailscale status

# ネットワークチェック
tailscale netcheck

# IP確認
tailscale ip -4
```

## 4. Sambaユーザー設定

```bash
# Sambaユーザー追加
sudo smbpasswd -a miyoshi_s
# → パスワードを設定

# Sambaユーザー確認
sudo pdbedit -L
```

## 5. サービス起動確認

```bash
# 全サービス状態確認
systemctl status tailscaled
systemctl status smbd nmbd
systemctl status nfs-server

# ディレクトリセットアップ確認
systemctl status fileserver-directory-setup
```

## 6. ディレクトリ確認

```bash
# 作成されたディレクトリ確認
ls -la /mnt/sda1/shares/
ls -la /mnt/sdb1/backup/

# 権限確認
ls -la /mnt/sda1/shares/*/
```

## 7. 接続テスト

### SMB接続テスト
```bash
# ローカルテスト
smbclient -L localhost -U miyoshi_s

# Tailscale経由テスト
smbclient -L nixos.tail-scale.ts.net -U miyoshi_s
```

### NFS接続テスト
```bash
# エクスポート確認
showmount -e localhost

# Tailscale経由
showmount -e nixos.tail-scale.ts.net
```

## 8. クライアント接続

### Windows
```
# エクスプローラーのアドレスバー
\\nixos\public
```

### macOS
```bash
# Finder → サーバへ接続
smb://nixos/public
```

### Linux
```bash
# SMBマウント
sudo mkdir /mnt/nixos-public
sudo mount -t cifs //nixos/public /mnt/nixos-public -o username=miyoshi_s

# NFSマウント
sudo mkdir /mnt/nixos-docker
sudo mount -t nfs nixos:/mnt/sda1/shares/docker /mnt/nixos-docker
```

## 9. 監視・バックアップ確認

```bash
# 監視タイマー確認
systemctl list-timers | grep -E "(disk-monitor|tailscale-monitor|fileserver-backup)"

# ログ確認
journalctl -u disk-monitor -n 10
journalctl -u tailscale-monitor -n 10
```

## 10. トラブルシューティング

### Tailscale接続問題
```bash
# ログ確認
journalctl -u tailscaled -f

# 再認証
sudo tailscale down
sudo tailscale up --accept-routes --advertise-exit-node
```

### SMB接続問題
```bash
# Sambaログ確認
journalctl -u smbd -n 50
journalctl -u nmbd -n 50

# 設定確認
sudo testparm
```

### NFS接続問題
```bash
# NFSログ確認
journalctl -u nfs-server -n 50

# エクスポート確認
sudo exportfs -v
```

### 権限問題
```bash
# ディレクトリ権限確認
ls -la /mnt/sda1/shares/

# ACL確認
getfacl /mnt/sda1/shares/public

# 権限修復
sudo systemctl restart fileserver-directory-setup
```

## セットアップ完了後の確認項目

- [ ] Tailscale認証完了
- [ ] すべてのサービスが起動中
- [ ] ディレクトリが正しく作成・権限設定
- [ ] SMB接続可能
- [ ] NFS接続可能（Linux）
- [ ] 監視タイマーが動作中
- [ ] バックアップタイマーが設定済み

## 日常的な管理コマンド

```bash
# ディスク使用量確認
df -h /mnt/sda1 /mnt/sdb1

# Tailscale状態確認
tailscale status

# サービス状態確認
systemctl status tailscaled smbd nmbd nfs-server

# バックアップ状況確認
ls -la /mnt/sdb1/backup/sda1-mirror/

# ログ確認
journalctl -u tailscaled -f
journalctl -u smbd -f
journalctl -u fileserver-backup -f
``` 