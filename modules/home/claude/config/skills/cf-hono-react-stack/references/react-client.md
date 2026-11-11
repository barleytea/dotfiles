# React クライアント（Vite SPA）

React 側の API 呼び出し、サーバー状態、ルーティングの規約。

確認先:

- https://hono.dev/docs/guides/rpc
- https://tanstack.com/query/latest/docs/framework/react/overview
- https://vite.dev/guide/env-and-mode
- https://reactrouter.com/start/modes

## API クライアント

API の入口は 1 ファイルに集める。コンポーネントから `fetch` を直接呼ばない。

```ts
// src/react-app/lib/api.ts
import { hc } from "hono/client";
import type { AppType } from "../../worker";

// 同一オリジン配信なのでベース URL は "/"。Cookie は同一オリジンなら自動で送られる
export const client = hc<AppType>("/");
export const api = client.api;

export class ApiError extends Error {
  // erasableSyntaxOnly でも通るよう、コンストラクタ引数のプロパティ宣言は使わない
  readonly status: number;
  readonly body: unknown;
  constructor(status: number, body: unknown) {
    super(`API error ${status}`);
    this.status = status;
    this.body = body;
  }
}

// 非 2xx のレスポンスを例外に変換する。成功時の型の絞り込みは呼び出し側の if で行う
export async function toApiError(res: { status: number; json(): Promise<unknown> }) {
  return new ApiError(res.status, await res.json().catch(() => null));
}
```

- `import type` だけを使う。値として import すると Worker のコードが client バンドルに入る
- `res.json()` の型は、ルートが返しうる全ステータスのボディの union になる。`if (!res.ok)` で例外を投げてから `res.json()` を呼ぶと、成功時の型に絞り込まれる。汎用の `unwrap(res)` 関数に包むと絞り込みが効かなくなるので作らない
- `res.ok` で絞り込めない場合（Hono のバージョンが古いなど）は `res.status === 200` で分岐する
- ルート数が多く型推論が重くなったら、Hono docs の RPC ガイドにある「型を事前計算した `hc` を export する」パターンを使う

## サーバー状態は TanStack Query

```ts
// src/react-app/features/todos/hooks.ts
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import type { InferRequestType, InferResponseType } from "hono/client";
import { api, toApiError } from "../../lib/api";

const $list = api.todos.$get;
const $create = api.todos.$post;

export type TodoList = InferResponseType<typeof $list, 200>;
type CreateInput = InferRequestType<typeof $create>["json"];

export const todoKeys = {
  all: ["todos"] as const,
  list: (cursor?: number) => [...todoKeys.all, "list", cursor] as const,
};

export function useTodos(cursor?: number) {
  return useQuery({
    queryKey: todoKeys.list(cursor),
    queryFn: async () => {
      const res = await $list({ query: { cursor: cursor?.toString() } });
      if (!res.ok) throw await toApiError(res);
      return res.json();
    },
  });
}

export function useCreateTodo() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (json: CreateInput) => {
      const res = await $create({ json });
      if (!res.ok) throw await toApiError(res);
      return res.json();
    },
    // 作成後は一覧を取り直す。楽観的更新は体感が問題になってから入れる
    onSuccess: () => qc.invalidateQueries({ queryKey: todoKeys.all }),
  });
}
```

規約:

- サーバーから来るデータは TanStack Query のキャッシュだけに置く。`useState` や Zustand に複製しない
- クライアント専用の状態（モーダルの開閉、入力途中の値）は `useState` で持つ。グローバル状態管理ライブラリは必要になるまで入れない
- query key は機能ごとにファクトリ（`todoKeys`）で管理し、無効化の範囲を明確にする
- `QueryClient` は `main.tsx` で 1 つだけ作り、`QueryClientProvider` で渡す

## リアルタイム更新（DO の WebSocket）

WebSocket の受信は TanStack Query のキャッシュに反映する。別のストアを作らない。

```ts
// src/react-app/features/rooms/hooks.ts
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useEffect } from "react";
import { z } from "zod";
import { api, toApiError } from "../../lib/api";

export const roomKeys = {
  all: ["rooms"] as const,
  messages: (roomId: string) => [...roomKeys.all, roomId, "messages"] as const,
};

export function useRoomMessages(roomId: string) {
  return useQuery({
    queryKey: roomKeys.messages(roomId),
    queryFn: async () => {
      const res = await api.rooms[":id"].messages.$get({ param: { id: roomId } });
      if (!res.ok) throw await toApiError(res);
      return res.json();
    },
  });
}

// DO が送る通知の形。DO 側の変更で形が変わっても壊れないよう、受信時に検証する
const roomEvent = z.object({ type: z.literal("message") });

export function useRoomSocket(roomId: string) {
  const qc = useQueryClient();
  useEffect(() => {
    const proto = location.protocol === "https:" ? "wss:" : "ws:";
    const ws = new WebSocket(`${proto}//${location.host}/api/rooms/${encodeURIComponent(roomId)}/ws`);
    ws.onmessage = (e) => {
      const parsed = roomEvent.safeParse(JSON.parse(String(e.data)));
      if (!parsed.success) return;
      // 差分を当てるより、該当クエリを無効化して取り直す方が単純で壊れにくい
      qc.invalidateQueries({ queryKey: roomKeys.messages(roomId) });
    };
    return () => ws.close();
  }, [roomId, qc]);
}
```

- 再接続が必要になったら指数バックオフ付きで実装する。最初から入れない
- 通知のスキーマは `src/shared/` に置き、DO の送信側と共有してもよい

## ルーティングとコード分割

- ルーティングは React Router の declarative / data mode（SPA）を使う。framework mode（SSR）はこのスキルの対象外
- ルート単位で `lazy()` を使い、初期バンドルを小さく保つ
- 未知のパスは Workers の `not_found_handling: "single-page-application"` が `index.html` を返すので、React Router 側で 404 画面を出す
- ルートごとにエラーバウンダリを置き、API エラー（`ApiError`）の status で表示を分ける

## 環境変数

- `import.meta.env.VITE_*` はビルド時にバンドルへ埋め込まれ、誰でも読める
- API キーや secrets を `VITE_*` に入れない。必要な処理は Worker 側に置き、Worker の secrets を使う
- API のベース URL は同一オリジンなので環境変数にしない

## アンチパターン

- `fetch("/api/todos")` を直書きし、型共有を捨てる
- `import { something } from "../../worker"` で Worker のコードを値として取り込む
- サーバーデータを `useEffect` + `useState` で取得・保持する（キャッシュ、再取得、競合状態の処理を自前で抱えることになる）
- 楽観的更新、無限スクロール、オフライン対応を要件がない段階で入れる
