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

## Important Notes

### ツール実行時の注意事項（サンドボックス）

Bash tool はサンドボックス上で実行されるため、ファイルアクセスや
ネットワーク接続がエラーになることがある。
そのような状況では、自動的に解決を試みず、ユーザーに状況を説明して指示を仰ぐこと。

### gh コマンドの認証（サンドボックス回避）

サンドボックスは `~/.config/gh` へのアクセスを拒否するため、
`GH_CONFIG_DIR=~/.config/github-cli` を `settings.json` の `env` に設定済み。
`~/.config/github-cli` は denyOnly に含まれないため読み取り可能。

- `nixos-rebuild switch` 時に `~/.config/github-cli/config.yml` が自動生成される
- 認証は `GH_TOKEN` 環境変数で行う
- `dangerouslyDisableSandbox: true` は不要

```bash
# ~/.zshrc_local に追記（既存の .zshrc が source している）
# シークレットの管理方法はOSによって異なる（macOS: Keychain、Linux: pass/gpg等）
export GH_TOKEN="ghp_xxxx"  # 実際のトークンに置き換え
```

Claude Code はシェルの環境変数を継承するため、
`GH_TOKEN` が設定されたシェルから起動すれば `gh` コマンドが正常に動作する。
トークンは dotfiles（Nix 管理ファイル）には書かず、環境変数として引き継ぐ。
