# Home Kubernetes GitOps

`clusters/home` は単一ノード k3s 用の Flux 同期起点。NixOS が k3s とホスト側ディレクトリを管理し、このディレクトリはクラスタ内リソースだけを管理する。Flux bootstrap の生成物と秘密情報は、この初期コミットには含めない。

```text
clusters/home             Flux の同期起点
infrastructure/           Tailscale Operator
apps/jellyfin/            Jellyfin と private Ingress
```

## 管理境界

- NixOS: k3s、`/mnt/sda1/k3s`、`/mnt/sda1/shares/media`、ホストのファイアウォール
- Flux: namespace、HelmRepository、HelmRelease、Jellyfin の Deployment/Service/Ingress
- 手動かつ Git 外: Flux bootstrap、SOPS/age 復号鍵、Tailscale OAuth client secret

Jellyfin の `/media` は `/mnt/sda1/shares/media` を read-only の `hostPath` として参照する。`/config` と `/cache` は `/mnt/sda1/k3s/jellyfin/` を使う。`/config` はバックアップ対象、`/cache` は再生成可能なため初期バックアップ対象外。

## 初回セットアップの前提

初回適用は x86_64 NixOS 実機で `make nixos-build` を成功させてから行う。k3s モジュールは
hostPath と local-path の保存先を準備する。root の k3s kubeconfig は NixOS 上の管理
ユーザー専用 `~/.kube/config` に安全な権限で複製し、`kubectl get nodes` が Ready を
示すことを確認する。kubeconfig を Mac へ転送しない。

Flux bootstrap は GitHub token を使い、`flux-system` の同期マニフェストを Git へ
commit する外部変更である。対象 owner、repository、branch、path を確認し、
`kubernetes/clusters/home` を同期起点として bootstrap する。手順と確認コマンドは
[運用ガイド](../docs/home-kubernetes.md#2-flux-bootstrap-と秘密情報) を参照。

### SOPS 導入前の制限

現在の初期ツリーには、Flux bootstrap 生成物、`.sops.yaml`、暗号化 Secret、Flux
Kustomization の `spec.decryption` が含まれない。そのため SOPS/age を使うための
review 済み変更なしにこのツリーを同期しても、`operator-oauth` は作成されない。
平文 OAuth secret を Git へ置く、または暫定的に手動 apply する運用は行わない。

SOPS を導入する変更では、age 公開鍵を用意し、`flux-system` namespace の `sops-age`
Secret と decryption 設定を追加する。`tailscale` namespace の
`operator-oauth.sops.yaml` は暗号化済みで管理する。具体的な順序と鍵の保管方法は
[運用ガイド](../docs/home-kubernetes.md#23-sopsage-と-tailscale-oauth) を参照。

手順 4 の Secret は公式チャートの既定契約を使う。名前は `operator-oauth`、キーは `client_id` と `client_secret`。チャートに OAuth 値を `valuesFrom` で渡さず、既定の Secret volume を使うため、値を HelmRelease に埋め込まない。OAuth client は operator/proxy 用タグを作成できるように、Tailscale の Devices、Auth Keys、Services の必要な read/write scope とタグ所有権を設定する。

`helmrelease.yaml` は Tailscale Operator chart `1.102.3` を固定し、`installCRDs: true` を明示して Operator の CRD を chart に管理させる。このツリーが作るのは標準 Kubernetes の `Ingress` だけなので、Ingress は Operator と IngressClass が Ready になるまで待機してから処理される。Tailscale の専用 CR を追加する場合は、Operator HelmRelease を先に Ready にする Flux の依存関係を追加する。

Jellyfin は公式コンテナ `ghcr.io/jellyfin/jellyfin:12.0` に固定する。GPU runtime、DLNA、Funnel、HA は初期スコープ外。Tailscale Ingress は private HTTPS のみを提供し、Funnel を有効化する設定は含めない。

## Jellyfin の初期利用

Operator と Ingress が Ready になった後、Ingress status に記録された MagicDNS FQDN を
Tailscale 接続済み・ACL 許可済みの端末から HTTPS で開く。接続先を短いホスト名や
`8096` と決め打ちしない。

```sh
kubectl get ingress jellyfin -n jellyfin \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}{"\n"}'
```

初回画面で管理者アカウントを作り、メディアライブラリとして `/media` を選ぶ。
`/media` は hostPath の read-only mount なので、Jellyfin から原本を変更できない。
メディアを SMB/NFS で追加した後は Jellyfin のライブラリスキャンを実行する。

Jellyfin `/config` のバックアップは現時点で自動化していない。設定更新前には Pod を
停止してから `/config` だけを別ディスクへコピーする。詳細な停止・復元手順は
[運用ガイド](../docs/home-kubernetes.md#53-jellyfin-のバックアップと復元) を参照。

## 検証

クラスタへ反映せずに構文と参照を確認するには、リポジトリルートで次を実行する。

```sh
kubectl kustomize kubernetes/clusters/home
```

実クラスタでの同期後は、`flux get sources helm -A`、`flux get helmreleases -A`、`kubectl get ingress -n jellyfin` で状態を確認する。Secret の内容を表示するデバッグコマンドは実行しない。

GitHub Actions には `kubernetes/**` 単独の変更を検証する workflow がない。manifest を
変更した PR では、ローカルで `kubectl kustomize kubernetes/clusters/home`、
`make pre-commit-run`、`git diff --check` を実行する。これらは静的検証であり、
Helm chart の実インストールや OAuth 認証は確認しない。

## 参照

- [Tailscale Kubernetes Operator](https://tailscale.com/docs/kubernetes-operator)
- [Tailscale Ingress](https://tailscale.com/docs/kubernetes-operator/ingress)
- [Tailscale Operator chart values](https://github.com/tailscale/tailscale/blob/main/cmd/k8s-operator/deploy/chart/values.yaml)
- [Flux HelmRelease valuesFrom](https://fluxcd.io/flux/components/helm/helmreleases/)
- [Jellyfin container](https://jellyfin.org/docs/general/installation/container/)
