---
description: "Full autonomous pipeline: plan → build → test → review → fix — chains omc and Codex end-to-end"
argument-hint: "<feature or task description>"
context: fork
allowed-tools: "*"
---

# Pipeline: Autonomous End-to-End Workflow

Chains every omc + Codex capability into a single autonomous pipeline.
From idea to reviewed, tested, working code.

## Workflow

User request: $ARGUMENTS

### Phase 1: Plan (Claude Opus)

Invoke `oh-my-claudecode:plan` with the user's request.
Output: implementation plan with clear steps.

### Phase 2: Build (Codex)

Invoke `/codex:rescue --write` with the plan from Phase 1.
If Codex is unavailable, fall back to `oh-my-claudecode:ultrawork`.

Output: implemented code.

### Phase 3: Test (ralph loop)

Invoke `oh-my-claudecode:ralph` with:

> Run all tests related to the changes. Fix any failures. Repeat until all tests pass. Do not proceed until green.

Max 5 iterations. Output: passing tests.

### Phase 4: Review (Codex dual review)

Run both reviews:

```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" review --wait --json
```

```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" adversarial-review --wait --json
```

If Codex unavailable, use `oh-my-claudecode:code-reviewer` agent instead.

### Phase 5: Fix (auto-fix loop)

If reviews found `critical` or `high` severity issues:

1. Invoke `/codex:rescue --resume` with the findings (or ralph if Codex unavailable)
2. Re-run tests (Phase 3 lite — single ralph pass)
3. Re-run structured review only
4. Max 3 fix cycles

### Phase 6: Report

Present final summary:

```
## Pipeline Complete

### Plan
- [1-2 sentence summary of what was designed]

### Build
- [files created/modified by Codex]
- Builder: Codex / Claude ultrawork (fallback)

### Tests
- Status: PASS ✓
- Iterations: N ralph cycles

### Review
- Structured: [verdict] — [N findings summary]
- Adversarial: [N concerns]
- Fix cycles: N

### Result
- [overall status: CLEAN / SHIPPED WITH NOTES]
- [any remaining minor findings]
```

## Abort Conditions

Stop the pipeline and report to the user if:
- Phase 3 (tests) fails after 5 iterations
- Phase 5 (fix loop) exceeds 3 cycles with critical findings remaining
- Any phase throws an unrecoverable error

## Fallback Chain

Every phase has a Claude-only fallback:

| Phase | Primary | Fallback |
|-------|---------|----------|
| Plan | Claude Opus (omc plan) | Same |
| Build | Codex rescue | omc ultrawork |
| Test | omc ralph | Same |
| Review | Codex review + adversarial | omc code-reviewer + architect |
| Fix | Codex rescue --resume | omc ralph |

The pipeline never blocks on Codex being unavailable.
