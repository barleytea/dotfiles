---
name: review-code-quality
description: Review changed code for correctness regressions, error handling, data-flow mistakes, misleading naming/abstractions, and maintainability defects. Use when asked to review code quality.
---

# review-code-quality

Review changed code for correctness regressions, error handling, data-flow mistakes, and
maintainability defects that can cause incorrect behavior. Also flag naming, control flow,
or abstractions that mislead a reader about what the code actually does, and duplication or
coupling that measurably raises the cost of the next change. Cite the file and line, explain
the failing scenario, and propose a concrete fix. Do not report formatting or style
preferences.

Report findings with severity, file and line evidence, impact, and an actionable remedy. If
no issue is found, say what was reviewed and that no qualifying finding was identified.

Operating rules and the full review list live in `~/.claude/CLAUDE.md` under "AI Guardrails"
(source: [ai-guardrails](https://github.com/barleytea/ai-guardrails)).
