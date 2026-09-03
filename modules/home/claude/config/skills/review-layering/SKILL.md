---
name: review-layering
description: Review whether responsibilities sit in the layer that owns them — DDD/domain logic leaking into controllers or ORM models, invariants enforced outside their aggregate, dependencies pointing outward. Use when asked to review layering or architecture boundaries.
---

# review-layering

Review whether each responsibility sits in the layer that owns it: business rules leaking
into controllers or ORM models, persistence or transport detail reaching domain code,
invariants enforced outside their aggregate, and dependencies pointing outward. Report only
misplacements with a concrete correctness, maintenance, or testability cost, and name the
layer that should hold the logic.

Report findings with severity, file and line evidence, impact, and an actionable remedy. If
no issue is found, say what was reviewed and that no qualifying finding was identified.

Operating rules and the full review list live in `~/.claude/CLAUDE.md` under "AI Guardrails"
(source: [ai-guardrails](https://github.com/barleytea/ai-guardrails)).
