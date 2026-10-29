# D1 + Drizzle ORM

スキーマ、migration、クエリの規約。

確認先:

- https://orm.drizzle.team/docs/connect-cloudflare-d1
- https://orm.drizzle.team/docs/get-started/d1-new
- https://orm.drizzle.team/docs/batch-api
- https://developers.cloudflare.com/d1/reference/migrations/
- https://developers.cloudflare.com/d1/worker-api/d1-database/
- https://developers.cloudflare.com/d1/platform/limits/
- https://developers.cloudflare.com/d1/best-practices/read-replication/

## スキーマ

```ts
// src/worker/db/schema.ts
import { sql } from "drizzle-orm";
import { index, integer, sqliteTable, text } from "drizzle-orm/sqlite-core";

const createdAt = () =>
  integer("created_at", { mode: "timestamp_ms" })
    .notNull()
    .default(sql`(unixepoch() * 1000)`);

export const users = sqliteTable("users", {
  id: text("id").primaryKey(), // crypto.randomUUID()
  email: text("email").notNull().unique(),
  createdAt: createdAt(),
});

export const todos = sqliteTable(
  "todos",
  {
    id: integer("id").primaryKey({ autoIncrement: true }),
    userId: text("user_id")
      .notNull()
      .references(() => users.id, { onDelete: "cascade" }),
    title: text("title").notNull(),
    done: integer("done", { mode: "boolean" }).notNull().default(false),
    createdAt: createdAt(),
  },
  // 一覧クエリ（user_id で絞り id 降順）に合わせた複合インデックス
  (t) => [index("todos_user_id_id_idx").on(t.userId, t.id)],
);

export type Todo = typeof todos.$inferSelect;
```

規約:

- カラム名は snake_case を明示する（`text("user_id")`）。TypeScript 側は camelCase
- 日時は `integer` + `timestamp_ms` で保存する。SQLite に日時型はない
- 外部に見せる ID は推測されにくい値（UUID）にする。連番を URL に出す場合は所有者チェックを必ず行う
- `WHERE` と `ORDER BY` に使う列の組み合わせでインデックスを張る。D1 は読んだ行数で課金されるので、インデックスはコストにも効く

## Drizzle クライアント

```ts
import { drizzle } from "drizzle-orm/d1";
import * as schema from "./db/schema";

const db = drizzle(c.env.DB, { schema });
```

hono-api.md の `withDb` ミドルウェアでリクエストごとに作り、`c.var.db` で使う。

## Migration

```ts
// drizzle.config.ts
import { defineConfig } from "drizzle-kit";

export default defineConfig({
  dialect: "sqlite",
  schema: "./src/worker/db/schema.ts",
  out: "./migrations", // wrangler.jsonc の migrations_dir と一致させる
});
```

手順:

1. `schema.ts` を変更する
2. `npx drizzle-kit generate --name <変更内容>` で SQL を生成する
3. 生成された SQL を読んでレビューする（テーブル再作成やデータ消失がないか）
4. `npm run db:migrate:local`（`wrangler d1 migrations apply DB --local --config wrangler.jsonc`）でローカルに当てる
5. テストを通す（テストも同じ migration を当てる。testing.md）
6. リモートへの適用はデプロイ手順の一部として行う（deploy-ops.md）

注意点:

- drizzle-kit が migration をサブディレクトリ（`migrations/0001_init/migration.sql`）で出力する場合は、`d1_databases` に `"migrations_pattern": "migrations/*/migration.sql"` を足す。初回の generate 後に出力形式を確かめる
- migration の適用と履歴管理は wrangler（`d1_migrations` テーブル）に任せる。`drizzle-kit migrate` / `push` と混在させない
- `drizzle-kit push` はリモートに使わない。レビューできる SQL を残せないため
- 適用済みの migration ファイルを編集しない。修正は新しい migration で行う
- SQLite の `ALTER TABLE` は制約変更ができず、drizzle-kit はテーブル再作成の SQL を出すことがある。外部キーがある場合は D1 の `PRAGMA defer_foreign_keys` の扱いを https://developers.cloudflare.com/d1/sql-api/foreign-keys/ で確かめる
- 破壊的変更（カラム削除・リネーム）は expand → contract の 2 回に分ける（deploy-ops.md）

## クエリ

### 原子性は batch で

D1 は Worker から `BEGIN TRANSACTION` を使った対話的トランザクションを前提にできない。複数の書き込みは `batch` にまとめる。batch は 1 つのトランザクションとして実行され、どれかが失敗すると全体がロールバックされる。

```ts
// 例: サインアップ時にユーザーと初期 Todo を同時に作る。片方だけ残る状態を作らない
const userId = crypto.randomUUID();
await db.batch([
  db.insert(users).values({ id: userId, email }),
  db.insert(todos).values({ userId, title: "最初のタスク" }),
]);
```

- batch の中で前の文の結果を使った分岐はできない。分岐が要る場合は条件を SQL 側（`WHERE` 句、`INSERT ... SELECT`、`ON CONFLICT`）に寄せる
- それでも足りない「読んでから条件付きで書く」処理は、該当エンティティを Durable Object に移すことを検討する（durable-objects.md）
- Drizzle の `db.batch()` の D1 対応状況と戻り値の型は https://orm.drizzle.team/docs/batch-api で確かめる。使えない場合は `c.env.DB.batch()` に prepared statement を渡す

### N+1 を避ける

```ts
// 悪い例: 件数ぶんクエリが走る
for (const t of list) t.tags = await db.select().from(tags).where(eq(tags.todoId, t.id));

// 良い例: まとめて取り、メモリで組み立てる
const rows = await db.select().from(tags).where(inArray(tags.todoId, list.map((t) => t.id)));
```

- `db.query.todos.findMany({ with: { tags: true } })`（relational query）は 1 本の SQL になる。relations の定義が必要
- 1 回の Worker 実行あたりのクエリ数には上限がある（有料プランで 1000）

### 上限に合わせた書き方

| 制限（2026-10 時点の有料プラン） | 対策 |
|---|---|
| 1 クエリのバインド変数は 100 個まで | 一括 INSERT は「列数 × 行数 ≤ 100」になるよう分割して batch に入れる。`inArray` に大きな配列を渡さない |
| 1 行・BLOB は 2MB まで | 大きなファイルは R2 に置き、D1 にはキーだけ保存する |
| 1 DB は 10GB まで | テナント単位で DB を分ける設計は、必要になってから検討する |
| クエリは 30 秒まで | 重い集計は事前集計テーブルか Queues + Cron に逃がす |

正確な値は https://developers.cloudflare.com/d1/platform/limits/ で確かめる。

### SQL インジェクション

- Drizzle のクエリビルダと `sql` テンプレート（`` sql`... ${value}` ``）は値をプレースホルダにする
- `sql.raw()` と文字列連結に入力を渡さない。並び順のように列名を動的にしたい場合は、許可リスト（`{ createdAt: todos.createdAt }`）から選ぶ
- 生の D1 API を使う場合も `prepare("... WHERE id = ?").bind(id)` を使う

### ページネーション

- `OFFSET` は深いページほど読む行数が増え、課金も増える。`id < cursor` のカーソル方式を使う（hono-api.md の一覧ルート）
- 並び順のキーは一意にする。`created_at` だけで並べると同時刻の行が飛ぶので `(created_at, id)` にする

## Read replication（必要になってから）

世界中のユーザーからの読み取りレイテンシが問題になった場合だけ有効にする。

- ダッシュボードか REST API で DB の read replication を有効にする
- Worker では Sessions API（`env.DB.withSession()`）を通したクエリだけがレプリカに行く
- 書き込み直後の読み取りで一貫性が要る場合は、レスポンスで bookmark（`session.getBookmark()`）を返し、次のリクエストで `withSession(bookmark)` に渡す
- Drizzle から Sessions API を使う方法は https://orm.drizzle.team/docs/read-replicas と Cloudflare docs で確かめる

## アンチパターン

- ループ内でクエリを発行する（N+1）
- `sql.raw` に入力を連結する
- `drizzle-kit push` を本番 DB に使う
- 対話的トランザクションを前提にした業務ロジックを D1 に載せる
- 深い `OFFSET` ページング
- 全テナントのデータを 1 テーブルに入れ、`tenant_id` の絞り込みを各クエリで手書きする（ミドルウェアやクエリ関数に集約する）
