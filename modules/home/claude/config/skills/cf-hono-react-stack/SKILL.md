---
name: cf-hono-react-stack
description: Opinionated full-stack guide for Cloudflare Workers + Hono + React (Vite SPA) + D1 (Drizzle ORM) + Durable Objects in a single Worker. Use when scaffolding, designing, implementing, reviewing, testing or deploying apps on this stack (Hono RPC with hc, wrangler.jsonc, @cloudflare/vite-plugin, D1 migrations, Durable Objects WebSockets, GitHub Actions deploy). Cloudflare / Hono / React / D1 / Durable Objects でアプリを開発・設計・レビュー・テスト・デプロイするときに使う。Defers product-level details to the cloudflare, durable-objects, workers-best-practices and wrangler skills.
---

# Cloudflare Workers + Hono + React + D1 + Durable Objects

このスキルは、このスタックで「どう組むか」を決めるガイドである。
製品ごとの網羅的な仕様は既存スキルと公式 docs に任せ、ここではスタック全体の構成・境界・規約・アンチパターンだけを扱う。

## 使う場面と使わない場面

使う場面:

- このスタックで新規プロジェクトを作る、または既存プロジェクトに機能を足す
- Hono API、React クライアント、D1 スキーマ、Durable Object の設計やレビューをする
- テスト、手動デプロイ、GitHub Actions によるデプロイを組む

使わない場面（別の判断が要る）:

- SSR や SEO が必須のアプリ。React Router framework mode などの SSR 構成を検討する
- Cloudflare Pages（Functions）での構築。新規は Workers + static assets を使う
- Agents SDK を使う AI エージェントは `agents-sdk` スキルを使う

## アーキテクチャ

1 つの Worker が静的アセット（React SPA）と API（Hono）を同時に配信する。

```
Browser
  │  GET /todos（画面遷移）       GET /api/*（fetch / WebSocket）
  ▼                               ▼
┌──────────────────────── Worker（1 デプロイ単位）────────────────────────┐
│ Static Assets                  run_worker_first: ["/api/*"]             │
│  dist/client（SPA）             │                                       │
│  not_found → index.html         ▼                                       │
│                         Hono app（basePath "/api"）                     │
│                           ├─ routes/todos.ts ──► D1（Drizzle）          │
│                           └─ routes/rooms.ts ──► Durable Object "Room"  │
│                                                   （SQLite storage・WS）│
└─────────────────────────────────────────────────────────────────────────┘
React は hc<AppType>（hono/client）で API を呼び、型を Worker と共有する
```

## ディレクトリ規約

Cloudflare 公式の Hono + React テンプレート（`cloudflare/templates/vite-react-template`）の `src/worker/` と `src/react-app/` の分け方を基準にし、足すファイルは次の場所に置く。

```
.
├── src/
│   ├── worker/
│   │   ├── index.ts          # Hono app、AppType、DO クラスの export
│   │   ├── env.ts            # AppEnv（Bindings / Variables）
│   │   ├── middleware/       # withDb、requireSession、requireRoomMember など
│   │   ├── routes/           # 機能ごとのサブアプリ（auth.ts, todos.ts, rooms.ts）
│   │   ├── db/schema.ts      # Drizzle スキーマ
│   │   └── do/room.ts        # Durable Object クラス
│   ├── shared/               # Worker と React で共有する zod スキーマと型だけを置く
│   └── react-app/
│       ├── main.tsx
│       ├── lib/api.ts        # hc クライアント（唯一の API 入口）
│       ├── features/         # 画面・hooks を機能単位で置く
│       └── test/setup.ts     # React テストの初期化
├── public/_headers           # 静的アセットのセキュリティヘッダー
├── migrations/               # drizzle-kit generate の出力 = D1 migrations_dir
├── test/                     # Worker 側テスト（helpers.ts、apply-migrations.ts、env.d.ts、*.test.ts）
├── wrangler.jsonc
├── worker-configuration.d.ts # wrangler types が生成する。手で編集しない
├── drizzle.config.ts
├── vite.config.ts
├── vitest.config.ts          # Worker テスト（workerd）
├── vitest.client.config.ts   # React テスト（jsdom）
└── tsconfig.{app,worker,node,test}.json
```

## 意思決定ツリー: D1 か Durable Object か

```
そのデータは…
├─ 複数ユーザー・複数エンティティをまたいで検索・集計・一覧する？ ──► D1
├─ 1 つのエンティティ（ルーム、ドキュメント、公演）単位で
│   ├─ 1 文の条件付き書き込みで整合性が守れる ──────────────────────► D1
│   │   （一意制約、UPDATE ... WHERE status = 'available'、ON CONFLICT）
│   ├─ 読んでから判断して書く、複数手順の直列化が要る ─────────────► DO
│   │   （仮押さえ、割り当てアルゴリズム、高頻度の競合）
│   ├─ リアルタイムに配信したい（WebSocket、プレゼンス） ─────────────► DO
│   └─ 一定時間後に処理したい（仮押さえの期限切れなど、alarm） ───────► DO
└─ 両方の性質がある ──► DO を正（source of truth）にし、
                        エンティティをまたぐ一覧・検索用の投影を D1 に書く（durable-objects.md）
```

迷ったら D1 から始める。DO は「複数手順の直列化」「リアルタイム」「タイマー」のどれかが必要になってから足す。

例: 座席予約。座席の確保だけなら、D1 の一意制約（`(performance_id, seat_id)`）か条件付き `UPDATE` で早い者勝ちを守れる。仮押さえの期限や座席マップのリアルタイム更新が要るなら、公演ごとの DO（`performance:<id>`）を正にし、ユーザー別の予約一覧は D1 に投影する。

## 標準ワークフロー

新機能は次の順で進める。各ステップの詳細は対応する reference にある。

1. `wrangler.jsonc` に binding を足し、`npx wrangler types --config wrangler.jsonc` で `Env` を再生成する（project-setup.md）
2. 失敗するテストを先に書く（testing.md）
3. `src/worker/db/schema.ts` を変更し、`npx drizzle-kit generate` で migration を作る（d1-drizzle.md）
4. Hono のサブアプリにルートを足し、zod で入力を検証する（hono-api.md）
5. `src/worker/index.ts` でルートをチェーンし、`AppType` が更新されることを確かめる
6. React 側は `lib/api.ts` の `hc` クライアントと TanStack Query で呼ぶ（react-client.md）
7. `npm run dev` で手元確認 → テスト → デプロイ（deploy-ops.md）

## ゴールデンルール

1. 1 Worker に SPA と API を同居させ、`run_worker_first: ["/api/*"]` で API だけ Worker に通す
2. `Env` は `wrangler types` で生成する。手書きしない
3. Hono のルートはメソッドチェーンで定義し、`export type AppType` で型を公開する
4. React からの API 呼び出しは `hc<AppType>` だけを使う。生の `fetch` で型共有を捨てない
5. すべての入力（body / query / param / header）を zod で検証する
6. D1 へのアクセスは Drizzle 経由にし、生 SQL は `sql` テンプレートのプレースホルダで書く
7. 複数の書き込みを原子的に行うときは `batch` を使う。D1 で `BEGIN TRANSACTION` に頼らない
8. DO はエンティティ単位で細かく分け、WebSocket は Hibernation API で受ける
9. リクエストに紐づく状態をモジュールスコープに置かない。後処理は `c.executionCtx.waitUntil` に渡す
10. 秘密情報は `wrangler secret` と `.dev.vars` だけで扱い、`vars` や `VITE_*` に入れない
11. デプロイ順は「D1 migration → Worker deploy」に固定し、スキーマ変更は前方互換にする

## アンチパターン早見表

| アンチパターン | 何が起きるか | 参照 |
|---|---|---|
| `app.get()` を文ごとに呼び、チェーンしない | `AppType` にルートが載らず、`hc` が `unknown` になる | hono-api.md |
| モジュールスコープに `let currentUser` を置く | 同じ isolate の別リクエストに状態が漏れる | hono-api.md |
| `await` しない Promise を投げっぱなしにする | レスポンス後に処理が打ち切られる | hono-api.md |
| ループ内でクエリを発行する（N+1） | レイテンシが件数に比例し、クエリ上限に当たる | d1-drizzle.md |
| `sql.raw` に入力を連結する | SQL インジェクション | d1-drizzle.md |
| 全データを 1 つのグローバル DO に集める | 1 スレッドに直列化され、スループットの上限になる | durable-objects.md |
| `ctx.acceptWebSocket` を使わない WebSocket | 接続中ずっと課金され、hibernate できない | durable-objects.md |
| JWT を `localStorage` に保存する | XSS で盗まれる | security.md |
| デプロイ後に migration を流す | 新コードが存在しないカラムを読んでエラーになる | deploy-ops.md |

## Reference ナビ

タスクに必要な reference だけを読む。

| やりたいこと | 読むファイル |
|---|---|
| プロジェクト作成、`wrangler.jsonc`、Vite、TypeScript 設定 | [references/project-setup.md](references/project-setup.md) |
| API ルート、バリデーション、エラー処理、ミドルウェア | [references/hono-api.md](references/hono-api.md) |
| React からの API 呼び出し、状態管理、ルーティング | [references/react-client.md](references/react-client.md) |
| スキーマ、migration、クエリ、ページネーション | [references/d1-drizzle.md](references/d1-drizzle.md) |
| リアルタイム、WebSocket、直列化、alarm | [references/durable-objects.md](references/durable-objects.md) |
| Worker・DO・D1・React のテスト | [references/testing.md](references/testing.md) |
| 認証、CSRF、CORS、secrets、レート制限 | [references/security.md](references/security.md) |
| 手動デプロイ、GitHub Actions、環境分け、運用 | [references/deploy-ops.md](references/deploy-ops.md) |

## Retrieval 方針

このスタックは変化が速い。2026-10 時点で次の変更が入っている。

- テストは `@cloudflare/vitest-pool-workers` から `@cloudflare/vitest-plugin` に移行した
- DO クラスの宣言は `migrations` 配列から `exports` フィールドに移行した
- compatibility_date が 2026-08-04 以降なら `nodejs_compat` は既定で有効になる

パッケージ名・設定キー・CLI フラグを書く前に、次の順で確かめる。

1. 公式 docs（Markdown 版は URL 末尾に `index.md` を付けると取れる）
   - https://developers.cloudflare.com/workers/vite-plugin/
   - https://developers.cloudflare.com/d1/ / https://developers.cloudflare.com/durable-objects/
   - https://hono.dev/docs/ / https://orm.drizzle.team/docs/connect-cloudflare-d1
2. 製品別スキル: `wrangler`（CLI）、`durable-objects`（DO の詳細 API）、`workers-best-practices`（Workers 全般のレビュー観点）、`cloudflare`（製品横断）
3. 各 reference の「確認先」に書いた URL

reference のコード例は構成と規約を示すものである。API の細部が docs と食い違ったら docs を正とする。
