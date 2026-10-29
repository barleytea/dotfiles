# デプロイと運用

環境分け、手動デプロイ、CI デプロイ（GitHub Actions / Workers Builds）、ロールバック、監視の規約。

確認先:

- https://developers.cloudflare.com/workers/vite-plugin/reference/cloudflare-environments/
- https://developers.cloudflare.com/workers/wrangler/environments/
- https://developers.cloudflare.com/workers/ci-cd/external-cicd/github-actions/
- https://developers.cloudflare.com/workers/ci-cd/builds/configuration/
- https://developers.cloudflare.com/workers/configuration/versions-and-deployments/
- https://developers.cloudflare.com/workers/configuration/previews/
- https://developers.cloudflare.com/d1/reference/time-travel/
- https://developers.cloudflare.com/durable-objects/reference/durable-objects-migrations/

## 共通の前提

### 環境の分け方

`wrangler.jsonc` のトップレベルを production、`env.staging` を staging にする。

```jsonc
{
  "name": "my-app",
  // ...トップレベル = production（project-setup.md の設定）
  "env": {
    "staging": {
      // Worker 名は自動で "my-app-staging" になる
      // binding は環境間で継承されないので、すべて書き直す
      "d1_databases": [
        {
          "binding": "DB",
          "database_name": "my-app-db-staging",
          "database_id": "<staging 用の database_id>",
          "migrations_dir": "migrations"
        }
      ],
      "durable_objects": {
        "bindings": [{ "name": "ROOM", "class_name": "Room" }]
      },
      "ratelimits": [
        { "name": "AUTH_LIMITER", "namespace_id": "2001", "simple": { "limit": 10, "period": 60 } }
      ],
      "vars": { "APP_ENV": "staging" }
    }
  }
}
```

- 継承されるキー: `main`・`compatibility_date`・`compatibility_flags`・`assets`・`observability`・`exports` など。staging に書かなくてよい
- 継承されないキー: `vars` と、`d1_databases`・`durable_objects`・`ratelimits`・`kv_namespaces` などの binding。すべて書き直す
- 継承の一覧は https://developers.cloudflare.com/workers/wrangler/configuration/ の Inheritable keys / Non-inheritable keys で確かめる
- `namespace_id`（rate limit）はアカウント内で一意にするので、production と staging で別の値にする
- 環境を足したら `npx wrangler types --config wrangler.jsonc` を再実行する

### Vite 構成での環境の選び方

`@cloudflare/vite-plugin` を使う構成では、環境は**ビルド時**に `CLOUDFLARE_ENV` で選ぶ。`wrangler deploy --env` は使わない。

```sh
CLOUDFLARE_ENV=staging npm run build   # dist/ に staging 用の設定が焼き込まれる
npx wrangler deploy                    # ビルド出力の設定を読んでデプロイする
```

`CLOUDFLARE_ENV` を付けずにビルドすると production 用になる。

### デプロイの順序

順序は「テスト → ビルド → D1 migration → Worker デプロイ」に固定する。

- migration を先に当てるので、**旧コードが新スキーマで動いても壊れない**ようにする（前方互換）
- カラムの削除・リネームのような破壊的変更は 2 回のデプロイに分ける
  1. expand: 新カラムを追加し、コードは新旧どちらでも動くようにする
  2. contract: 旧カラムを参照するコードが消えたあとで、旧カラムを削除する migration を出す
- `wrangler rollback` で戻るのはコードだけで、D1 のスキーマとデータは戻らない。前方互換にしておけば、コードのロールバックだけで済む

D1 の migration は、ビルド出力ではなく元の設定ファイルを明示して当てる。

```sh
npx wrangler d1 migrations apply DB --remote --env staging --config wrangler.jsonc
```

ビルド後の wrangler コマンドは出力設定（環境が平坦化された設定）を自動で読む場合がある。`--config wrangler.jsonc` を付けて元の設定を読ませ、`--env` を効かせる。ビルドを先にするのは、ビルドに失敗したときに migration だけが当たった状態を作らないためである。

### Durable Object クラスの変更

- クラスの追加は `exports` にエントリを足してデプロイする
- 削除・リネームは `exports` の状態（`deleted` / `renamed`）で宣言してからデプロイする。コードからクラスを消すだけにしない（データを失う）
- DO クラスの変更は `wrangler deploy` でだけ反映される。`wrangler versions upload` では反映されない
- 旧方式の `migrations` 配列を使う既存 Worker では、既存の tag を書き換えず、新しい tag を追記する

### Secrets

- アプリの secrets は環境ごとに `npx wrangler secret put <KEY> --env staging --config wrangler.jsonc` で登録する。CI で毎回入れ直す必要はない
- CI から secrets を同期したい場合は、`wrangler secret bulk` の現行仕様を `wrangler` スキルで確かめてから使う

## 手動デプロイ

個人開発、初回構築、緊急対応で使う。チーム開発の通常のデプロイは CI に任せ、同じ環境に手動デプロイと CI デプロイを混ぜない。

### 初回構築

```sh
npx wrangler login                          # ブラウザで OAuth。共有端末では使わない
npx wrangler d1 create my-app-db            # production
npx wrangler d1 create my-app-db-staging    # staging
# 出力された database_id を wrangler.jsonc のトップレベルと env.staging に書く
npx wrangler types --config wrangler.jsonc
```

secrets を環境ごとに登録する（上記）。

### 通常のデプロイ

```sh
npm test

# staging
CLOUDFLARE_ENV=staging npm run build
npx wrangler d1 migrations apply DB --remote --env staging --config wrangler.jsonc
npx wrangler deploy

# staging で動作確認してから production
npm run build
npx wrangler d1 migrations apply DB --remote --config wrangler.jsonc
npx wrangler deploy
```

### 段階的なリリース

影響の大きい変更は、新しいバージョンをアップロードしてから割合を指定して切り替える。

```sh
npm run build
npx wrangler d1 migrations apply DB --remote --config wrangler.jsonc   # スキーマは前方互換にしておく
npx wrangler versions upload --message "add rooms"   # まだトラフィックは流れない
npx wrangler versions deploy                         # 対話的に新旧バージョンの割合を選ぶ
npx wrangler rollback                                # 問題が出たら直前のバージョンに戻す
```

- 段階リリース中は新旧のコードが同時に動く。スキーマと API の互換性を保つ
- DO クラスの変更を含むデプロイは段階リリースにできない（`versions upload` で反映されないため）

## CI デプロイ（GitHub Actions）

チーム開発の標準にする。テストを通らないコードがデプロイされない、承認を挟める、履歴が残る、の 3 点が手動より優れる。

### 流れ

| トリガー | ジョブ |
|---|---|
| Pull Request | 型生成チェック、型検査、テスト |
| `main` への push | テスト → staging へデプロイ |
| staging 成功後 | GitHub Environments の承認 → production へデプロイ |

### 認証情報

- Cloudflare ダッシュボードの Account API tokens で、「Edit Cloudflare Workers」をもとにトークンを作る
  - 対象アカウントを 1 つに絞る
  - D1 の migration を当てるので、テンプレートに D1 の Edit 権限が含まれていなければ足す
  - IP 制限と有効期限を付けられるなら付ける
  - staging と production で別のトークンを発行する。片方が漏れても、もう片方の環境は守れる
- `CLOUDFLARE_API_TOKEN` と `CLOUDFLARE_ACCOUNT_ID` は GitHub の **Environment secrets**（staging / production）に置く。リポジトリにも `wrangler.jsonc` にも書かない
- Global API Key は使わない
- production の Environment には Required reviewers を設定する

### ワークフロー

```yaml
# .github/workflows/deploy.yml
name: ci-deploy

on:
  pull_request:
  push:
    branches: [main]

permissions:
  contents: read

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      # Actions はタグではなくコミット SHA で固定し、Renovate などで更新する
      - uses: actions/checkout@<sha> # v6
      - uses: actions/setup-node@<sha> # 最新メジャー
        with:
          node-version-file: .node-version
          cache: npm
      - run: npm ci
      - run: npx wrangler types --check --config wrangler.jsonc
      - run: npx tsc -b
      - run: npm test

  deploy-staging:
    needs: test
    if: github.event_name == 'push'
    runs-on: ubuntu-latest
    environment: staging
    # 同じ環境へのデプロイと migration を並列に走らせない
    concurrency:
      group: deploy-staging
      cancel-in-progress: false
    env:
      CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
      CLOUDFLARE_ACCOUNT_ID: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
    steps:
      - uses: actions/checkout@<sha> # v6
      - uses: actions/setup-node@<sha>
        with:
          node-version-file: .node-version
          cache: npm
      - run: npm ci
      # ビルドが失敗したら migration を当てない
      - run: npm run build
        env:
          CLOUDFLARE_ENV: staging
      - run: npx wrangler d1 migrations apply DB --remote --env staging --config wrangler.jsonc
      - run: npx wrangler deploy

  deploy-production:
    needs: deploy-staging
    runs-on: ubuntu-latest
    environment: production # Required reviewers の承認待ちになる
    concurrency:
      group: deploy-production
      cancel-in-progress: false
    env:
      CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
      CLOUDFLARE_ACCOUNT_ID: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
    steps:
      - uses: actions/checkout@<sha> # v6
      - uses: actions/setup-node@<sha>
        with:
          node-version-file: .node-version
          cache: npm
      - run: npm ci
      - run: npm run build
      - run: npx wrangler d1 migrations apply DB --remote --config wrangler.jsonc
      - run: npx wrangler deploy
```

設計上の判断:

- wrangler は `npx wrangler` で呼び、バージョンは `package-lock.json` で固定する。手元と CI で同じバージョンになる
- 公式の `cloudflare/wrangler-action`（2026-10 時点で v4）を使ってもよい。その場合も build → migration → deploy の順を `preCommands` や複数ステップで守り、`wranglerVersion` を固定する
- `<sha>` は実装時に各 Action の最新リリースのコミット SHA に置き換える。タグ（`@v6`）のままにしない

```sh
tag=$(gh api repos/actions/checkout/releases/latest --jq .tag_name)
gh api "repos/actions/checkout/commits/$tag" --jq .sha   # actions/checkout@<この SHA> # <tag>
```

- `cancel-in-progress: false` にする。migration の途中でジョブを止めない
- fork からの Pull Request には secrets が渡らないので、デプロイ系のジョブは `push` でだけ動かす

### PR ごとのプレビュー（必要になってから）

- `npx wrangler versions upload --preview-alias pr-<番号>` で、トラフィックを流さずに確認用 URL を作れる。新しい `wrangler preview` コマンドもある。違いは https://developers.cloudflare.com/workers/configuration/previews/ で確かめる
- プレビューは staging の D1 を共有する。migration を含む PR のプレビューは、スキーマが合わず壊れることがある
- DO クラスの変更はプレビューに反映されない

## CI デプロイ（Workers Builds）

Cloudflare 側の Git 連携 CI。GitHub Actions を書かずに済む。

- ダッシュボードで Worker とリポジトリを接続し、Build command / Deploy command / ビルド変数を設定する
- Deploy command は変えられるので、migration を前に挟む

```sh
npx wrangler d1 migrations apply DB --remote --config wrangler.jsonc && npx wrangler deploy
```

- staging 用の Worker では、ビルド変数に `CLOUDFLARE_ENV=staging` を設定し、migration のコマンドに `--env staging` を付ける
- ダッシュボード上の Worker 名と `wrangler.jsonc` の `name`（環境なら `my-app-staging`）が一致しないとビルドが失敗する

選び方:

| 条件 | 選択 |
|---|---|
| 個人開発・小規模で、テストと承認のゲートが要らない | Workers Builds |
| テスト必須、production 前の承認、他のチェック（lint、型生成）と統合したい | GitHub Actions |

## 運用

### 監視とログ

- `observability.enabled: true` で Workers Logs が有効になる。トラフィックが多い場合は `head_sampling_rate` で間引く
- リアルタイムのログは `npx wrangler tail <Worker 名>` で見る。Worker 名はビルド出力の `dist/<worker>/wrangler.json` の `name` で確かめる（staging は通常 `my-app-staging`）
- `console.log` には構造化した JSON を出す。ダッシュボードでフィールド検索できる
- ログにトークン、Cookie、個人情報を出さない

### D1 の復旧

- D1 は Time Travel で直近 30 日（無料プランは 7 日）の任意の時点に戻せる
- 危険な migration の前に、現在の bookmark を控える

```sh
npx wrangler d1 time-travel info my-app-db --config wrangler.jsonc   # 現在の bookmark を確認
npx wrangler d1 time-travel restore my-app-db --timestamp=<UNIX 時刻 or RFC3339> --config wrangler.jsonc
```

- restore は DB 全体を戻す。戻した時点以降の書き込みは失われる。restore の出力にある bookmark を使えば元に戻せる
- 長期保存のバックアップが要る場合は `npx wrangler d1 export` を定期実行し、R2 に置く
- `time-travel` と `export` にも `--config wrangler.jsonc` を付ける（ビルド後の出力設定を読ませない）

### ロールバックの判断

| 問題 | 対処 |
|---|---|
| コードのバグ（スキーマは前方互換） | `npx wrangler rollback` |
| migration でデータが壊れた | Time Travel で D1 を戻し、コードもロールバックする |
| DO クラスの変更で問題が出た | `exports` を修正して再デプロイする（rollback では DO の宣言が戻らない場合がある。docs で確かめる） |

## アンチパターン

- 環境ごとの binding を書き忘れ、staging が production の D1 を触る
- Worker をデプロイしてから migration を当てる
- 破壊的な migration を 1 回のデプロイで出す
- Vite 構成で `wrangler deploy --env staging` を使う（ビルド済みの設定が使われ、意図した環境にならない）
- ローカルから手動で production にデプロイし、CI のデプロイと履歴が食い違う
- アカウント全体に権限がある API トークンや Global API Key を CI に置く
- 既存の DO クラスをコードから消すだけで削除する
