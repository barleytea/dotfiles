---
applyTo: "**"
---

## Codex-Specific Interaction Rules

- When presenting explicit user choices, use `AskQuestionTool` whenever that tool is available.
- Do not present plain-text multiple-choice lists when `AskQuestionTool` can capture the decision.
- Use plain-text questions only for open-ended input, clarification that cannot be represented as options, or environments where `AskQuestionTool` is unavailable.
- When a tool-based choice is appropriate, keep the options mutually exclusive and concise.
