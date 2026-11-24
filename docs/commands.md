# Commands

`make help` で日本語の対話的ヘルプ（`less`）が開く。`make help-fzf` なら fzf で選択 → 実行できる。

ここでは目的別に主要ターゲットを整理する。**全ターゲットは Makefile の `## コメント` を SoT とする**。

## 1. Nix（macOS / nix-darwin）

| ターゲット | 説明 | flake.lock 更新 |
|------------|------|-----------------|
| `make home-manager-apply` | HM 設定を適用（推奨） | ✅（事前に `flake-update-darwin`） |
| `make home-manager-switch` | HM 設定を適用（lock 更新なし） | ❌ |
| `make home-manager-build` | ビルドのみ | ❌ |
| `make nix-darwin-apply` | nix-darwin の `all` 設定を適用 | ❌（apply 時は更新せず） |
| `make nix-darwin-homebrew-apply` | Homebrew 設定のみ | ❌ |
| `make nix-darwin-system-apply` | system.defaults のみ | ❌ |
| `make nix-darwin-check` | ビルドチェックのみ | ❌ |
| `make nix-update-all` | チャンネル更新 + HM apply + nix-darwin apply | ✅ |
| `make nix-check-all` | チャンネル更新 + HM apply + nix-darwin check（ローカル CI 相当） | ✅ |
| `make nix-check-all-ci` | チャンネル更新 + HM switch + nix-darwin check（旧 CI 互換、lock 更新なし） | ❌ |

> ⚠️ `home-manager-apply` は内部で `flake-update-darwin` を呼ぶ副作用がある（lock を必ず更新する）。lock を変えたくないときは `make home-manager-switch` を使うこと。

### GitHub HTTPS 認証

macOS では、Home Manager が `https://github.com/` への Git 接続に GitHub CLI の
認証ヘルパーを設定する。別アカウントの Git 設定を読み込む作業ツリーと、
ほかの HTTPS ホストへの接続には `osxkeychain` を使う。

変更は `make home-manager-switch` で反映する。Home Manager が読み取り専用の
`~/.config/git/config` を生成するため、`gh auth setup-git` は不要。
普段 Git を使うシェルで `gh auth status` を実行し、認証状態を確認する。
`OWNER` と `REPOSITORY` を通常の設定を使う GitHub の非公開リポジトリに置き換える。
別アカウント用の作業ツリー外から、適用済みの全体設定で接続できることを確認する。
トークンは dotfiles に記録しない。

```sh
(
	cd /tmp || exit
	GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL="$HOME/.config/git/config" \
		GIT_TERMINAL_PROMPT=0 git ls-remote --exit-code https://github.com/OWNER/REPOSITORY.git HEAD
)
```

## 2. Nix（NixOS）

| ターゲット | 説明 |
|------------|------|
| `make nixos-switch` | システム設定（HM 含む）を適用 |
| `make nixos-build` | ビルドのみ |

NixOS 側には `home-manager-apply` 相当のターゲットは無い（HM は system flake に統合済み）。

## 3. flake.lock 操作

| ターゲット | 対象 |
|------------|------|
| `make flake-update-darwin` | `darwin/flake.lock` |
| `make flake-update-nixos` | `nixos/flake.lock` |
| `make flake-update-nixvim` | `nixvim/flake.lock` |
| `make flake-update-all` | 上記 3 つを順次 |

`flake-update-*` は専用ブランチで行い、機能変更を伴う PR には混ぜないこと。

## 4. Nix メンテナンス

| ターゲット | 説明 |
|------------|------|
| `make nix-channel-update` | nixpkgs-unstable に更新 |
| `make nix-gc` | `sudo nix-collect-garbage -d` |
| `make nix-uninstall` | Nix の完全アンインストール |

## 5. Nixvim（スタンドアロン）

`nix run ./nixvim` で起動。flake のみ管理対象で、Make ターゲットは `flake-update-nixvim` のみ。

## 6. pre-commit

| ターゲット | 説明 |
|------------|------|
| `make pre-commit-init` | フックをインストール（mise 経由） |
| `make pre-commit-run` | 全ファイルに対し実行 |

設定は `.pre-commit-config.yaml`。`gitleaks` で秘密情報スキャン、基本フックで trailing whitespace / EOL fixer / YAML check 等。

## 7. VSCode

| ターゲット | 説明 |
|------------|------|
| `make vscode-apply` | 設定と拡張機能を適用 |
| `make vscode-insiders-apply` | Insiders 版に同じ操作 |
| `make vscode-save` | 現在の拡張機能一覧を保存 |
| `make vscode-sync` | 設定を同期 |

## 8. mise

| ターゲット | 説明 |
|------------|------|
| `make mise-install-all` | mise 管理ツール全てをインストール |
| `make mise-install-npm-commitizen` | commitizen / cz-git を global インストール |
| `make mise-run-safe-chain-setup` | aikido safe-chain のセットアップ |
| `make mise-update-npm-tools` | npm CLI の pin を min-age 制約付きで最新化（`MISE_NPM_MIN_AGE_DAYS` で日数指定可、デフォルト 7） |
| `make mise-list` | ツール一覧 |
| `make mise-config` | mise の設定表示 |

Agent Skills は `modules/home/agent-skills/registry.json` のレジストリに従って mise タスクで同期する。外部 skill は空の staging に導入し、dotfiles管理のスキルは同じ staging にローカルコピーしてから、対象 skill だけを `~/.agents/skills` 内で置き換える。Claude、Codex旧形式、Cursor向けリンクも同期する。Nix が管理する `review-*` と `imozuru` は維持され、全件同期では管理対象 skill や skill 内の古いファイルも片付く。

```sh
# dotfiles のリポジトリルートから実行
mise run agent-skills
# 指定したスキルだけを更新し、他の管理対象を触らない
mise run agent-skills --only nihongo

# skill を探す
gh skill search cloudflare
```

同期対象は `modules/home/agent-skills/registry.json` に宣言する。`nihongo` の正本は `modules/home/claude/config/skills/nihongo/` にあり、Claude向けにはHome Managerがリンクし、`~/.agents/skills/` へはこのタスクがコピーする。`--only` は指定した skill だけを更新し、他の管理対象を削除しない。`gh` は外部skill用に必要で、Darwin / NixOS では Nix、Windows CTF の WSL では apt で導入する。`gh skill` は GitHub CLI の preview 機能。以前 `npx skills` などで入れたスキルは自動では移行されないため、同期タスクを実行すると宣言済みのスキルが導入される。

## 9. その他ユーティリティ

| ターゲット | 説明 |
|------------|------|
| `make zsh` | zsh の起動時間を測定 |
| `make paths` | `$PATH` を改行区切りで表示 |
| `make windows-ctf-help` | `windows-ctf/Makefile` のヘルプを呼ぶ |
| `make windows-host-help` | Windows ホスト UX ガイドの場所表示 |
| `make windows-ctf-dump-wt-settings` | Windows Terminal 設定を dotfiles に dump |

## 10. Codex pstack plugin

`make home-manager-switch` の Home Manager activation が commit 固定の `michael-denyer/pstack-claude` marketplace と `pstack` plugin を冪等に導入する。初回導入後は Codex を再起動し、`/hooks` で SessionStart hook を確認して trust してから、`$setup-pstack` でモデルを選ぶ。自動ルーティングを止める場合は `~/.codex/pstack-models.md` に `session hook: off` を記述する。pstack は第三者による Codex 向け移植版。

手動導入・更新は以下のコマンドで行う。

```bash
codex plugin marketplace add michael-denyer/pstack-claude --ref a12b04786023e762f12f5de7bb5fafb8c23f8c36 --sparse .agents/plugins --sparse plugins/pstack
codex plugin add pstack@pstack-claude
```

更新時は `modules/home/codex/install-plugins.sh` の commit を更新し、既存の plugin と marketplace を削除してから `make home-manager-switch` を実行する。plugin の hook 定義が変わった場合、Codex は改めて trust を求める。

## 11. 環境変数

| 変数 | 既定値 | 用途 |
|------|--------|------|
| `NIX_PROFILE` | 自動検出 | Nix 環境変数 source 元の `profile.d` スクリプト |
| `NIXVIM_CONFIG_INPUT` | `path:../nixvim` | flake input `nixvim-config` の override 先 |
| `DOTFILES_SHARED_INPUT` | `path:../modules` | flake input `dotfiles-shared` の override 先 |
| `MISE_NPM_MIN_AGE_DAYS` | `7` | `mise-update-npm-tools` の min-age 日数 |

## 12. CI 想定の使い分け

| シナリオ | ローカル | CI |
|----------|----------|----|
| macOS PR 検証 | `make nix-check-all` | HM CI activation package / nix-darwin / nixvim の `nix build` を個別に直接実行 |
| NixOS PR 検証 | `make nixos-build` | `nix build path:.#nixosConfigurations.desktop.config.system.build.toplevel ...` を直接実行 |
| nixvim PR 検証 | `nix build ./nixvim` | `nix build .#packages.<system>.default --no-write-lock-file` |

NixOS CI の toplevel と nixvim の確認は、依存関係と設定の評価を目的に `--dry-run` で行う。
imozuru の skill source は同じ NixOS input で `nix build --no-link` を実行し、checkPhase を含む
Linux 実ビルドを確認する。

GitHub Actions の darwin CI は長時間化を避けるため、`make nix-check-all-ci` は使わず、実適用や `mise install` を伴わないビルド確認に絞る。HM は `homeConfigurations.ci` を使い、GUI アプリなどの大型 `home.packages` をビルド対象から外す。

## 13. 検証のおすすめフロー

変更を加えたら最低でも以下を実行する:

1. 影響範囲の OS で `*-check` / `*-build` を通す（apply はまだしない）
2. `make pre-commit-run` で lint と gitleaks
3. 問題なければ apply
4. 挙動が変わったら `AGENTS.md` / `docs/architecture.md` / `docs/commands.md` を同期更新

## 13. Home Kubernetes の導入・確認

以下は x86_64 NixOS 実機で実行する。`make nixos-switch` はシステム設定を変更するため、
先に `make nixos-build` を成功させ、`/mnt/sda1` と `/mnt/sdb1` がマウントされていることを
確認する。

```sh
findmnt /mnt/sda1 /mnt/sdb1
make nixos-build
make nixos-switch
systemctl status k3s k3s-storage-setup --no-pager
```

NixOS ホストだけで Kubernetes を管理するため、k3s の kubeconfig を Mac へコピーしない。

```sh
install -d -m 0700 "$HOME/.kube"
sudo install -m 0600 /etc/rancher/k3s/k3s.yaml "$HOME/.kube/config"
sudo chown "$USER":"$(id -gn)" "$HOME/.kube/config"
export KUBECONFIG="$HOME/.kube/config"
kubectl get nodes -o wide
kubectl get storageclass
```

manifest の静的検証はクラスタを変更しない。

```sh
kubectl kustomize kubernetes/clusters/home >/dev/null
git diff --check
```

Flux bootstrap、SOPS/age、Tailscale OAuth secret は外部状態と秘密情報を扱う。実行前に
[Home Kubernetes の運用](home-kubernetes.md) の順序を確認する。
実際の age 公開鍵と暗号化 OAuth Secret を Git に追加してから bootstrap し、age 秘密鍵
を含む `sops-age` は bootstrap 後に `flux-system` namespace へ一度だけ作成する。secret
の内容を表示する `kubectl` コマンドは使わない。

## 14. Jellyfin と Flux の状態確認

```sh
flux check
flux get kustomizations -A
flux get helmreleases -A
kubectl get pods -A
kubectl get ingress -n jellyfin
kubectl get ingress jellyfin -n jellyfin \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}{"\n"}'
```

最後に表示される MagicDNS FQDN を Tailscale 接続済み・ACL 許可済みの端末から HTTPS で
開く。`8096` を直接公開しない。詳細は [`kubernetes/README.md`](../kubernetes/README.md)
を参照。

## Orcaの設定

`mise run orca-bot-diff <定義名> <Botフォルダ>` で登録済みBotの公開定義との差分を確認する。登録と反映の手順は [Orcaの設定](orca.md) を参照。
