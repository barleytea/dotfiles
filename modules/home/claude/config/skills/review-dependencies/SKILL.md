---
name: review-dependencies
description: Review dependency additions and upgrades for unnecessary scope, abandoned packages, known security risk, license incompatibility, and lockfile inconsistency. Use when asked to review dependency changes.
---

# review-dependencies

Review dependency additions and upgrades for unnecessary scope, abandoned packages, known
security risk, license incompatibility, and lockfile inconsistency. Require evidence before
claiming a vulnerability or incompatibility.

Report findings with severity, file and line evidence, impact, and an actionable remedy. If
no issue is found, say what was reviewed and that no qualifying finding was identified.

Operating rules and the full review list live in `~/.claude/CLAUDE.md` under "AI Guardrails"
(source: [ai-guardrails](https://github.com/barleytea/ai-guardrails)).
