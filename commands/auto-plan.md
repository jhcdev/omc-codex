---
description: "Claude plans & builds → Codex reviews → auto-fix — with automatic cross-model fallback when either is unavailable"
argument-hint: "<feature or task description>"
context: fork
allowed-tools: "*"
---

# Auto-Plan: Design → Build → Validate Cycle

Claude designs and implements (deep reasoning + codebase context).
Codex validates (fast structured review + adversarial challenge).
**When either model is unavailable, the other takes over automatically.**

## Cross-Model Fallback

| Phase | Primary | Fallback |
|-------|---------|----------|
| Plan | Claude Opus | Codex task |
| Build | Claude ralph | Codex rescue --write |
| Review | Codex review | Claude code-reviewer |
| Fix (simple) | Codex rescue | Claude ralph |
| Fix (complex) | Claude ralph | Codex rescue |

## Workflow

User request: $ARGUMENTS

### Phase 1: Plan

**Primary: Claude Opus** — Invoke `oh-my-claudecode:plan` with the user's request.

**Fallback: Codex** — If Claude unavailable:
```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" task --json "Design an implementation plan for: $ARGUMENTS. Output a numbered step-by-step plan."
```

Save the plan output — this becomes the implementation spec.

### Phase 2: Build

**Primary: Claude ralph** — Claude understands the full codebase and can implement complex plans.

Invoke `oh-my-claudecode:ralph` with:
> Implement the following plan precisely. Run tests after each step.
> [plan from Phase 1]

**Fallback: Codex** — If Claude unavailable (rate limit, quota, context limit):
1. Check what's already implemented (git diff)
2. Invoke `/codex:rescue --write` with remaining plan steps

### Phase 3: Review

**Primary: Codex** — A different model reviewing catches blind spots.

```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" review --wait --json
```

**Fallback: Claude** — If Codex unavailable:
Use `oh-my-claudecode:code-reviewer` agent.

### Phase 4: Auto-Fix Loop

- If `verdict === "APPROVE"` or no `critical`/`high` findings → done
- If there are findings, route by availability and complexity:
  - **Claude available + complex** → ralph
  - **Simple or Claude unavailable** → `/codex:rescue --resume`
  - Re-run review, max 3 fix cycles

### Phase 5: Final Report

Summarize:
- What was planned (Phase 1) — by Claude or Codex
- What was built (Phase 2) — by Claude or Codex
- Review result (Phase 3) — by Codex or Claude
- Fixes applied and by which model
