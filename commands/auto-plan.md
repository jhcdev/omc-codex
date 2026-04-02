---
description: "Claude plans & builds → Codex reviews → auto-fix loop — each model does what it's best at"
argument-hint: "<feature or task description>"
context: fork
allowed-tools: "*"
---

# Auto-Plan: Design → Build → Validate Cycle

Claude designs and implements (deep reasoning + codebase context).
Codex validates (fast structured review + adversarial challenge).
Fixes route back to the model best suited for each finding.

## Workflow

User request: $ARGUMENTS

### Phase 1: Claude Plans (deep reasoning)

Invoke `oh-my-claudecode:plan` with the user's request.
Wait for the plan to be finalized.

Save the plan output — this becomes the implementation spec.

### Phase 2: Claude Builds (multi-file context)

Claude understands the full codebase and can implement complex plans
that touch multiple files with awareness of dependencies and side effects.

Invoke `oh-my-claudecode:ralph` with:

> Implement the following plan precisely. Run tests after each step.
>
> [paste the full plan from Phase 1]

Wait for ralph to complete with passing tests.

### Phase 3: Codex Reviews (cross-model validation)

A different model reviewing catches blind spots the builder might miss.
Codex provides fast, structured review with consistent severity ratings.

Run structured review:

```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" review --wait --json
```

**If Codex fails:** fall back to `oh-my-claudecode:code-reviewer` agent.

### Phase 4: Auto-Fix Loop (route by complexity)

Parse the review result:

- If `verdict === "APPROVE"` or no `critical`/`high` findings:
  - Report success with plan summary, implementation summary, and review verdict
  - Done

- If there are `critical`/`high` findings, route by type:
  - **Quick scoped fixes** (1-2 files, clear location) → `/codex:rescue --resume`
  - **Complex fixes** (architectural, multi-file) → `oh-my-claudecode:ralph`
  - Re-run Codex review (go back to Phase 3)
  - Max 3 fix cycles

### Phase 5: Final Report

Summarize to the user:
- What was planned (Phase 1 — Claude)
- What was built (Phase 2 — Claude ralph)
- Review result (Phase 3 — Codex)
- Fixes applied and by which model (Phase 4)

## Fallback

If Codex is not installed:
- Phase 1-2: Claude (same — already Claude-primary)
- Phase 3-4: Use Claude `code-reviewer` agent instead of Codex review
