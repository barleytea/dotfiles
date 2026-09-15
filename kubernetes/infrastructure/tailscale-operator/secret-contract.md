# Tailscale Operator の Secret 契約

`tailscale-operator` HelmRelease は公式チャートの既定値を使う。OAuth 認証情報は、Flux bootstrap 後に SOPS/age で暗号化した Secret として、次の名前・キーで `tailscale` namespace に用意する。

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: operator-oauth
  namespace: tailscale
stringData:
  client_id: "<Tailscale OAuth client ID>"
  client_secret: "<Tailscale OAuth client secret>"
```

実ファイルは `secrets/operator-oauth.sops.yaml` に置く。雛形
`secrets/operator-oauth.sops.yaml.example` をコピーし、SOPS で暗号化してから
`secrets/kustomization.yaml` の resource に追加する。雛形と plaintext の OAuth 値を
Git に追加しない。Flux の infrastructure Kustomization は `spec.decryption` で
`flux-system` namespace の `sops-age` Secret を参照する。OAuth client には Operator
用タグ `tag:k8s-operator` を作成できる権限を付与する。

Tailscale 公式の Helm chart は、`oauth.clientId` と `oauth.clientSecret` を指定した場合に Secret を生成し、未指定の場合は `operator-oauth` の `client_id` / `client_secret` を参照する。この構成は後者を使うため、`HelmRelease.spec.valuesFrom` で OAuth 値を渡さない。OAuth client と tailnet policy には、Operator/proxy用タグを作成できる Devices、Auth Keys、Services の必要な read/write scope とタグ所有権を設定する。チャートを更新する際は、使用バージョンの公式 `values.yaml` と [Kubernetes Operator の公式手順](https://tailscale.com/docs/kubernetes-operator) を再確認する。
