---
name: review-performance
description: Review for measurable regressions such as unbounded work, repeated I/O, N+1 queries, avoidable allocations in hot paths, and missing limits. Use when asked to review performance.
---

# review-performance

Review for measurable regressions such as unbounded work, repeated I/O, N+1 queries,
avoidable allocations in hot paths, and missing limits. Describe the input scale and path
that makes the impact material.

Report findings with severity, file and line evidence, impact, and an actionable remedy. If
no issue is found, say what was reviewed and that no qualifying finding was identified.

Operating rules and the full review list live in `~/.claude/CLAUDE.md` under "AI Guardrails"
(source: [ai-guardrails](https://github.com/barleytea/ai-guardrails)).
