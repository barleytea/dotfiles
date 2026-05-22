---
name: skill-eval
description: スキルのプロンプト品質を評価・チューニングする。スキルを書いたあと別のサブエージェントに実行させ、不明瞭点・自動補完箇所・達成率をレポートさせて反復改善する。Use when you want to evaluate or tune a SKILL.md prompt quality. Ref: https://zenn.dev/mizchi/articles/empirical-prompt-tuning
allowed-tools: Bash, Read, Write, Agent
---

# Skill Evaluator

スキルのプロンプト品質を実証的に評価・改善するワークフロー。

**前提**: 書いた直後の自分が最もダメな読者。別の新規エージェントに実行させることで、暗黙の前提補完に気づく。

## 手順

### Step 1: スキルとシナリオを特定する

引数の形式で SKILL.md のパスを解決する:

- `/` または `./` で始まる → パスとして解釈
  - SKILL.md を直接指していればそのまま使う
  - ディレクトリを指していれば `<dir>/SKILL.md` を使う
- それ以外 → スキル名として解釈し、以下の順で探す:
  1. カレントディレクトリの `.claude/skills/<name>/SKILL.md`
  2. `~/.claude/skills/<name>/SKILL.md`

SKILL.md を Read で読み込み、front matter の `name:` フィールドからスキル名を取得する（レポート保存先に使う）。

`scenarios.md` は SKILL.md と同じディレクトリに存在する場合のみ Read で読み込む。存在しなければユーザーに以下を確認する:
  - 典型シナリオ 1 件（最も一般的な使い方）
  - エッジケース 1〜2 件（境界値・例外的な状況）

### Step 2: サブエージェントで実行する

各シナリオに対して、**独立した新規エージェント**を起動してスキルを実行させる（学習による偽陽性を排除するため、必ず新規エージェントを使う）。

サブエージェントへの指示テンプレート:

```
以下のスキルをシナリオに沿って実行してください。

実行中に以下を必ず記録してください：
1. 不明瞭だった点 - 指示が曖昧で解釈が必要だった箇所（具体的に引用すること）
2. 自動補完した箇所 - 明示されていないが補って実行した部分
3. 実行できなかった指示 - 不可能だった、またはスキップした指示
4. 再試行した箇所 - やり直しが必要だった操作とその理由

---
## スキル内容
<SKILL.md の全文をここに貼り付ける>

---
## シナリオ
<シナリオの説明をここに貼り付ける>
---

実行完了後、以下のフォーマットでレポートしてください：

### 実行結果
- 完了/部分完了/失敗

### 要件達成率
- 要件ごとに達成/未達を列挙
- 総合達成率: XX%

### 不明瞭点
- （具体的に、SKILL.md のどの記述が曖昧だったか引用して説明）

### 自動補完
- （明示されていないが補って実行した部分）

### 実行不可
- （スキップした指示とその理由）
```

### Step 3: レポートを収集・保存する

各シナリオのサブエージェントのレポートを統合し、以下のパスに保存:

```
~/.claude/skill-eval/<skill-name>/<YYYY-MM-DDTHH-MM>.md
```

保存フォーマット:

```markdown
# Skill Eval: <skill-name>
Date: <ISO timestamp>
Iteration: <N> (前回のレポートファイル数 + 1)

## Summary
- Overall Achievement: XX%
- New Issues Found: N 件

## Scenario Results

### Scenario 1: <シナリオ名>
Achievement: XX%

#### 不明瞭点
- ...

#### 自動補完
- ...

#### 実行不可
- ...

## Improvement Suggestions (優先度順)
1. [HIGH] ...
2. [MED] ...

## Convergence Status
- 前回比達成率: +XX%
- 新規指摘件数: N 件
- 判定: 収束 / 継続
```

ディレクトリが存在しなければ作成する:

```bash
mkdir -p "${HOME}/.claude/skill-eval/${SKILL_NAME}"
```

### Step 4: 改善を提案する

レポートを読んで、以下の優先順位で改善点を提案する:

1. **複数シナリオで共通する不明瞭点** → 最優先
2. **実行できなかった指示** → 削除または明確化
3. **自動補完が多い箇所** → 明示的な指示を追加

**重要**: 1 回の修正では 1 件の指摘のみを修正する。複数を一度に変えると何が効いたか分からなくなる。

### Step 5: 収束を判定する

過去のレポートファイルを参照し、以下の条件が揃えば収束と判定:

- 連続 2 回の評価で新規指摘がゼロ
- 達成率の変動が ±3pt 以下

収束していれば「スキルの品質は十分です」と報告する。収束していなければ、次の修正を行って再評価を促す。

---

## 使い方の例

```
# グローバルスキル（名前指定）
/skill-eval generate-commit-msg

# 別プロジェクトのスキル（パス指定）
/skill-eval ./path/to/project/.claude/skills/my-skill/SKILL.md
/skill-eval /absolute/path/to/SKILL.md

# ディレクトリ指定
/skill-eval ./path/to/project/.claude/skills/my-skill/
```

scenarios.md がない場合はインタラクティブに確認する。
