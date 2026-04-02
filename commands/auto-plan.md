---
description: "Full cycle: Claude plans → Codex builds → Codex reviews → auto-fix loop until clean"
argument-hint: "<feature or task description>"
context: fork
allowed-tools: "*"
---

# Auto-Plan: Plan → Build → Review → Fix Cycle

Claude Opus designs the architecture, Codex implements it, Codex reviews, and issues are auto-fixed.

## Workflow

User request: $ARGUMENTS

### Phase 1: Claude Plans

Invoke `oh-my-claudecode:plan` with the user's request.
Wait for the plan to be finalized.

Save the plan output — this becomes the implementation spec for Codex.

### Phase 2: Codex Builds

Invoke `/codex:rescue --write` with:

> Implement the following plan. Follow it precisely.
>
> [paste the full plan from Phase 1]

Wait for Codex to complete the implementation.

### Phase 3: Codex Reviews

Run structured review:

```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" review --wait --json
```

### Phase 4: Auto-Fix Loop

Parse the review result:

- If `verdict === "APPROVE"` or no `critical`/`high` findings:
  - Report success with plan summary, implementation summary, and review verdict
  - Done

- If there are `critical`/`high` findings:
  - Invoke `/codex:rescue --resume` with: "Fix these review findings: [findings]"
  - Re-run review (go back to Phase 3)
  - Max 3 fix cycles

### Phase 5: Final Report

Summarize to the user:
- What was planned (Phase 1)
- What was built (Phase 2)
- Review result (Phase 3)
- Any remaining findings

## Fallback

If Codex is not installed:
- Phase 1: Claude plans (same)
- Phase 2: Use `oh-my-claudecode:ultrawork` instead of Codex rescue
- Phase 3-4: Skip Codex review, use Claude code-reviewer agent instead
