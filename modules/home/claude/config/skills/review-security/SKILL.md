---
name: review-security
description: Review for exploitable injection, authorization, secret exposure, unsafe deserialization, path traversal, and dangerous command execution. Use when asked to review security.
---

# review-security

Review for exploitable injection, authorization, secret exposure, unsafe deserialization,
path traversal, and dangerous command execution. Report only vulnerabilities with a
plausible exploit path and state the affected trust boundary.

Report findings with severity, file and line evidence, impact, and an actionable remedy. If
no issue is found, say what was reviewed and that no qualifying finding was identified.

Operating rules and the full review list live in `~/.claude/CLAUDE.md` under "AI Guardrails"
(source: [ai-guardrails](https://github.com/barleytea/ai-guardrails)).
