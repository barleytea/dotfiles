# Principles

## Core

- Don't hold back. Give it your all.
- Always Think in English, but respond in Japanese.
- For maximum efficiency, whenever you need to perform multiple independent operations, invoke all relevant tools simultaneously rather than sequentially.
- MUST use subagents for complex problem verification
- After receiving tool results, carefully reflect on their quality and determine optimal next steps before proceeding. Use your thinking to plan and iterate based on this new information, and then take the best next action.

## Workflow Structure
- Follow Explore-Plan-Code-Commit approach: 理解→計画→実装→コミット
- Always read and understand existing code before making changes
- Create detailed plans before implementation
- Use iterative approaches
- Course-correct early and frequently
- After completing code changes, always suggest a commit message following gitmoji + conventional commits format (e.g. `feat: :sparkles: add feature`) at the end of your response

## Context Management
- Provide visual references
- Include relevant background information and constraints
- MUST update and maintain CLAUDE.md files for persistent project context
- Document project-specific patterns and conventions

## Problem-Solving Approach
- Leverage thinking capabilities for complex multi-step reasoning
- Focus on understanding problem requirements rather than just passing tests
- Use test-driven development

## Tool and Resource Optimization
- Optimize tool usage with parallel calling for maximum efficiency
- Use subagents for complex problem verification
- When you need the user to choose from explicit options, use `AskQuestionTool` instead of presenting plain-text multiple-choice lists.
- Use plain-text questions only for open-ended input or when `AskQuestionTool` is unavailable.

## Agent Model Strategy
- **Fable / Opus をメインセッションとして使う場合**: 戦略立案・監査・レビュー・オーケストレーションに専念し、実作業（コード生成・コマンド実行・ファイル編集・情報収集）は Sonnet サブエージェント（`model: claude-sonnet-4-6`）に切り出して実行させる。
- **例外**: 難易度が特に高いと判断した実作業はメインセッションで直接行ってよい。
- サブエージェントを起動する際は Agent ツールの `model` パラメータに `"sonnet"` を明示する（省略するとメインセッションのモデルを継承してしまう）。
