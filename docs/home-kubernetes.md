# Home Kubernetes とプライベート執筆環境の運用

この文書は、単一ノードの NixOS に k3s、Flux、Tailscale Kubernetes
Operator、Jellyfin を導入し、同じホストで AI 支援の小説執筆を行うための
運用手順である。設定の正本は NixOS 側が [`nixos/`](../nixos/)、Kubernetes
側が [`kubernetes/`](../kubernetes/) である。

実データを移動・削除する手順には明示的な確認点を設けている。原稿、OAuth
client secret、age 秘密鍵、GitHub token をリポジトリ・シェル履歴・画面共有
へ残さないこと。

## 目的と採用理由

この構成は可用性を最優先する本番クラスタではない。停止を許容する一台の
ホームサーバで、Kubernetes と GitOps を学びながら、Jellyfin を安全に
運用することが目的である。

- k3s は NixOS の `services.k3s` で管理でき、単一ノードで小さく始められる。
- Flux は Kubernetes リソースの変更を Git から再現可能にする。
- Tailscale Ingress は Jellyfin を tailnet 内だけに公開する。Funnel は使わない。
- Jellyfin はメディアを閲覧・視聴するためのアプリであり、ファイルを置く入口
  は既存の SMB/NFS のままにする。
- 執筆データは代替不能なユーザーデータなので Kubernetes から切り離す。Mac は
  SSH 端末に徹し、AI CLI、Git、Zellij、原稿の正本は NixOS 上だけに置く。

```text
メディアを追加する端末 ── SMB/NFS ──> /mnt/sda1/shares/media
                                           │ read-only hostPath
tailnet の視聴端末 ── HTTPS ───────────> Jellyfin Pod

Mac terminal ── Tailscale + SSH ───────> NixOS + Zellij + AI CLI
                                           └── /mnt/sda1/private/writing/novel
```

## 責務とデータ境界

| 層 | 管理対象 | 管理しないもの |
|---|---|---|
| NixOS | k3s、マウント、ホスト側ディレクトリ、SSH、Tailscale | Kubernetes の Deployment / Ingress |
| Flux | namespace、Tailscale Operator、Jellyfin | k3s 本体、ホスト上のファイル権限 |
| Jellyfin | `/media` の索引・視聴、`/config` の設定 | メディア原本の書換え |
| writing service | 原稿ディレクトリと世代バックアップ | SMB/NFS/PVC への公開 |
| 手動・Git 外 | 初回 Flux bootstrap、age 秘密鍵、Tailscale OAuth secret | 平文秘密情報のコミット |

| パス | 用途 | 取扱い |
|---|---|---|
| `/mnt/sda1/shares/media` | メディア原本 | Jellyfin からは読み取り専用 |
| `/mnt/sda1/k3s/storage` | local-path PVC の保存先 | 単一ノード専用。別ノードへ移動できない |
| `/mnt/sda1/k3s/jellyfin/config` | Jellyfin の設定・DB | バックアップ必須 |
| `/mnt/sda1/k3s/jellyfin/cache` | サムネイル等のキャッシュ | 再生成可能。初期バックアップ対象外 |
| `/mnt/sda1/private/writing/novel` | 原稿と Git 履歴の正本 | `miyoshi_s` 専用、SMB/NFS/Kubernetes 非公開 |
| `/mnt/sdb1/backup/private/writing` | 原稿の 14 世代日次バックアップ | 同一ホスト内。災害対策ではない |

`/mnt/sda1` と `/mnt/sdb1` は同一マシン内である。二台のディスクに分かれていても
盗難、火災、電源事故、ホスト故障を防げない。原稿を守るには、復元試験を済ませた
後に暗号化済みのオフサイトバックアップを別途追加する。

## セキュリティ境界

この構成の「private」は、原稿を一般的な共有一覧・Kubernetes・Mac のローカル
ファイルシステムから切り離す意味であり、ホストの root 権限を持つ人から隠す
暗号化ではない。

- 原稿ディレクトリは `0700` で作成され、SMB と NFS の export 対象外である。
- `tailscale0` は NixOS の trusted interface である。そのためホスト側 firewall
  だけで tailnet の利用者を細かく分離してはいない。SSH と Jellyfin を利用できる
  人・タグは **Tailscale の ACL / grants で制限する**。
- Jellyfin の Service は `ClusterIP`、Ingress は `tailscale` class である。LAN の
  ポート `8096` や Tailscale Funnel を設定しない。
- Mac に原稿ファイルや Git clone は作らない。ただし SSH の接続記録、terminal の
  scrollback・ウィンドウ復元、クリップボード、画面キャプチャは残り得る。本文を
  コピーしない、terminal の復元を無効化するなどは Mac 側で別途行う。
- クラウド AI に渡した本文は AI 提供者へ送信される。外部送信を避ける箇所は、NixOS
  上のローカルモデルだけを使う。

## 0. 導入前の確認

以下は **x86_64 NixOS 実機** 上で行う。macOS からのクロスビルドでは、Linux 用
NixOS toplevel を正しく検証できない。

```sh
cd /path/to/dotfiles
findmnt /mnt/sda1 /mnt/sdb1
df -h /mnt/sda1 /mnt/sdb1
git status --short
kubectl kustomize kubernetes/clusters/home >/dev/null
```

`findmnt` が二つのマウントを示さない場合はそこで停止する。k3s と writing service
は未マウントの `/mnt/sda1` / `/mnt/sdb1` にデータを作らないよう確認しているが、
ストレージ障害をアプリの設定変更で解決しない。

次も確認する。

- NixOS ホストが Tailscale へログイン済みである。
- tailnet の MagicDNS を有効にし、SSH と Jellyfin の利用端末・ユーザーを ACL
  で許可する計画がある。
- `shares/media` はメディア専用であり、原稿を置かない。
- k3s は単一 server/worker である。二台構成の etcd HA には移行しない。HA が必要に
  なった時点で、三台以上の server とストレージを設計し直す。

## 1. NixOS と k3s の初回適用

### 1.1 ビルドしてから適用する

`nixos-switch` はシステム状態を変更する。必ずビルド成功と差分を確認してから、
このホストを変更してよいタイミングで実行する。

```sh
cd /path/to/dotfiles
make nixos-build
git diff -- nixos/services/k3s nixos/services/writing nixos/services/default.nix
make nixos-switch
```

適用後はサービスとマウントを確認する。以下は状態を読むだけで、原稿の内容は
表示しない。

```sh
systemctl status k3s --no-pager
systemctl status k3s-storage-setup writing-directory-setup --no-pager
systemctl list-timers writing-backup.timer --all
findmnt /mnt/sda1 /mnt/sdb1
sudo journalctl -u k3s -b --no-pager -n 100
```

`k3s-storage-setup` が失敗している場合、Jellyfin の hostPath を手で作成して回避
しない。マウント状態と unit の失敗理由を修正してから k3s を起動する。

### 1.2 ユーザー用 kubeconfig

k3s の root 用 kubeconfig を NixOS 上の管理ユーザーだけが読むコピーへ作る。
このコピーを Mac に転送しない。以下の `$USER` は **NixOS 上で SSH ログインして
いる管理ユーザー** を指す。

```sh
install -d -m 0700 "$HOME/.kube"
sudo install -m 0600 /etc/rancher/k3s/k3s.yaml "$HOME/.kube/config"
sudo chown "$USER":"$(id -gn)" "$HOME/.kube/config"
export KUBECONFIG="$HOME/.kube/config"
kubectl get nodes -o wide
kubectl get storageclass
```

`Ready` の node と local-path の StorageClass が確認できるまで Flux を bootstrap
しない。`/etc/rancher/k3s/k3s.yaml` や `~/.kube/config` はクラスタ管理者認証情報を
含むので、Git へ追加しない。

### 1.3 反映前後の GitOps ツリー確認

Kubernetes YAML の静的な組立ては、クラスタへ変更を入れずに確認できる。

```sh
kubectl kustomize kubernetes/clusters/home >/dev/null
git diff --check
```

これは Kustomize の参照を検査するだけで、Helm chart の取得、Tailscale 認証、Pod の
起動を保証しない。

## 2. Flux bootstrap と秘密情報

### 2.1 現在のツリーで自動化されている範囲

現時点の `kubernetes/` は、Flux が同期した後に Tailscale Operator と Jellyfin を
展開するリソースを持つ。一方で次は意図的に Git に含めていない。

- `flux-system` の bootstrap 生成物
- `operator-oauth` の実値
- age 秘密鍵と Flux controller が参照する Secret
- `.sops.yaml`、暗号化 Secret、Flux Kustomization の `spec.decryption`

したがって、**このリポジトリをそのまま同期しても SOPS 復号は有効にならず、
Tailscale Operator は OAuth Secret がないため Ready にならない**。初回 bootstrap は
まず `flux-system` の生成物を作るために実行し、その直後に以下の Secret 管理用の小さな
変更をレビューして commit する。変更を取り込むまで Operator が Ready でないのは想定
内であり、平文 Secret で一時的に復旧させない。

1. age 公開鍵だけを使う `.sops.yaml` を追加する。
2. `operator-oauth.sops.yaml` を `tailscale` namespace の resource に加える。
3. bootstrap が生成する `flux-system` の Kustomization に SOPS decryption と
   `sops-age` Secret 参照を加える。

3 の Kustomization には少なくとも次の decryption 設定が必要である。これは
`flux-system` に作成される bootstrap manifest への変更なので、bootstrap 後に
対象ファイルを確認してから追加する。

```yaml
spec:
  decryption:
    provider: sops
    secretRef:
      name: sops-age
```

この三点を完了するまで、平文 Secret を `kubectl apply` して「後で GitOps 化する」
運用にはしない。Secret の契約は
[`secret-contract.md`](../kubernetes/infrastructure/tailscale-operator/secret-contract.md)
を正本とする。

### 2.2 GitHub を使う bootstrap

bootstrap は GitHub token を利用し、GitHub リポジトリへ `flux-system` の生成物を
commit する外部変更である。対象 owner、repository、branch、path を画面上で確認し、
意図しないリポジトリでないことを確認してから実行する。

```sh
flux check --pre

# 値は実在する GitHub owner/repository に置き換える。token をコマンド引数に書かない。
read -r -s GITHUB_TOKEN
export GITHUB_TOKEN
flux bootstrap github \
  --owner '<GitHub-owner>' \
  --repository '<repository>' \
  --branch main \
  --path kubernetes/clusters/home
bootstrap_status=$?
unset GITHUB_TOKEN
test "$bootstrap_status" -eq 0
```

個人アカウントのリポジトリで `flux bootstrap github --help` が要求する場合だけ
`--personal` を追加する。組織リポジトリでは付けない。token は最小権限・短寿命を
優先し、貼り付けた後は terminal の履歴にコマンド値が残っていないことを確認する。

bootstrap の直後に確認する。

```sh
flux check
flux get sources git -A
flux get kustomizations -A
```

失敗時に `kubectl get secret -o yaml` や `kubectl describe secret` を実行して秘密を
画面・ログに出さない。

### 2.3 SOPS/age と Tailscale OAuth

age 秘密鍵は NixOS 上だけに作り、権限 `0600` の個人用パスワードマネージャーと
オフライン媒体に復旧手順とともに保管する。age の公開鍵は Git に置いてよいが、
秘密鍵、Tailscale OAuth client secret、GitHub token は置かない。

SOPS の導入では Flux 公式の [SOPS guide](https://fluxcd.io/flux/guides/mozilla-sops/)
に従い、次の性質を満たすレビュー可能な変更を作る。

- `sops-age` は `flux-system` namespace にだけ手動作成し、controller が復号に使う。
- Git に置く `operator-oauth.sops.yaml` は暗号化済みで、名前は `operator-oauth`、
  namespace は `tailscale`、キーは `client_id` と `client_secret` である。
- `HelmRelease` に OAuth 値を `values` や `valuesFrom` として埋め込まない。現行
  chart は上記 Secret 名・キーを既定契約として参照する。
- OAuth client の scope と tag ownership は、使用する Tailscale Operator chart
  バージョンの [公式設定手順](https://tailscale.com/docs/kubernetes-operator) に照らして
  最小限にする。operator/proxy 用タグを作成できる権限も必要になる。

鍵の作成と cluster への bootstrap Secret 登録は、上記の Git 側変更をレビューしてから
NixOS 上で一度だけ行う。秘密鍵のファイル名・保存先は個人の復旧手順に記録するが、
このリポジトリや dotfiles 管理下に置かない。

```sh
umask 077
install -d -m 0700 "$HOME/.config/sops/age"
age-keygen -o "$HOME/.config/sops/age/keys.txt"
age-keygen -y "$HOME/.config/sops/age/keys.txt"

# 出力された公開鍵だけを .sops.yaml の recipient に使う。
# Flux bootstrap が完了し、decryption 設定を commit した後だけ実行する。
kubectl -n flux-system create secret generic sops-age \
  --from-file=age.agekey="$HOME/.config/sops/age/keys.txt" \
  --dry-run=client -o yaml | kubectl apply -f -
```

`age-keygen -y` の出力は公開鍵なので Git に置ける。`keys.txt` と上の `kubectl` が
作る bootstrap Secret は秘密である。`kubectl get secret -o yaml`、`sops --decrypt`、
terminal への値の貼り付けで内容を確認しない。暗号化 Secret は `sops` の編集画面で
直接作成・更新し、保存されたファイルが暗号化されていることと `metadata.name` /
`metadata.namespace` だけをレビューする。

暗号化 Secret と decryption 設定を commit した後、同期を要求して結果だけを確認する。

```sh
flux reconcile kustomization flux-system --with-source
flux get kustomizations -A
flux get helmreleases -A
```

Tailscale OAuth client の値を生成・表示する場面は、画面録画・共有・shell history
を停止してから行う。値を紛失すると Operator を再認証する必要があり、age 秘密鍵を
紛失すると暗号化 Secret を復号できない。

## 3. Jellyfin の初期利用

Flux が同期した後の確認は次の順で行う。

```sh
flux get helmreleases -A
kubectl get pods -A
kubectl get ingress -n jellyfin
kubectl get ingress jellyfin -n jellyfin \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}{"\n"}'
```

最後のコマンドが返す MagicDNS FQDN を、Tailscale に接続済みで ACL が許可する端末の
ブラウザから `https://` で開く。`jellyfin` という短い名前や URL を憶測で固定せず、
Ingress status を接続先の正本とする。HTTP の `:8096` を直接 LAN へ公開しない。

初回画面では管理者アカウントを作成し、ライブラリのメディアフォルダとして
`/media` を選ぶ。Pod 内の `/media` は `readOnly: true` なので、Jellyfin から
メディア原本を削除・名前変更できない。SMB/NFS でメディアを追加した後は Jellyfin
のライブラリスキャンを実行する。

この初期構成は CPU で Direct Play を優先する。GPU トランスコード、DLNA、Funnel、
複数 replica、HA は含まない。動画形式が再生端末に対応しない場合の変換性能を
求める段階で、NixOS 側の NVIDIA runtime と Kubernetes device plugin を別変更として
設計・検証する。

## 4. 原稿の非破壊移行と日常執筆

### 4.1 移行前の確認

既存の原稿は `/mnt/sda1/shares/public` と既存バックアップに平文で残っている可能性が
ある。今回の移行は、それらを自動削除しない。まず新しい正本が作成されたことだけを
確認する。

```sh
namei -l /mnt/sda1/private/writing/novel
systemctl status writing-directory-setup --no-pager
```

コピー対象のファイル名・容量・バックアップの有無を人間が確認してから、`rsync` の
source と destination を一行ずつ見直す。最初は `--dry-run` を付けて差分だけを確認
し、既存原稿を上書きしない空の destination にだけ実コピーする。

```sh
# <source-directory> は原稿だけを含む既存ディレクトリへ置換する。
rsync -aHn --human-readable --itemize-changes \
  '<source-directory>/' \
  /mnt/sda1/private/writing/novel/

# dry-run の対象と件数を承認した後だけ -n を外す。
rsync -aH --human-readable --itemize-changes \
  '<source-directory>/' \
  /mnt/sda1/private/writing/novel/
```

コピー完了後、通常の執筆アプリで開く・保存する、`git status` を確認する、日次
バックアップを一度成功させる、という順で検証する。旧原稿の削除・移動はこの検証と
復元試験が終わった後でも急がない。削除対象を列挙して本人が承認するまでは行わない。

`/var/lib/git/novel.git` が存在する場合、writing service は日次バックアップへ別に
複製するが、作業ツリーを自動で clone、push、再初期化しない。リモートとして使うか、
新しい正本内の `.git` だけを使うかは、既存履歴を確認してから人間が決める。

### 4.2 Mac を SSH terminal として使う

Mac には clone や SMB マウントを作らず、Tailscale 越しに NixOS へ SSH 接続する。

```sh
ssh -t miyoshi_s@<NixOS の Tailscale 名> \
  'zellij attach --create writing'
```

接続後に作業ディレクトリへ移動して、NixOS に導入済みの AI CLI を起動する。

```sh
cd /mnt/sda1/private/writing/novel
git status
```

AI の作業規約は原稿リポジトリの `AGENTS.md` に置く。配備用の
[`template/AGENTS.md`](../nixos/services/writing/template/AGENTS.md) は、AI が
本文を勝手に確定・削除・全文置換・履歴改変しないこと、変更前に範囲と差分を示す
ことを定める雛形である。雛形は自動コピーされないので、内容を確認してから正本へ
手動で追加する。

Git は小さな scene または章単位で commit し、AI の草稿・レビュー・人間が採用した
本文を混ぜない。同じファイルを複数の AI セッションで同時に編集させない。AI が
外部クラウドを利用する場合は、送信してよい本文だけを明示する。

## 5. バックアップと復元試験

バックアップが存在することと復元可能であることは別である。初回構築後、以後は
少なくとも月一回、原稿・Jellyfin・k3s の復元手順を別の安全な検証先で確認する。

### 5.1 現在自動化済みのもの

| 対象 | 現在の状態 | 確認方法 |
|---|---|---|
| 原稿の正本 | 日次 03:15、ランダム最大 15 分遅延、14 世代 | `systemctl list-timers writing-backup.timer --all` |
| 原稿の backup | `/mnt/sdb1/backup/private/writing/<timestamp>/novel` | `sudo systemctl status writing-backup --no-pager` |
| 既存 bare Git | 存在する場合だけ原稿 backup 世代へ複製 | 対象 backup 世代の `novel.git` の有無を確認 |
| Jellyfin `/config` | **未自動化** | 手動バックアップが必要 |
| k3s embedded etcd | **未自動化** | snapshot と server token を別途保全する |

原稿バックアップを今すぐ一回実行するには次を使う。作業中の書き込みと競合しない
タイミングを選ぶ。

```sh
sudo systemctl start writing-backup.service
sudo systemctl status writing-backup.service --no-pager
```

### 5.2 原稿の復元試験

正本を上書きせず、空の検証用ディレクトリへ一世代をコピーして、ファイルを開ける
ことと Git 履歴を確認する。以下の `<backup-generation>` は日時ディレクトリ名に
置き換える。

```sh
test_root=/mnt/sda1/private/writing-restore-test
install -d -m 0700 "$test_root"
rsync -aHn --numeric-ids \
  "/mnt/sdb1/backup/private/writing/<backup-generation>/novel/" \
  "$test_root/novel/"
```

dry-run の出力と destination が正しいことを確認してから `-n` を外す。復元試験後の
`writing-restore-test` は原稿のコピーを含む。削除は破壊的操作なので、保持不要である
ことを確認し、対象パスを明示してから本人が実行する。

正本への本番復元では、まず新しい backup 世代を取り、SSH/Zellij/AI の書込みを止める。
次に別パスへ復元して内容を検証し、正本を置換する必要性・対象・ロールバック方法を
本人が承認してから行う。既存正本に対する `rsync --delete` は承認なしに実行しない。

### 5.3 Jellyfin のバックアップと復元

`/config` には SQLite DB を含むため、稼働中にファイルを単純コピーしない。現在は
自動 backup unit がないため、Jellyfin の更新や設定変更の前に以下の保守手順を使う。

1. Jellyfin を停止して Pod が消えたことを確認する。
2. `/mnt/sda1/k3s/jellyfin/config` だけを `/mnt/sdb1` の日時付きディレクトリへ
   コピーする。`/cache` はコピーしない。
3. コピー先を検証してから Deployment を元の replica 数へ戻す。

```sh
kubectl -n jellyfin scale deployment/jellyfin --replicas=0
kubectl -n jellyfin wait --for=delete pod \
  -l app.kubernetes.io/name=jellyfin --timeout=120s

# backup path と既存世代を人間が確認してから実行する。
sudo rsync -aH --numeric-ids \
  /mnt/sda1/k3s/jellyfin/config/ \
  /mnt/sdb1/backup/k3s/jellyfin-config/<timestamp>/

kubectl -n jellyfin scale deployment/jellyfin --replicas=1
kubectl -n jellyfin rollout status deployment/jellyfin --timeout=180s
```

本番復元は停止中に行い、現在の `config` をすぐ戻せる別ディレクトリへ退避してから
バックアップをコピーする。`config` の置換、Jellyfin の再起動、ログイン・ライブラリ・
視聴履歴の確認を一組として実施する。Pod の削除だけで `/config` は消えないが、
ホストディスクの障害では失われる。

### 5.4 k3s etcd のバックアップと復元

この NixOS 設定は `clusterInit = true` の embedded etcd を使い、Kubernetes Secret
の at-rest encryption を有効にしている。etcd snapshot の定期取得と外部へのコピーは
まだ自動化していない。k3s の snapshot と
`/var/lib/rancher/k3s/server/token` を同じ世代として、アクセス制限された別ストレージ
へ保管する。server token は Secret と同等に扱い、内容を表示・Git 化しない。

snapshot 作成は NixOS ホスト上で次のように行う。

```sh
sudo k3s etcd-snapshot save --name manual-<YYYYMMDD-HHMM>
sudo k3s etcd-snapshot ls
```

復元はクラスタの現在状態を snapshot 時点へ戻す破壊的操作である。Pod、PVC、Flux の
同期状態を巻き戻し得るため、対象 snapshot、token の対応、Jellyfin/原稿 backup、
サービス停止時間を確認して本人が承認するまで実行しない。実施時は使用中 k3s
バージョンの [K3s backup and restore](https://docs.k3s.io/datastore/backup-restore)
に従い、通常は `k3s` 停止、`--cluster-reset --cluster-reset-restore-path` を使う
復元、再起動、node/Flux の健全性確認という順で行う。

## 6. 日常の状態確認と障害時の切り分け

### 6.1 読み取りだけの確認

```sh
systemctl is-active k3s writing-backup.timer
kubectl get nodes
kubectl get pods -A
flux get kustomizations -A
flux get helmreleases -A
kubectl get ingress -n jellyfin
```

Tailscale Operator が Ready でないときは、まず HelmRepository/HelmRelease の status と
controller logs を確認する。OAuth secret の中身を出力するコマンドは使わない。

```sh
kubectl -n tailscale get helmrepository,helmrelease
kubectl -n tailscale get pods
kubectl -n tailscale logs deploy/tailscale-operator --tail=100
```

Jellyfin が起動しないときは、media mount、config/cache の hostPath、Pod の events を
確認する。`/media` を read-write に変更して回避しない。

```sh
kubectl -n jellyfin get pods
kubectl -n jellyfin describe pod -l app.kubernetes.io/name=jellyfin
kubectl -n jellyfin logs deploy/jellyfin --tail=100
findmnt /mnt/sda1
```

### 6.2 変更の基本順序

1. NixOS の変更は `make nixos-build` で評価する。
2. Kubernetes manifest は `kubectl kustomize kubernetes/clusters/home` で組み立てる。
3. 秘密を含まない変更だけを Git へ commit する。SOPS 暗号化済み Secret は差分の
   暗号化状態と namespace/name だけをレビューする。
4. `make nixos-switch` や Flux bootstrap のような状態変更は、対象とロールバックを
   確認してから実行する。
5. 反映後は k3s、Flux、Tailscale Operator、Jellyfin の順で Ready を確認する。

## 7. CI とローカル検証の範囲

現行の GitHub Actions では `nixos/**` の変更は NixOS toplevel build を検証するが、
`kubernetes/**` 単独の変更で Kustomize 検証を行う workflow はない。したがって
Kubernetes manifest を変更した PR では、少なくともローカルまたは NixOS ホストで
次を実行する。

```sh
kubectl kustomize kubernetes/clusters/home >/dev/null
make pre-commit-run
git diff --check
```

これらは静的検証であり、Flux bootstrap の外部 Git 変更、SOPS 復号、Tailscale OAuth、
Helm chart の実インストール、Jellyfin の実再生を代替しない。CI を追加する場合は、
秘密を使わず `kubectl kustomize` だけを実行する専用 job と `kubernetes/**` の path
trigger を追加する。

## 参照

- [kubernetes/README.md](../kubernetes/README.md): GitOps ツリーと Operator の Secret 契約
- [nixos/services/writing/README.md](../nixos/services/writing/README.md): 原稿用 service の詳細
- [K3s backup and restore](https://docs.k3s.io/datastore/backup-restore)
- [Flux SOPS guide](https://fluxcd.io/flux/guides/mozilla-sops/)
- [Tailscale Kubernetes Operator](https://tailscale.com/docs/kubernetes-operator)
- [Jellyfin backup and restore](https://jellyfin.org/docs/general/administration/backup-and-restore/)
