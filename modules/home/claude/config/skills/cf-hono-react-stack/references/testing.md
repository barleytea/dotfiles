# テスト

Worker（Hono・D1・DO）は Workers ランタイムで、React は jsdom で、それぞれ別の Vitest 設定でテストする。

確認先:

- https://developers.cloudflare.com/workers/testing/vitest-integration/configuration/
- https://developers.cloudflare.com/workers/testing/vitest-integration/test-apis/
- https://developers.cloudflare.com/workers/testing/vitest-integration/isolation-and-concurrency/
- https://developers.cloudflare.com/workers/testing/vitest-integration/migration-guides/migrate-to-vitest-plugin/
- https://hono.dev/docs/helpers/testing

2026-10 時点で、Workers のテスト統合は `@cloudflare/vitest-plugin`（Vitest 4.1 以上）になっている。古い記事にある `@cloudflare/vitest-pool-workers` や `defineWorkersConfig` は旧方式である。既存プロジェクトは `npx @cloudflare/codemods vitest:pool-workers-to-vitest-plugin` で移行する。

## 設定ファイルを分ける

Workers のテスト統合はカスタムの Vitest `environment` を使えないので、React（jsdom）とは設定を分ける。

| 設定 | 対象 | 実行環境 |
|---|---|---|
| `vitest.config.ts` | `test/**/*.test.ts`（Worker） | workerd（`cloudflareTest()`） |
| `vitest.client.config.ts` | `src/react-app/**/*.test.tsx` | jsdom |

```json
{
  "scripts": {
    "test": "npm run test:worker && npm run test:client",
    "test:worker": "vitest run --config vitest.config.ts",
    "test:client": "vitest run --config vitest.client.config.ts"
  }
}
```

## Worker 側の設定

```ts
// vitest.config.ts
import path from "node:path";
import { cloudflareTest, readD1Migrations } from "@cloudflare/vitest-plugin";
import { defineConfig } from "vitest/config";

export default defineConfig({
  plugins: [
    cloudflareTest(async () => {
      // 本番と同じ migration をテスト用 D1 に当てる
      const migrations = await readD1Migrations(path.join(__dirname, "migrations"));
      return {
        wrangler: { configPath: "./wrangler.jsonc" },
        miniflare: { bindings: { TEST_MIGRATIONS: migrations } },
      };
    }),
  ],
  test: {
    include: ["test/**/*.test.ts"],
    setupFiles: ["./test/apply-migrations.ts"],
  },
});
```

```ts
// test/apply-migrations.ts
import { applyD1Migrations } from "cloudflare:test";
import { env } from "cloudflare:workers";

await applyD1Migrations(env.DB, env.TEST_MIGRATIONS);
```

```ts
// test/env.d.ts
declare module "cloudflare:workers" {
  interface ProvidedEnv extends Env {
    TEST_MIGRATIONS: D1Migration[];
  }
}
```

- テスト用の `tsconfig.test.json`（`include`: `test`、`worker-configuration.d.ts`）を作り、`types` に `@cloudflare/vitest-plugin/types` を入れる。ルートの `tsconfig.json` の `references` に足して、`tsc -b` で型検査されるようにする
- `ProvidedEnv` を宣言するモジュール名（`cloudflare:workers` か `cloudflare:test` か）は、移行ガイドの最新例に合わせる
- `readD1Migrations` の import 元（メインエントリか `/config` サブパスか）は docs の表記が揺れている。型エラーが出たら docs の最新例に合わせる
- `wrangler.jsonc` の `assets` に `directory` を書いていない（Vite が補う）ため、テストの起動時に assets の設定でエラーが出ることがある。出た場合は `miniflare` オプションで上書きするか、テスト用の wrangler 設定を分ける
- drizzle-kit がサブディレクトリ形式（`migrations/<name>/migration.sql`）で出力する場合、`readD1Migrations` がトップレベルの `.sql` しか読まないことがある。その場合は自前で読み込む

```ts
// vitest.config.ts 内で readD1Migrations の代わりに使う
import fs from "node:fs/promises";

async function readDrizzleMigrations(dir: string) {
  const names = (await fs.readdir(dir, { withFileTypes: true }))
    .filter((d) => d.isDirectory())
    .map((d) => d.name)
    .sort();
  return Promise.all(
    names.map(async (name) => {
      const sqlText = await fs.readFile(path.join(dir, name, "migration.sql"), "utf8");
      // drizzle-kit は文の区切りに "--> statement-breakpoint" を入れる。1 文ずつ実行させる
      const queries = sqlText.split("--> statement-breakpoint").map((q) => q.trim()).filter(Boolean);
      return { name, queries };
    }),
  );
}
```

- ストレージはテストファイル単位で分離される。同じファイル内のテストは状態を共有するので、各テストで自分のデータを作り、他のテストの結果に依存しない

## API のテスト（Hono）

Hono の `app.request()` に `env` を渡して呼ぶ。Workers ランタイム上で動くので、D1 と DO は本物のローカル実装が使われる。

```ts
// test/todos.test.ts
import { env } from "cloudflare:workers";
import { describe, expect, it } from "vitest";
import app from "../src/worker";
import { createTestSession } from "./helpers";

describe("POST /api/todos", () => {
  it("作成した Todo を 201 で返す", async () => {
    const cookie = await createTestSession(env);
    const res = await app.request(
      "/api/todos",
      {
        method: "POST",
        headers: { "Content-Type": "application/json", Cookie: cookie },
        body: JSON.stringify({ title: "牛乳を買う" }),
      },
      env,
    );
    expect(res.status).toBe(201);
    expect(await res.json()).toMatchObject({ title: "牛乳を買う", done: false });
  });

  it("空のタイトルは 400 を返す", async () => {
    const cookie = await createTestSession(env);
    const res = await app.request(
      "/api/todos",
      {
        method: "POST",
        headers: { "Content-Type": "application/json", Cookie: cookie },
        body: JSON.stringify({ title: "" }),
      },
      env,
    );
    expect(res.status).toBe(400);
  });
});
```

- `createTestSession` は D1 にユーザーとセッションを直接作り、Cookie ヘッダーの文字列を返すヘルパーにする（security.md のセッション設計に合わせる）
- 型付きで呼びたい場合は `hono/testing` の `testClient(app, env)` を使う。env を渡す引数の形は https://hono.dev/docs/helpers/testing で確かめる
- `c.executionCtx.waitUntil` を使うルートは、ExecutionContext を第 4 引数に渡し、後処理の完了を待ってから検証する

```ts
import { createExecutionContext, waitOnExecutionContext } from "cloudflare:test";

// init は上の例と同じリクエスト設定（method、headers、body）
const ctx = createExecutionContext();
const res = await app.request("/api/todos", init, env, ctx); // ctx を渡さないと c.executionCtx が例外になる
await waitOnExecutionContext(ctx);
```

- Worker 全体（アセット配信の経路を含む）を通したい場合は、`cloudflare:workers` の `exports.default.fetch()` を使う

## Durable Object のテスト

```ts
// test/room.test.ts
import { runDurableObjectAlarm, runInDurableObject } from "cloudflare:test";
import { env } from "cloudflare:workers";
import { expect, it } from "vitest";
import type { Room } from "../src/worker/do/room";

it("post したメッセージが list で取れる", async () => {
  const roomId = crypto.randomUUID();
  const stub = env.ROOM.getByName(`room:${roomId}`);
  await stub.post(roomId, "user-1", "こんにちは");
  const messages = await stub.list();
  expect(messages[0]).toMatchObject({ userId: "user-1", text: "こんにちは" });
});

it("alarm で最終発言時刻が D1 に投影され、outbox が空になる", async () => {
  const roomId = crypto.randomUUID();
  await env.DB.prepare("INSERT INTO rooms (id, name) VALUES (?, ?)").bind(roomId, "test").run();
  const stub = env.ROOM.getByName(`room:${roomId}`);
  await stub.post(roomId, "user-1", "a");

  // alarm を待たずに即時実行する
  expect(await runDurableObjectAlarm(stub)).toBe(true);

  const row = await env.DB.prepare("SELECT last_message_at FROM rooms WHERE id = ?").bind(roomId).first();
  expect(row?.last_message_at).not.toBeNull();
  await runInDurableObject(stub, async (_instance: Room, state) => {
    const { n } = state.storage.sql.exec<{ n: number }>("SELECT COUNT(*) AS n FROM outbox").one();
    expect(n).toBe(0);
  });
});
```

- 通常は RPC（`stub.post()`）経由で振る舞いをテストする。`runInDurableObject` は内部状態の確認が必要なときだけ使う
- alarm は `runDurableObjectAlarm(stub)` で即時に実行させる。D1 への投影（durable-objects.md）はこの方法でテストする
- DO 名はテストごとに一意（UUID）にし、本番と同じ `room:<uuid>` の形式を使う
- ルームのアクセス制御（非メンバーが 404 になること）は、DO 単体ではなく API のテストで確かめる
- DO クラスを同じ Worker で定義しているので、`main` は `wrangler.jsonc` から読まれる。別の場所を使う場合は `cloudflareTest({ main })` を指定する

## React 側の設定

```ts
// vitest.client.config.ts
import react from "@vitejs/plugin-react";
import { defineConfig } from "vitest/config";

export default defineConfig({
  plugins: [react()],
  test: {
    environment: "jsdom",
    include: ["src/react-app/**/*.test.{ts,tsx}"],
    setupFiles: ["./src/react-app/test/setup.ts"], // @testing-library/jest-dom の読み込み
  },
});
```

- コンポーネントは `@testing-library/react` で、ユーザーの操作（`@testing-library/user-event`）を通して振る舞いを確かめる
- API は MSW などでモックするか、`lib/api.ts` を差し替える。どちらにするかはプロジェクトで 1 つに決める
- テストごとに新しい `QueryClient`（`retry: false`）を作る

## TDD の進め方

1. 失敗する Worker テストを書く（ステータスコードとレスポンスの形）
2. スキーマ変更が要るなら migration を生成し、テストで当たることを確かめる
3. ルートを実装してテストを通す
4. React の hooks / コンポーネントのテストを書き、実装する

## アンチパターン

- リモートの D1 や本番 Worker に向けてテストを実行する
- テスト間でデータを共有し、実行順に依存する
- Node 環境（`environment: "node"`）で Worker コードをテストする（ランタイムの差でテストが通っても本番で落ちる）
- 古い `@cloudflare/vitest-pool-workers` の記事をそのまま写す
