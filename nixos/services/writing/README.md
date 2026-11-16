# Private writing service

このモジュールは、NixOS 上の `/mnt/sda1/private/writing/novel` を本文の正本として扱う。ディレクトリは `miyoshi_s` に限定した `0700` で準備され、既存の本文や `/var/lib/git/novel.git` を初期化・移動・削除しない。

このリポジトリでは [`nixos/services/default.nix`](../default.nix) で
`services.writing.enable = true;` を有効にしている。SMB、NFS、Kubernetes の共有設定には
このパスを追加しないこと。原稿を別のホストや利用者から見つけにくくするための分離で
あり、NixOS の root 権限を持つ人から暗号学的に隠すものではない。

Hermes固有のHome Manager moduleとhelperは、外部flake
[`gyokuroo/hermes-writing-nix`](https://github.com/gyokuroo/hermes-writing-nix)から
読み込む。ここではhost固有の`services.hermes-writing`値と、原稿正本・マウント・日次backup
の運用だけを管理する。外部repoに原稿、OAuth、Discord環境変数、GitHub認証状態を保存しない。

正本のパス、AI 利用規約、Mac 側に残り得る痕跡、非破壊移行、復元試験は
[Home Kubernetes とプライベート執筆環境の運用](../../../docs/home-kubernetes.md) を
参照する。

## Hermes 執筆エージェント

外部moduleは `miyoshi_s` の Home Manager user service として一つの gateway を起動する。
公式 v0.23.1 を使い、ChatGPT subscription の `openai-codex` provider と公式 catalog の
`gpt-6-sol` tag を既定にする。`users.users.miyoshi_s.linger = true` により、SSH logout
後も user service を継続する。

```text
HERMES_HOME: /mnt/sda1/private/writing/hermes
worktree:    /mnt/sda1/private/writing/worktrees/hermes
branch:      agent/hermes-writing
```

初期 job は Nix 設定へ埋め込まず、導入後に writer cron を一つだけ登録する。writer は
5分間隔で checkpoint/progress から scene 単位を継続し、`cron.max_parallel_jobs = 1` と
retry/catch-up を使う。完了時は checkpoint 更新、branch への commit、自分の job remove、
Discord 通知の順に行う。CLI/Discord は目標・指示・状態確認・pause/resume 専用で、正本への
自動 merge・push は行わない。

Hermes に全 run 用の OS-level lock hook はない。単一 writer とし、手編集は cron pause、
running worker の終了確認後だけ行う。checkpoint と commit の短い処理は lock で保護するが、
これは運用上の排他であり root や別プロセスを強制的に遮断するものではない。

初回準備は NixOS 上の SSH shell から次の順で行う。

```sh
# activation 前に作成する。既に activation 済みなら作成後に NixOS/HM をもう一度適用する。
# /mnt/sda1/private/writing/hermes.env を 0600 で作成し、Discord の runtime env を手動投入
hermes-writing-init
hermes auth add openai-codex --type oauth
hermes-writing-ready
hermes gateway start
# /mnt/sda1/private/writing/worktrees/hermes/progress/goal.md に目標・完了条件を記入
hermes-writing-start
```

`hermes-writing-start` は `progress/goal.md` の完了条件を確認し、writer cron を重複なく
登録する。`hermes-writing-ready` は storage、branch、source/common Git の接続を確認する。
`hermes-writing-status` は状態確認、`hermes-writing-checkpoint` と
`hermes-writing-commit` は lock 付きの短い更新に使う。

GitHub の認証と commit author は Hermes 専用の `gyokuroo` に分離する。初回だけ
`hermes-gh auth login --hostname github.com` を実行し、`hermes-gh-user` が `gyokuroo` を
表示することを確認する。親の個人 account を switch/logout せず、repo 移管・新規 repo 作成・
自動 push は行わない。Discord bot env、OAuth、GitHub login は手動入力とし、秘密値は Git と
backup に含めず、復元時に再認証する。

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

バックアップは正本の `novel/`、Hermes の非秘密 state（cron/checkpoint/ledger）、固定
worktree、common Git、存在する場合の `/var/lib/git/novel.git` を保存する。`auth.json`、
`.env`、OAuth/token/credential ファイルは除外する。writer cron を pause し、running worker
と external worker の終了、gateway の正常停止、state DB/WAL の終了を確認してから rsync
する。待機上限は30分とし、timeout 時は backup を中断して元の稼働状態へ戻す。

`/mnt/sda1` と `/mnt/sdb1` は同じホストにあるため、災害・盗難対策ではない。正本を上書き
せず別パスへ復元する試験を定期的に行う。実際の復元手順と削除前の確認点は
[運用ガイド](../../../docs/home-kubernetes.md#51-原稿の復元試験)を参照。
