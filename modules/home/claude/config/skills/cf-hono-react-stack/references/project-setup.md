# プロジェクトセットアップ

新規作成と設定ファイル（`wrangler.jsonc`、`vite.config.ts`、TypeScript）の規約。

確認先:

- https://developers.cloudflare.com/workers/framework-guides/web-apps/more-web-frameworks/hono/
- https://developers.cloudflare.com/workers/vite-plugin/get-started/
- https://developers.cloudflare.com/workers/static-assets/routing/single-page-application/
- https://developers.cloudflare.com/workers/wrangler/configuration/
- https://developers.cloudflare.com/workers/languages/typescript/

## 新規作成

公式テンプレートから始める。手でゼロから組まない。

```sh
npm create cloudflare@latest -- my-app --template=cloudflare/templates/vite-react-template
cd my-app
npm i hono zod @hono/zod-validator drizzle-orm @tanstack/react-query
npm i -D drizzle-kit vitest @cloudflare/vitest-plugin \
  jsdom @testing-library/react @testing-library/user-event @testing-library/jest-dom
```

zod は v4 を前提にする（`z.uuid()` などトップレベルの形式関数を使う）。

テンプレートには Hono・React・`@cloudflare/vite-plugin` が入っている。D1 と DO は後から足す。

```sh
npx wrangler d1 create my-app-db   # 出力された database_id を wrangler.jsonc に書く
```

## wrangler.jsonc

設定ファイルは JSONC を使う（コメントが書け、新機能が先に JSON スキーマへ入るため）。

```jsonc
{
  "$schema": "node_modules/wrangler/config-schema.json",
  "name": "my-app",
  "main": "src/worker/index.ts",
  // 作成日の日付を入れる。2026-08-04 以降なら nodejs_compat は既定で有効
  "compatibility_date": "2026-10-04",
  "observability": { "enabled": true },
  "assets": {
    // Vite プラグインがビルド時に dist/client を指すので directory は書かない
    "not_found_handling": "single-page-application",
    // 画面遷移（Sec-Fetch-Mode: navigate）でも /api/* を Worker に通す
    "run_worker_first": ["/api/*"]
  },
  "d1_databases": [
    {
      "binding": "DB",
      "database_name": "my-app-db",
      "database_id": "<wrangler d1 create の出力>",
      "migrations_dir": "migrations"
    }
  ],
  "durable_objects": {
    "bindings": [{ "name": "ROOM", "class_name": "Room" }]
  },
  // DO クラスの宣言。新方式の exports を使う（legacy の migrations 配列とは併用できない）
  "exports": {
    "Room": { "type": "durable-object", "storage": "sqlite" }
  },
  // ログインなどのレート制限（security.md）
  "ratelimits": [
    { "name": "AUTH_LIMITER", "namespace_id": "1001", "simple": { "limit": 10, "period": 60 } }
  ]
}
```

設定の判断基準:

- `compatibility_date` はプロジェクト作成日にする。上げるときは変更履歴（https://developers.cloudflare.com/workers/configuration/compatibility-flags/）を読み、テストを通してから上げる
- 2026-08-04 より前の日付を使う既存プロジェクトでは `"compatibility_flags": ["nodejs_compat"]` が必要になる
- `run_worker_first` を書かないと、SPA 設定ではブラウザの画面遷移リクエストが Worker に届かない。API を叩く `fetch` は届くが、OAuth のコールバックのようなリダイレクト系が壊れる
- SPA のルート（`/todos` など）は Worker を通らずアセットとして返る。Worker の課金対象にならない
- 既存 Worker が `migrations` 配列で DO を宣言している場合は、そのまま使ってよい。`exports` への移行手順は https://developers.cloudflare.com/durable-objects/reference/durable-objects-migrations/ を読んでから行う

環境（staging / production）の分け方は deploy-ops.md に書く。

## vite.config.ts

```ts
import { cloudflare } from "@cloudflare/vite-plugin";
import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

export default defineConfig({
  // フレームワークのプラグインを先に、cloudflare() を後に置く
  plugins: [react(), cloudflare()],
});
```

`cloudflare()` は引数なしでルートの `wrangler.jsonc` を読む。`npm run dev` で Worker が Workers ランタイム（workerd）上で動き、D1 と DO はローカルでエミュレートされる。

package.json の scripts はテンプレートの形を保つ。

```json
{
  "scripts": {
    "dev": "vite dev",
    "build": "vite build",
    "preview": "npm run build && vite preview",
    "deploy": "npm run build && wrangler deploy",
    "cf-typegen": "wrangler types --config wrangler.jsonc",
    "db:generate": "drizzle-kit generate",
    "db:migrate:local": "wrangler d1 migrations apply DB --local --config wrangler.jsonc",
    "test": "npm run test:worker && npm run test:client",
    "test:worker": "vitest run --config vitest.config.ts",
    "test:client": "vitest run --config vitest.client.config.ts"
  }
}
```

テスト設定を Worker 用と React 用に分ける理由は testing.md に書く。

テンプレートの `deploy` スクリプトは、D1 migration と環境の選択（`CLOUDFLARE_ENV`）を含まない。D1 を使う構成ではこのスクリプトを使わず、deploy-ops.md の手順でデプロイする。

ビルドすると `dist/client/`（静的アセット）と `dist/<worker 名>/`（Worker コードと出力用 `wrangler.json`）ができる。`wrangler deploy` と `vite preview` はこの出力設定を自動で使う。そのため、ビルドせずに `wrangler deploy` すると古い成果物がデプロイされる。

ビルド後は、他の wrangler コマンド（`d1 migrations apply`、`secret put`、`types`）も出力設定を読む場合がある。出力設定は環境が平坦化されているので、`--env` が効かなかったり、別の環境の設定から型が生成されたりする。これらのコマンドには `--config wrangler.jsonc` を付けて元の設定を読ませる。

## TypeScript

### Env の生成

```sh
npx wrangler types --config wrangler.jsonc
```

- `worker-configuration.d.ts` にグローバルな `Env` 型とランタイム型が生成される
- binding や `vars` を変えたら必ず再実行する。`package.json` の `postinstall` か `cf-typegen` で回す
- 生成ファイルはコミットする。CI では `npx wrangler types --check --config wrangler.jsonc` で生成漏れを検出する
- アプリの型には `@cloudflare/workers-types` を併用しない。compatibility_date と合わない型が混ざる（共有ライブラリの型付けに使うのは問題ない）

### tsconfig の分割

テンプレートの分割（React 用 / Worker 用 / Node 用）を維持し、Worker テスト用を足す。

| ファイル | 対象 | 型の前提 |
|---|---|---|
| `tsconfig.app.json` | `src/react-app` | DOM。Worker の型は `import type` で取り込むだけ |
| `tsconfig.worker.json` | `src/worker`、`worker-configuration.d.ts` | Workers ランタイム。DOM は入れない |
| `tsconfig.node.json` | `vite.config.ts`、`drizzle.config.ts`、`vitest*.config.ts` | Node |
| `tsconfig.test.json` | `test`、`worker-configuration.d.ts` | Workers ランタイム + `@cloudflare/vitest-plugin/types`（testing.md） |

React から `AppType` を `import type` すると、Worker のファイルも型検査の対象に入る。`Env` が見つからないエラーが出たら、`tsconfig.app.json` の `include` に `worker-configuration.d.ts` を足す。DOM と Workers の型が衝突する場合は、`AppType` を export するファイルから Workers 固有の型が漏れないようにする。

## ローカル開発

- `npm run dev` で SPA と API が同じオリジン（`http://localhost:5173`）で動く。CORS 設定は要らない
- 初回と migration 追加後は `npm run db:migrate:local` を実行する
- ローカルの secrets は `.dev.vars` に書く（security.md）
- `.wrangler/` はローカル状態（D1 の SQLite など）なので `.gitignore` に入れる

## アンチパターン

- `Env` を手書きし、binding を足すたびにずれる
- `assets.directory` を Vite 構成で書く（ビルド出力と二重管理になる）
- `compatibility_date` を何年も放置する、または毎回最新日付に機械的に上げる
- `wrangler dev` と `vite dev` を混在させる。このスタックでは `vite dev` に統一する
