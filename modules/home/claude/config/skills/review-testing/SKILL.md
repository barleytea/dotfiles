---
name: review-testing
description: Review whether changed behavior is covered by the smallest meaningful existing tests, flagging concrete untested failure modes. Use when asked to review test coverage.
---

# review-testing

Review whether changed behavior is covered by the smallest meaningful existing tests. Flag
missing tests only when an untested failure mode is concrete and important. State the test
scenario that proves the issue.

Report findings with severity, file and line evidence, impact, and an actionable remedy. If
no issue is found, say what was reviewed and that no qualifying finding was identified.

Operating rules and the full review list live in `~/.claude/CLAUDE.md` under "AI Guardrails"
(source: [ai-guardrails](https://github.com/barleytea/ai-guardrails)).
