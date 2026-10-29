# Hono API

Worker 側の API 設計規約。RPC の型共有が壊れない書き方が最優先になる。

確認先:

- https://hono.dev/docs/guides/rpc
- https://hono.dev/docs/guides/validation
- https://hono.dev/docs/guides/best-practices
- https://hono.dev/docs/helpers/factory
- https://hono.dev/docs/getting-started/cloudflare-workers

## 型の土台

`Env` は `wrangler types` が生成するグローバル型を使う。リクエスト単位の値は `Variables` に置く。

```ts
// src/worker/env.ts
import type { DrizzleD1Database } from "drizzle-orm/d1";
import type * as schema from "./db/schema";

export type AppEnv = {
  Bindings: Env;
  Variables: {
    db: DrizzleD1Database<typeof schema>;
    userId: string; // 認証ミドルウェアが設定する（security.md）
    roomId: string; // requireRoomMember が設定する（durable-objects.md）
  };
};
```

```ts
// src/worker/middleware/db.ts
import { drizzle } from "drizzle-orm/d1";
import { createMiddleware } from "hono/factory";
import * as schema from "../db/schema";
import type { AppEnv } from "../env";

// リクエストごとに生成する。モジュールスコープでキャッシュしない
export const withDb = createMiddleware<AppEnv>(async (c, next) => {
  c.set("db", drizzle(c.env.DB, { schema }));
  await next();
});
```

## エントリポイント

```ts
// src/worker/index.ts
import { Hono } from "hono";
import { csrf } from "hono/csrf";
import { HTTPException } from "hono/http-exception";
import { logger } from "hono/logger";
import { secureHeaders } from "hono/secure-headers";
import type { AppEnv } from "./env";
import { withDb } from "./middleware/db";
import { authRoute } from "./routes/auth";
import { roomsRoute } from "./routes/rooms";
import { todosRoute } from "./routes/todos";

const app = new Hono<AppEnv>().basePath("/api");

// 全ルート共通のミドルウェア。認証はサブアプリ側で掛ける
app.use(logger(), secureHeaders(), csrf(), withDb);

app.onError((err, c) => {
  // エラー応答はすべて { error } の JSON にそろえる
  if (err instanceof HTTPException) return c.json({ error: err.message }, err.status);
  // 内部情報はログにだけ出し、クライアントには返さない
  console.error(err);
  return c.json({ error: "internal_error" }, 500);
});

app.notFound((c) => c.json({ error: "not_found" }, 404));

// route() をチェーンした戻り値の型が AppType になる
const routes = app
  .route("/auth", authRoute) // 公開ルート（ログイン・ログアウト）
  .route("/todos", todosRoute)
  .route("/rooms", roomsRoute);

export type AppType = typeof routes;
export default app;
export { Room } from "./do/room";
```

- `basePath("/api")` は `wrangler.jsonc` の `run_worker_first: ["/api/*"]` と対応させる
- DO クラスはエントリポイントから named export する。export しないとデプロイが失敗する
- 認証は保護したいサブアプリの先頭で `.use(requireSession)` する。全体に掛けるとログイン API まで保護されるため、全体には掛けない
- `secureHeaders()` は `next()` の後でレスポンスヘッダーを書き換える。DO から返した WebSocket の 101 応答を書き換えられずに失敗する場合は、durable-objects.md の中継例のように応答を作り直す

## ルート定義（サブアプリ）

機能ごとに `new Hono<AppEnv>()` を作り、メソッドチェーンで定義する。

```ts
// src/worker/routes/todos.ts
import { zValidator } from "@hono/zod-validator";
import { and, desc, eq, lt } from "drizzle-orm";
import { Hono } from "hono";
import { z } from "zod";
import { todos } from "../db/schema";
import type { AppEnv } from "../env";
import { requireSession } from "../middleware/session";

const listQuery = z.object({
  cursor: z.coerce.number().int().positive().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});
const createBody = z.object({ title: z.string().trim().min(1).max(200) });
const idParam = z.object({ id: z.coerce.number().int().positive() });

export const todosRoute = new Hono<AppEnv>()
  .use(requireSession) // 以降のルートはログイン必須
  .get("/", zValidator("query", listQuery), async (c) => {
    const { cursor, limit } = c.req.valid("query");
    const items = await c.var.db
      .select()
      .from(todos)
      .where(and(eq(todos.userId, c.var.userId), cursor ? lt(todos.id, cursor) : undefined))
      .orderBy(desc(todos.id))
      .limit(limit);
    return c.json({ items, nextCursor: items.length === limit ? items.at(-1)?.id : undefined });
  })
  .post("/", zValidator("json", createBody), async (c) => {
    const { title } = c.req.valid("json");
    const [item] = await c.var.db
      .insert(todos)
      .values({ title, userId: c.var.userId })
      .returning();
    return c.json(item, 201);
  })
  .delete("/:id", zValidator("param", idParam), async (c) => {
    const { id } = c.req.valid("param");
    const deleted = await c.var.db
      .delete(todos)
      .where(and(eq(todos.id, id), eq(todos.userId, c.var.userId)))
      .returning({ id: todos.id });
    // 想定内のエラーは c.json で返すと、クライアントの型に 404 が載る
    if (deleted.length === 0) return c.json({ error: "not_found" }, 404);
    return c.body(null, 204);
  });
```

規約:

- `.get().post()` のようにチェーンする。`const r = new Hono(); r.get(...); r.post(...)` と文を分けると、`typeof r` にルートが載らない
- ハンドラをチェーンの外に切り出すと型推論が切れる。切り出すときは `createFactory<AppEnv>().createHandlers(...)` を使う
- `c.json(data, status)` のステータスを明示する。`hc` 側で `res.status` による型の絞り込みが効く
- 想定内のエラー（404、409、422）は `c.json({ error }, status)` で返す。`HTTPException` は認証失敗のような横断的な中断に使う
- 所有者チェック（`userId` 条件）をクエリの `where` に含める。取得後に比較すると漏れやすい

## バリデーション

- `zValidator(target, schema)` で `json` / `query` / `param` / `header` / `cookie` / `form` を検証する
- query と param は文字列で届くので `z.coerce` を使う
- 失敗時のレスポンス形式をそろえたい場合は第 3 引数の hook で返す。

```ts
zValidator("json", createBody, (result, c) => {
  if (!result.success) {
    return c.json({ error: "invalid_request", issues: result.error.issues }, 400);
  }
});
```

- zod スキーマを Worker とクライアントで共有したい場合は `src/shared/` に置き、両方の tsconfig から参照する。共有するのはスキーマと型だけにする

## 非同期処理とリクエスト状態

- レスポンス後に続けたい処理（監査ログ、D1 への投影、キャッシュ更新）は `c.executionCtx.waitUntil(promise)` に渡す
- `await` も `waitUntil` もしない Promise を作らない（floating promise）。レスポンス後に打ち切られる
- リクエストに紐づく値（ユーザー、DB クライアント）は `c.set` / `c.var` で受け渡す。モジュールスコープの変数は同じ isolate の別リクエストと共有される
- Workers 全般の注意点（ストリーミング、グローバル状態、サブリクエスト上限）は `workers-best-practices` スキルで確認する

## アンチパターン

- チェーンせずにルートを登録し、`hc` の型が `unknown` になる
- 1 ファイルに全ルートを書く。機能単位のサブアプリに分けて `route()` でつなぐ
- `c.req.json()` を検証なしで使う
- エラー時に `err.message` やスタックをそのまま返す
- `cors()` を同一オリジン構成で付ける（不要。別オリジンが必要な場合は security.md）
