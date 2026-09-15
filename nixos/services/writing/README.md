# Private writing service

このモジュールは、NixOS 上の `/mnt/sda1/private/writing/novel` を本文の正本として扱う。ディレクトリは `miyoshi_s` に限定した `0700` で準備され、既存の本文や `/var/lib/git/novel.git` を初期化・移動・削除しない。

このリポジトリでは [`nixos/services/default.nix`](../default.nix) で
`services.writing.enable = true;` を有効にしている。SMB、NFS、Kubernetes の共有設定には
このパスを追加しないこと。原稿を別のホストや利用者から見つけにくくするための分離で
あり、NixOS の root 権限を持つ人から暗号学的に隠すものではない。

正本のパス、AI 利用規約、Mac 側に残り得る痕跡、非破壊移行、復元試験は
[Home Kubernetes とプライベート執筆環境の運用](../../../docs/home-kubernetes.md) を
参照する。

## Mac からの接続

原稿名を含めないホスト名で Tailscale 経由 SSH 接続し、zellij のセッション内で作業する。

```sh
ssh -t miyoshi_s@<NixOS の Tailscale 名> 'zellij attach --create writing'
```

SSH は通常の OpenSSH と公開鍵認証を使う。NixOS は `tailscale0` を trusted interface に
しているため、誰が SSH を利用できるかは Tailscale ACL / grants で制限する。Mac に
原稿の clone や SMB マウントを作らず、AI CLI、Git、Zellij は NixOS 上で実行する。

原稿リポジトリへ AI 用規約を置く場合は、[`template/AGENTS.md`](template/AGENTS.md) を
内容確認後に手動でコピーする。このテンプレートは自動配備されない。

## バックアップ

日次で `/mnt/sdb1/backup/private/writing/YYYY-MM-DD_HH-MM-SS/` に保存し、14 世代を保持する。両ストレージのマウント確認、正本の非空確認、正本が `/mnt/sda1` と同じデバイス上にあることの確認に失敗した場合は処理しない。

```sh
systemctl list-timers writing-backup.timer --all
sudo systemctl status writing-backup.service --no-pager
```

バックアップは正本の `novel/` と、存在する場合だけ `/var/lib/git/novel.git` を別の
`novel.git/` として保存する。`/mnt/sda1` と `/mnt/sdb1` は同じホストにあるため、
災害・盗難対策ではない。正本を上書きせず別パスへ復元する試験を定期的に行う。実際の
復元手順と削除前の確認点は [運用ガイド](../../../docs/home-kubernetes.md#51-原稿の復元試験)
を参照。
