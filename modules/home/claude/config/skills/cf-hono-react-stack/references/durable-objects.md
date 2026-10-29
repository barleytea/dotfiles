# Durable Objects

このスタックで DO を使うときの設計規約。DO の API の網羅的な説明は `durable-objects` スキルに任せる。

確認先:

- https://developers.cloudflare.com/durable-objects/best-practices/rules-of-durable-objects/
- https://developers.cloudflare.com/durable-objects/api/base/
- https://developers.cloudflare.com/durable-objects/api/sqlite-storage-api/
- https://developers.cloudflare.com/durable-objects/best-practices/websockets/
- https://developers.cloudflare.com/durable-objects/api/alarms/
- https://developers.cloudflare.com/durable-objects/reference/durable-objects-migrations/

## いつ DO を使うか

SKILL.md の意思決定ツリーに従う。要点は次のとおり。

- D1: エンティティをまたぐ検索・集計・一覧
- DO: 1 エンティティ単位の直列化、リアルタイム配信、タイマー（alarm）

DO は 1 インスタンスが 1 スレッドで動く。「1 ルーム = 1 DO」「1 ドキュメント = 1 DO」のように、負荷が自然に分散する単位で分ける。

## キー設計

- `env.ROOM.getByName(name)` で stub を取る。名前はエンティティの ID（`room:<uuid>`）にする
- 名前に入力値を使う場合は、Worker 側で形式を検証し、アクセス権を確認してから stub を取る
- 全ユーザー共通の 1 インスタンス（`getByName("global")`）を作らない。必要な場合は、そこに来るリクエスト量の上限を見積もる
- stub はリクエストごとに取る。モジュールスコープにキャッシュしない

## DO クラス

```ts
// src/worker/do/room.ts
import { DurableObject } from "cloudflare:workers";

export type RoomMessage = { id: number; userId: string; text: string; createdAt: number };
type Attachment = { userId: string };

export class Room extends DurableObject<Env> {
  constructor(ctx: DurableObjectState, env: Env) {
    super(ctx, env);
    // SQLite の exec は同期なので、コンストラクタで初期化してよい
    this.ctx.storage.sql.exec(`
      CREATE TABLE IF NOT EXISTS messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        text TEXT NOT NULL,
        created_at INTEGER NOT NULL
      );
      CREATE TABLE IF NOT EXISTS outbox (
        message_id INTEGER PRIMARY KEY,
        room_id TEXT NOT NULL,
        created_at INTEGER NOT NULL
      );
    `);
  }

  // public メソッドは Worker から RPC で呼べる。引数と戻り値は構造化複製できる値にする
  async list(limit = 50): Promise<RoomMessage[]> {
    return this.ctx.storage.sql
      .exec<RoomMessage>(
        `SELECT id, user_id AS userId, text, created_at AS createdAt
         FROM messages ORDER BY id DESC LIMIT ?`,
        limit,
      )
      .toArray();
  }

  async post(roomId: string, userId: string, text: string): Promise<RoomMessage> {
    const createdAt = Date.now();
    // 本体と outbox を同じトランザクションで書く（D1 への投影は alarm で行う）
    const msg = this.ctx.storage.transactionSync(() => {
      const m = this.ctx.storage.sql
        .exec<RoomMessage>(
          `INSERT INTO messages (user_id, text, created_at) VALUES (?, ?, ?)
           RETURNING id, user_id AS userId, text, created_at AS createdAt`,
          userId,
          text,
          createdAt,
        )
        .one();
      this.ctx.storage.sql.exec(
        `INSERT INTO outbox (message_id, room_id, created_at) VALUES (?, ?, ?)`,
        m.id,
        roomId,
        createdAt,
      );
      return m;
    });
    // alarm は 1 DO に 1 つ。予約済みなら上書きしない
    if ((await this.ctx.storage.getAlarm()) === null) {
      await this.ctx.storage.setAlarm(Date.now());
    }
    this.broadcast({ type: "message" });
    return msg;
  }

  // 接続中のユーザー（プレゼンス）。hibernate 後も attachment から復元できる
  async presence(): Promise<string[]> {
    const ids = this.ctx
      .getWebSockets()
      .map((ws) => (ws.deserializeAttachment() as Attachment).userId);
    return [...new Set(ids)];
  }

  // WebSocket の受け口。Worker で認証・認可済みのリクエストだけが届く
  async fetch(request: Request): Promise<Response> {
    const userId = request.headers.get("X-User-Id");
    if (!userId) return new Response("unauthorized", { status: 401 });

    const { 0: client, 1: server } = new WebSocketPair();
    // acceptWebSocket を使うと、接続を保ったまま DO を hibernate できる
    this.ctx.acceptWebSocket(server);
    // メモリ上のフィールドは hibernate で消えるので、接続ごとの情報は attachment に入れる
    server.serializeAttachment({ userId } satisfies Attachment);
    return new Response(null, { status: 101, webSocket: client });
  }

  async webSocketMessage(ws: WebSocket, message: string | ArrayBuffer) {
    // 書き込みは HTTP（RPC 経由）に一本化し、WS は通知専用にする
    if (message === "ping") ws.send("pong");
  }

  async webSocketClose(ws: WebSocket) {
    // 受け取ったコード（1005 / 1006 など）は close() に渡せない場合があるので 1000 で閉じる
    ws.close(1000, "closing");
  }

  async alarm() {
    const rows = this.ctx.storage.sql
      .exec<{ messageId: number; roomId: string; createdAt: number }>(
        `SELECT message_id AS messageId, room_id AS roomId, created_at AS createdAt
         FROM outbox ORDER BY message_id LIMIT 100`,
      )
      .toArray();
    const last = rows.at(-1);
    if (!last) return;

    // alarm は少なくとも 1 回実行される。何度実行しても同じ結果になる更新にする
    await this.env.DB.prepare(
      `UPDATE rooms SET last_message_at = MAX(COALESCE(last_message_at, 0), ?) WHERE id = ?`,
    )
      .bind(last.createdAt, last.roomId)
      .run();

    // D1 を await している間に新しい行が入っても消さないよう、処理した範囲だけを消す
    this.ctx.storage.sql.exec(`DELETE FROM outbox WHERE message_id <= ?`, last.messageId);
    if (this.ctx.storage.sql.exec(`SELECT 1 FROM outbox LIMIT 1`).toArray().length > 0) {
      await this.ctx.storage.setAlarm(Date.now());
    }
  }

  private broadcast(payload: unknown) {
    const data = JSON.stringify(payload);
    for (const ws of this.ctx.getWebSockets()) ws.send(data);
  }
}
```

規約:

- ストレージは SQLite（`ctx.storage.sql`）を使う。新規クラスは `wrangler.jsonc` の `exports` で `"storage": "sqlite"` を宣言する（project-setup.md）
- カーソル（`exec` の戻り値）は `await` の前に `.toArray()` / `.one()` で読み切る
- `BEGIN` / `SAVEPOINT` は `exec` で使えない。複数の文をまとめるときは `ctx.storage.transactionSync()` を使う
- メモリ上のフィールドはキャッシュとしてだけ使う。hibernate や再起動で消えるので、正はストレージに置く
- `blockConcurrencyWhile` は非同期の初期化（外部からのデータ読み込みなど）にだけ使う。リクエスト処理で常用すると直列化の待ち時間が増える
- DO の中で外部への `fetch` や D1 を `await` すると、その間に別のリクエストが割り込む（input gate が開く）。割り込まれて困る「読んでから書く」処理は、ストレージ操作だけで完結させる。`alarm()` の D1 投影は、処理した範囲だけを消すことで割り込みを許容している
- ping/pong だけなら `ctx.setWebSocketAutoResponse` を使うと DO を起こさずに応答できる
- DO 内の SQLite スキーマの変更は、コンストラクタで `PRAGMA user_version` を見て段階的に `ALTER TABLE` する。D1 の migration とは別物である

## アクセス制御（ルームのメンバー）

ルームの一覧とメンバー表は、ルームをまたいで引くので D1 に置く。メッセージ本体は DO を正にする。

```ts
// src/worker/db/schema.ts に追加する
// d1-drizzle.md の import 行に primaryKey を足し、createdAt ヘルパーを再利用する

export const rooms = sqliteTable("rooms", {
  id: text("id").primaryKey(), // crypto.randomUUID()。DO 名は room:<id>
  name: text("name").notNull(),
  lastMessageAt: integer("last_message_at", { mode: "timestamp_ms" }), // DO からの投影
  createdAt: createdAt(),
});

export const roomMembers = sqliteTable(
  "room_members",
  {
    roomId: text("room_id")
      .notNull()
      .references(() => rooms.id, { onDelete: "cascade" }),
    userId: text("user_id")
      .notNull()
      .references(() => users.id, { onDelete: "cascade" }),
  },
  (t) => [primaryKey({ columns: [t.roomId, t.userId] }), index("room_members_user_id_idx").on(t.userId)],
);
```

```ts
// src/worker/middleware/room.ts
import { and, eq } from "drizzle-orm";
import { createMiddleware } from "hono/factory";
import { z } from "zod";
import { roomMembers } from "../db/schema";
import type { AppEnv } from "../env";

// 大文字小文字の違いで別の DO を指さないよう、小文字に正規化する（zod v4）
const roomId = z.uuid().transform((s) => s.toLowerCase());

export const requireRoomMember = createMiddleware<AppEnv>(async (c, next) => {
  const parsed = roomId.safeParse(c.req.param("id"));
  if (!parsed.success) return c.json({ error: "not_found" }, 404);

  const [member] = await c.var.db
    .select({ roomId: roomMembers.roomId })
    .from(roomMembers)
    .where(and(eq(roomMembers.roomId, parsed.data), eq(roomMembers.userId, c.var.userId)))
    .limit(1);
  // 存在を隠すため、非メンバーにも 404 を返す
  if (!member) return c.json({ error: "not_found" }, 404);

  c.set("roomId", parsed.data);
  await next();
});
```

このミドルウェアが `AppEnv` の `Variables.roomId`（hono-api.md）を設定する。プレゼンス（`stub.presence()`）を画面に出す場合は、`/:id/presence` のようなルートをこの後ろに足す。

## Hono からの中継

```ts
// src/worker/routes/rooms.ts
import { zValidator } from "@hono/zod-validator";
import { type Context, Hono } from "hono";
import { z } from "zod";
import { roomMembers, rooms } from "../db/schema";
import type { AppEnv } from "../env";
import { requireRoomMember } from "../middleware/room";
import { requireSession } from "../middleware/session";

const createBody = z.object({ name: z.string().trim().min(1).max(100) });
const postBody = z.object({ text: z.string().trim().min(1).max(1000) });

const roomStub = (c: Context<AppEnv>) => c.env.ROOM.getByName(`room:${c.var.roomId}`);

export const roomsRoute = new Hono<AppEnv>()
  .use(requireSession)
  .post("/", zValidator("json", createBody), async (c) => {
    const id = crypto.randomUUID();
    // ルームと作成者のメンバー登録を同時に行う
    await c.var.db.batch([
      c.var.db.insert(rooms).values({ id, name: c.req.valid("json").name }),
      c.var.db.insert(roomMembers).values({ roomId: id, userId: c.var.userId }),
    ]);
    return c.json({ id }, 201);
  })
  // /:id 配下はすべてメンバー確認を通す
  .use("/:id/*", requireRoomMember)
  .get("/:id/messages", async (c) => {
    return c.json({ messages: await roomStub(c).list() });
  })
  .post("/:id/messages", zValidator("json", postBody), async (c) => {
    const message = await roomStub(c).post(c.var.roomId, c.var.userId, c.req.valid("json").text);
    return c.json(message, 201);
  })
  .get("/:id/ws", async (c) => {
    if (c.req.header("Upgrade") !== "websocket") {
      return c.json({ error: "expected_websocket" }, 426);
    }
    // WebSocket は CSRF ミドルウェアの対象外なので Origin を確かめる
    if (c.req.header("Origin") !== new URL(c.req.url).origin) {
      return c.json({ error: "forbidden" }, 403);
    }
    // 認証済みのユーザー ID を Worker が付け直す。クライアントが送ったヘッダーは信用しない
    const req = new Request(c.req.raw);
    req.headers.set("X-User-Id", c.var.userId);
    const res = await roomStub(c).fetch(req);
    // stub から返った応答のヘッダーは変更できない。secureHeaders などが書き換えられるよう作り直す
    if (res.webSocket) return new Response(null, { status: 101, webSocket: res.webSocket });
    return new Response(res.body, res);
  });
```

- 読み書きは RPC（`stub.list()` / `stub.post()`）で呼ぶ。`fetch` は WebSocket の Upgrade にだけ使う
- 認可（メンバー確認）は Worker 側で済ませ、DO は認可済みの呼び出しだけを受ける前提にする。DO は外部から直接呼べない
- WebSocket の接続時も Cookie による認証ミドルウェアが動く。ブラウザの WebSocket はカスタムヘッダーを送れないので、トークンをクエリ文字列に載せる方式は避け、Cookie を使う
- WebSocket の中継は `npm run dev` と staging で実際に接続して確かめる（ミドルウェアとの組み合わせで壊れやすい）

## DO を正にして D1 に投影する

エンティティをまたぐ一覧（例: ルーム一覧を最終発言順に並べる）のために DO のデータを D1 にも置きたい場合は、DO を正にして D1 へ非同期に書く。上の `Room` クラスがこの形になっている。

1. DO の SQLite に本体と outbox の行を同じ `transactionSync` で書く
2. `ctx.storage.setAlarm()` で alarm を予約する（予約済みなら上書きしない）
3. `alarm()` で outbox を読み、D1 を更新してから、処理した範囲の outbox の行を消す
4. alarm は少なくとも 1 回実行され、例外を投げると再試行される。D1 への書き込みは何度実行しても同じ結果になるようにする（`MAX()` や upsert）

D1 は結果整合になる。即時に反映されていないと困る画面は、DO の RPC から直接読む。ユーザー単位の一覧のように DO をまたぐ画面は、遅延を許容して D1 を読む。

### 期限付きの処理（仮押さえなど）

一定時間後に状態を戻す処理も alarm で書く。期限を SQLite に保存し、`alarm()` で期限切れの行を処理して、次の期限で `setAlarm()` し直す。DO ごとに alarm は 1 つなので、複数の期限は「最も近い期限」で予約する。

## アンチパターン

- 全データを 1 つの DO に集める
- `server.accept()`（Hibernation ではない受け方）で WebSocket を受ける
- メモリ上の `Map` を正として扱い、ストレージに書かない
- DO の中で外部 I/O を挟んで「読んでから書く」処理を行う
- 認可を DO の中だけで行い、Worker 側で確認しない（あるいはその逆で、DO 名を入力から直接作る）
- 既存の DO クラスの rename・削除を `exports` の状態遷移を使わずに行う（データが失われる。deploy-ops.md）
