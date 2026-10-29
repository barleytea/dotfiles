# セキュリティ

secrets、認証、CSRF、CORS、レート制限、ヘッダーの規約。

確認先:

- https://developers.cloudflare.com/workers/configuration/secrets/
- https://developers.cloudflare.com/workers/runtime-apis/bindings/rate-limit/
- https://developers.cloudflare.com/workers/static-assets/headers/
- https://hono.dev/docs/middleware/builtin/csrf
- https://hono.dev/docs/middleware/builtin/secure-headers
- https://hono.dev/docs/helpers/cookie
- https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html

## Secrets

- 本番の値は `npx wrangler secret put <KEY> --config wrangler.jsonc`（staging は `--env staging` も付ける）で登録する
- ローカルの値は `.dev.vars` に書き、`.gitignore` に `.dev.vars*` と `.env*` を入れる。リポジトリには値を空にした `.dev.vars.example` だけを置く
- `wrangler.jsonc` の `vars` は公開してよい設定値だけに使う。リポジトリに入るので API キーやパスワードを書かない
- `VITE_*` の環境変数はブラウザに配られる。secrets を入れない
- コミット前に secret スキャナ（gitleaks など）を pre-commit と CI で動かす
- secrets を足したら `npx wrangler types --config wrangler.jsonc` を再実行する（`.dev.vars` のキーが `Env` に型として載る）

## 認証

### 方式の選び方

| 用途 | 推奨 |
|---|---|
| 社内ツール・管理画面 | Cloudflare Access（Zero Trust）を前段に置き、アプリ側は Access の JWT を検証する |
| 一般ユーザー向け | OAuth / OIDC（Google、GitHub など）またはメールのマジックリンク + サーバー側セッション |
| パスワード認証が要件として必須 | 実績のあるライブラリを使う。自作する場合は Web Crypto の PBKDF2 で、反復回数を OWASP の推奨値に合わせる |

パスワード保存やトークン発行の処理を思いつきで自作しない。

### サーバー側セッション（Cookie + D1）

ブラウザに渡すのはランダムなトークンだけにし、D1 にはそのハッシュを保存する。

```ts
// src/worker/db/schema.ts に追加
export const sessions = sqliteTable("sessions", {
  id: text("id").primaryKey(), // トークンの SHA-256（hex）。生のトークンは保存しない
  userId: text("user_id")
    .notNull()
    .references(() => users.id, { onDelete: "cascade" }),
  expiresAt: integer("expires_at", { mode: "timestamp_ms" }).notNull(),
});
```

```ts
// src/worker/middleware/session.ts
import { and, eq, gt } from "drizzle-orm";
import { getCookie } from "hono/cookie";
import { createMiddleware } from "hono/factory";
import { HTTPException } from "hono/http-exception";
import { sessions } from "../db/schema";
import type { AppEnv } from "../env";

export const SESSION_COOKIE = "__Host-session";

export async function hashToken(token: string) {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(token));
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

export const requireSession = createMiddleware<AppEnv>(async (c, next) => {
  const token = getCookie(c, SESSION_COOKIE);
  if (!token) throw new HTTPException(401, { message: "unauthorized" });

  const [session] = await c.var.db
    .select({ userId: sessions.userId })
    .from(sessions)
    .where(and(eq(sessions.id, await hashToken(token)), gt(sessions.expiresAt, new Date())))
    .limit(1);
  if (!session) throw new HTTPException(401, { message: "unauthorized" });

  c.set("userId", session.userId);
  await next();
});
```

ログイン成功時の Cookie 発行:

```ts
import { setCookie } from "hono/cookie";

const token = crypto.randomUUID() + crypto.randomUUID(); // 推測不能な 244 ビット相当
await c.var.db.insert(sessions).values({
  id: await hashToken(token),
  userId,
  expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
});
setCookie(c, SESSION_COOKIE, token, {
  httpOnly: true,
  secure: true,
  sameSite: "Lax",
  path: "/",
  maxAge: 30 * 24 * 60 * 60,
});
```

- `__Host-` 接頭辞の Cookie は `Secure`・`Path=/`・`Domain` なしが強制され、サブドメインからの上書きを防げる
- Chrome と Firefox は `http://localhost` で `Secure` Cookie を受け付けるが、Safari と LAN の IP アドレスでのアクセスは受け付けない。ローカル開発は Chrome / Firefox の `localhost` で行い、Safari で確認するときは staging を使う
- ログインとログアウトのルートは `routes/auth.ts` の公開サブアプリに置き、`requireSession` を掛けない（hono-api.md）
- ログアウトでは D1 の行を消し、Cookie を削除する
- ログイン時にセッションを作り直す（セッション固定攻撃の対策）
- 期限切れの行は Cron Trigger で定期的に消す
- JWT を使う場合も `localStorage` には置かず、HttpOnly Cookie に入れる。失効させたい要件があるならサーバー側セッションを選ぶ

## CSRF と CORS

同一オリジン構成（SPA と API が同じ Worker）を前提にする。

- `hono/csrf` を全体に掛ける。form 系の Content-Type で送られる state 変更リクエストの `Origin` / `Sec-Fetch-Site` を検証する
- JSON API は、`SameSite=Lax` の Cookie と、クロスオリジンの `application/json` 送信にはプリフライトが要ることで守られる。この前提を壊さないため、`cors()` を付けない
- state を変える操作を `GET` で実装しない
- WebSocket の Upgrade は CSRF ミドルウェアと CORS の対象外なので、ルートで `Origin` を確かめる

```ts
const origin = c.req.header("Origin");
if (origin !== new URL(c.req.url).origin) return c.json({ error: "forbidden" }, 403);
```

別オリジンからの呼び出しがどうしても必要な場合だけ、`cors({ origin: [許可するオリジン], credentials: true })` を対象ルートに限定して付ける。`origin: "*"` と `credentials: true` は併用しない。

## 入力と出力

- すべての入力を zod で検証する（hono-api.md）。長さの上限も必ず付ける
- 大きなボディを拒否するため、`hono/body-limit` の `bodyLimit({ maxSize })` を書き込み系ルートに付ける
- エラー応答に例外メッセージやスタックトレースを含めない
- ユーザー入力を React で表示するときに `dangerouslySetInnerHTML` を使わない。Markdown などを表示する場合はサニタイズする

## レート制限

ログイン、サインアップ、メール送信、高コストな API に付ける。

```jsonc
// wrangler.jsonc
"ratelimits": [
  // namespace_id はアカウント内で一意な整数（文字列で書く）。period は 10 か 60 秒
  { "name": "AUTH_LIMITER", "namespace_id": "1001", "simple": { "limit": 10, "period": 60 } }
]
```

```ts
const ip = c.req.header("CF-Connecting-IP");
// ヘッダーがないと全員が同じキーを共有してしまうので拒否する
if (!ip) return c.json({ error: "bad_request" }, 400);
const { email } = c.req.valid("json");
// IP 単位と、狙われたアカウント単位の両方で数える
for (const key of [`ip:${ip}`, `email:${email.toLowerCase()}`]) {
  const { success } = await c.env.AUTH_LIMITER.limit({ key });
  if (!success) return c.json({ error: "too_many_requests" }, 429);
}
```

- 上限は Cloudflare の拠点ごとに数えられる近似値である。厳密な回数制限（課金や在庫）は Durable Object で数える
- IPv6 は 1 人が大量のアドレスを持てるので、必要なら /64 に丸めてキーにする
- ログイン済みのルートはユーザー ID をキーにする
- 分散した攻撃（多数の IP からのパスワードリスト攻撃）は IP 単位の制限では防げない。Cloudflare の WAF / Bot 対策や Turnstile を併用する

## セキュリティヘッダー

- API のレスポンスには `secureHeaders()` を付ける（hono-api.md のエントリポイント）
- SPA（静的アセット）のレスポンスは Worker を通らないので、`public/_headers` で CSP などを付ける

```
/*
  Content-Security-Policy: default-src 'self'; connect-src 'self'; img-src 'self' data:; frame-ancestors 'none'
  X-Content-Type-Options: nosniff
  Referrer-Policy: strict-origin-when-cross-origin
```

- CSP は Vite のビルド結果（インラインスクリプトの有無）に合わせて調整し、`npm run preview` で違反が出ないことを確かめる
- SPA のフォールバック（`/todos` などで返る `index.html`）にもヘッダーが付くかを、デプロイ後に `curl -I https://<host>/todos` で確かめる
- WebSocket を使う場合、`connect-src 'self'` で同一オリジンの `wss:` が許可されるかをブラウザで確かめる

## アンチパターン

- `wrangler.jsonc` の `vars` や `VITE_*` に secrets を書く
- `.dev.vars` をコミットする
- JWT やセッショントークンを `localStorage` に保存する
- 生のセッショントークンを DB に保存する
- `cors({ origin: "*" })` を Cookie 認証の API に付ける
- WebSocket の接続で `Origin` を確かめない
