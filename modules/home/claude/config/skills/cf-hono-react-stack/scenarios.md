# Scenarios for cf-hono-react-stack

## Scenario 1: 典型（新規アプリの設計と実装方針）

「Todo アプリに、ルーム単位でメッセージをリアルタイム共有する機能を付けたい。Cloudflare Workers + Hono + React + D1 + Durable Objects で、ディレクトリ構成、wrangler.jsonc、スキーマ、主要な API ルート、React の呼び出し方、テスト方針を設計して、主要ファイルのコードを書いて」

**期待する動作**: Todo は D1、ルームのメッセージとリアルタイム配信は DO に置き、1 Worker に SPA と API を同居させた構成を出す。

**合否判定**:
- [ ] Todo を D1（Drizzle）、ルームを DO（SQLite storage + WebSocket Hibernation）に振り分けている
- [ ] `wrangler.jsonc` に `not_found_handling: "single-page-application"` と `run_worker_first: ["/api/*"]` がある
- [ ] DO クラスを `exports` で宣言し、エントリポイントから named export している
- [ ] Hono のルートをチェーンして `AppType` を export し、React は `hc<AppType>` と TanStack Query で呼んでいる
- [ ] 入力を zod で検証し、所有者チェックをクエリ条件に含めている
- [ ] テストに `@cloudflare/vitest-plugin` を使い、D1 migration をテストに当てている
- [ ] WebSocket の接続で認証と `Origin` の確認をしている

---

## Scenario 2: 典型（デプロイの構築）

「このスタックのアプリを staging と production に分けて、GitHub Actions でデプロイしたい。手動デプロイの手順も知りたい」

**期待する動作**: 環境分けの `wrangler.jsonc`、手動デプロイ手順、GitHub Actions のワークフローを、migration の順序と secrets の扱いを守って出す。

**合否判定**:
- [ ] `env.staging` で D1・DO・rate limit などの binding を書き直している
- [ ] Vite 構成なので環境を `CLOUDFLARE_ENV` でビルド時に選び、`wrangler deploy --env` を使っていない
- [ ] D1 migration を Worker デプロイより前に当て、`--config wrangler.jsonc` を付けている
- [ ] API トークンを最小権限にし、GitHub の Environment secrets に置いている
- [ ] production の前に承認（Environment の Required reviewers）を挟んでいる
- [ ] `concurrency` でデプロイと migration の並列実行を防いでいる
- [ ] 破壊的なスキーマ変更を expand / contract に分ける方針に触れている

---

## Scenario 3: エッジ（D1 と DO の境界判断）

「座席予約システムを作りたい。公演ごとに座席を早い者勝ちで確保し、ユーザーは自分の予約一覧を見られるようにしたい。D1 だけで作れる？」

**期待する動作**: 座席の確保だけなら D1 の一意制約か条件付き `UPDATE` で早い者勝ちを守れると答える。そのうえで、仮押さえの期限や座席マップのリアルタイム更新が要るなら、公演ごとの DO を正にし、ユーザー別の予約一覧を D1 に投影する設計を示す。

**合否判定**:
- [ ] D1 だけで作れる条件（一意制約・条件付き UPDATE・batch）を具体的に示している
- [ ] D1 で対話的トランザクションを前提にできないことに触れている
- [ ] DO が必要になる条件（仮押さえの期限、リアルタイム配信、高頻度の競合）を挙げている
- [ ] DO を使う場合は公演単位（全体で 1 つではない）にしている
- [ ] ユーザー別の予約一覧を D1 に投影し、alarm による再試行と冪等な更新に触れている
