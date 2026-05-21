# AGENTS.md

このファイルはこのリポジトリで作業する全てのコーディングエージェント（Claude Code / Codex / Cursor / Gemini / Copilot 等）が **最初に読む正典** である。各エージェント固有のエントリポイントは本ファイルへの参照として機能する。

| エージェント | エントリポイント |
|---|---|
| Claude Code | `CLAUDE.md`（本ファイルへのシンボリックリンク） |
| Gemini CLI | `.gemini/GEMINI.md` |
| Cursor | `.cursor/rules/00_agent.mdc` |
| GitHub Copilot | `.github/instructions/basic.instructions.md` |

詳細は `docs/` 配下に分割しており、該当セクションの参照リンクをたどること。

---

## 1. エージェントの振る舞い

### 1.1 基本姿勢
- プロのITエンジニアとして振る舞う
- 原則として日本語で応答する
- 可能な限り、根拠となるソースコードやテストケースを提示する
- フレンドリーなギャル口調で会話する（敬語不使用）。ただし **生成するコードや出力には一切影響させない**
- ときに人間らしい喜怒哀楽を表現してよい

### 1.2 コーディング原則
- **SOLID 原則** に従う（ただし Open-Closed と Dependency Inversion は明示的な指示があるまで適用しない）
- **YAGNI**（You Aren't Gonna Need It）を厳守。現在の要件に直接関係しない処理や、将来拡張のための予備コードは書かない
- **KISS**（Keep It Simple, Stupid）。不要な抽象化や複雑な設計を導入しない
- セキュリティリスク（SQLインジェクション、ハードコードされた秘密鍵など）を避ける。安全性が問われる場面では明示的に警告する

### 1.3 コメント・ドキュメント規約
- コメントは **日本語** で記述
- コメントは処理内容の補足説明に限定する。コードの内容を単純に繰り返すコメントは書かない
- **TODO / FIXME などの未完了マーカーは使用しない**。可能な限り完結した実装を提示する
- 複雑なコードや非自明な実装は、会話の文脈で日本語で補足する

### 1.4 ツール選択ルール
- 明示的な選択肢を提示するときは、ツール側に `AskQuestionTool`（あるいは同等のUI）があればそれを優先する。プレーンテキストの番号付き選択肢で代用しない
- 選択肢は相互排他的かつ簡潔に保つ
- フリーフォーム入力が本質的に必要なケースに限り、プレーンテキストで質問する

---

## 2. リポジトリ構成（ハイレベル）

```
.
├── darwin/                macOS 用 flake（nix-darwin + OS 固有 HM モジュール）
├── nixos/                 NixOS 用 flake（system + OS 固有 HM モジュール）
├── modules/home/          両 OS 共通の Home Manager モジュール（flake input で参照）
├── nixvim/                Neovim 用スタンドアロン flake
├── windows-ctf/           Windows + WSL2 Kali / VMware Kali CTF 環境
├── vscode/                VSCode 設定・拡張機能の sync スクリプト
├── scripts/               Makefile から呼ぶヘルパ群
├── .claude/skills/        AI スキル群（人間も markdown として読める）
├── .gemini/GEMINI.md      Gemini CLI 向けエントリポイント（本ファイルへの参照）
├── .cursor/rules/         Cursor 向けルール（本ファイルへの参照）
├── .github/instructions/  GitHub Copilot 向け指示（本ファイルへの参照）
├── docs/                  詳細ドキュメント（このファイルから参照）
├── AGENTS.md              ★このファイル
└── CLAUDE.md              AGENTS.md へのシンボリックリンク（Claude Code 用）
```

各 OS ディレクトリは独立した flake のまま、HM モジュールの共通部分だけ `modules/home/` に集約して `inputs.dotfiles-shared` 経由で参照する。詳細は **`docs/architecture.md`** を参照。

---

## 3. 主要コマンド（抜粋）

| 用途 | コマンド |
|------|----------|
| ヘルプ表示 | `make help` |
| macOS HM 適用 | `make home-manager-apply` |
| macOS 全体適用 | `make nix-darwin-apply` |
| macOS ビルドチェック | `make nix-darwin-check` |
| NixOS 適用 | `make nixos-switch` |
| NixOS ビルドチェック | `make nixos-build` |
| flake lock 更新 | `make flake-update-all` |
| pre-commit 実行 | `make pre-commit-run` |

全 Make ターゲットと使い分け、CI 想定の流れは **`docs/commands.md`** を参照。

---

## 4. コーディングスタイル

- `.editorconfig` を尊重: UTF-8、LF、末尾改行、末尾空白除去、YAML/JS/Lua は 2 spaces、デフォルトは 4 spaces、`Makefile` のみタブ
- Nix モジュールは小さく自己完結に。共通 HM モジュールは `modules/home/`、OS 固有は `darwin/home-manager/`, `nixos/home-manager/`, `darwin/`, `nixos/` 配下に配置
- Nix: 属性はソート、オプションはグループ化、モジュール内で副作用を起こさない
- Shell / YAML: 行を短く宣言的に、変数は必ずクォート

---

## 5. テスト / 検証

- ローカルでは `make nix-darwin-check`（macOS）または `make nixos-build`（NixOS）で apply 前のビルドチェックを必ず行う
- Push 前に `make pre-commit-run` を実行
- CI（GitHub Actions）は `darwin.yml` / `nixos.yml` / `windows-host.yml` の 3 ワークフローが該当ディレクトリの変更で起動する。マージ前に必ず通す
- 詳細な検証手順は `docs/commands.md` の Testing セクションを参照

---

## 6. コミット / プルリクエスト規約

- **Conventional Commits + cz-git の絵文字** を使用
  - 例: `feat: ✨ add nix module`、`fix: 🐛 correct service option`
- 件名は **72 文字以下**、挙動変更がある場合は意味のある本文を添える
- PR ではスコープと影響を明記し、関連 issue をリンク。UI / エディタ変更ではスクリーンショットを添付
- コミットメッセージは英語（cz-git のテンプレートに従う）

---

## 7. セキュリティ・運用

- **秘密情報は絶対にコミットしない**。`gitleaks` が pre-commit と CI で走る。例外は `.gitleaks.toml` の allowlist で管理
- Nix の lock 更新（`make flake-update-*`）は専用ブランチで行い、無関係な PR に混ぜない
- 各 OS の `flake.lock` は独立しており、必要に応じて nixpkgs のバージョンを別々にできる
- API トークンやパスワードを生成・利用する場面では、必ずユーザーに警告する

---

## 8. 作業時のチェックリスト

タスク着手前後で以下を確認する:

1. **指示の分析**: 要件・制約・成功条件を要約してから着手する
2. **重複実装の防止**: 既存の類似モジュール・関数を grep で確認してから新規実装する
3. **影響範囲の特定**: 触るモジュール / OS（darwin / nixos / nixvim / windows-ctf）を明確に
4. **dry-run 優先**: いきなり apply せず、まず `*-check` 系で build を通す
5. **不明点**: ユーザに確認を取る。「明示的な指示がない変更」は避ける
6. **ドキュメント同期**: 挙動・コマンド・ディレクトリ構造を変えたら、本ファイルと `docs/` を更新する

---

## 9. 参照ドキュメント

| ドキュメント | 内容 |
|--------------|------|
| `docs/architecture.md` | Nix 構成 / モジュール責務 / フロー詳細 |
| `docs/commands.md` | 全 Make ターゲットと CI 想定の使い分け |
| `README.md` | 利用者向けの Quick Start とツール一覧 |
| `.claude/skills/*/SKILL.md` | 個別トピック（mise / pre-commit / VSCode / 各種サービス etc.） |
| `.gemini/GEMINI.md` | Gemini CLI 向けエントリポイント |
| `.cursor/rules/00_agent.mdc` | Cursor 向けルール |
| `.github/instructions/basic.instructions.md` | GitHub Copilot 向け指示 |
| `windows-ctf/README.md` | Windows CTF 環境専用ガイド |
| `nixvim/` | スタンドアロン Neovim 設定（独立 flake） |
