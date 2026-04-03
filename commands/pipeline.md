---
description: "Full autonomous pipeline for ANY task — plan → execute → verify → review → fix. Routes each phase to the best model, with automatic cross-model fallback"
argument-hint: "<feature or task description>"
context: fork
allowed-tools: "*"
---

# Pipeline: Strength-Based Autonomous Workflow

Routes each phase to the model that excels at it.
Claude handles planning, complex implementation, and debugging.
Codex handles code review, validation, and quick targeted fixes.
**When either model is unavailable, the other takes over automatically.**

## Role Assignment

| Capability | Primary | Fallback |
|------------|---------|----------|
| Planning & architecture | Claude Opus | Codex rescue |
| Complex implementation | Claude ralph | Codex rescue --write |
| Test iteration | Claude ralph | Codex rescue --write |
| Structured code review | Codex review | Claude code-reviewer |
| Adversarial review | Codex adversarial | Claude architect |
| Quick scoped fixes | Codex rescue | Claude ralph |
| Cross-model synthesis | Claude | — |

## Cross-Model Fallback Protocol

When the primary model for a phase is unavailable (rate limit, auth error, context limit, timeout, not installed, any failure):

1. **Detect failure**: Phase did not complete — check error type
2. **Capture progress**: Record what was completed so far (files changed, tests passing, remaining work from plan)
3. **Switch to fallback model**: Hand off remaining work with full context
4. **Verify after switch**: When the original model is available again, optionally verify the fallback model's work

### Claude → Codex Fallback

When Claude is unavailable (rate limit, quota exhausted, context limit, any error):

Invoke `/codex:rescue --write` with:
> Continue this work. Here's what was completed so far:
> [list of completed steps and changed files]
>
> Remaining work:
> [list of remaining steps from the plan]

### Codex → Claude Fallback

When Codex is unavailable (not installed, auth failure, ENOBUFS, timeout):

- Structured review → `oh-my-claudecode:code-reviewer` agent
- Adversarial review → `oh-my-claudecode:architect` agent
- Codex task → `oh-my-claudecode:ralph` or `oh-my-claudecode:ultrawork`

**Work never stalls. If one model is down, the other keeps going.**

## Workflow

User request: $ARGUMENTS

### Phase 1: Plan

**Primary: Claude Opus** (deep reasoning for ambiguous requirements)
Invoke `oh-my-claudecode:plan` with the user's request.

**Fallback: Codex** — If Claude unavailable:
```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" task --write --json "Design an implementation plan for: $ARGUMENTS. Output a numbered step-by-step plan with files to create/modify."
```

Output: implementation plan with clear steps.

### Phase 2: Build

**Primary: Claude ralph** (multi-file context, persistent iteration)
Invoke `oh-my-claudecode:ralph` with the plan from Phase 1.

**Fallback: Codex** — If Claude unavailable mid-build:
1. Check what steps are already done (git diff, test status)
2. Invoke `/codex:rescue --write` with remaining uncompleted steps
3. When Claude returns, optionally run a quick ralph verification pass

### Phase 3: Review

**Primary: Codex** (fast, structured, cross-model validation)

```bash
DIFF_BYTES=$(git diff HEAD~1 2>/dev/null | wc -c || echo "0")
SCOPE_FLAG=""
[ "$DIFF_BYTES" -gt 500000 ] && SCOPE_FLAG="--scope working-tree"

node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" review --wait --json $SCOPE_FLAG
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" adversarial-review --wait --json $SCOPE_FLAG
```

**Fallback: Claude** — If Codex unavailable:
- Structured review → `oh-my-claudecode:code-reviewer` agent
- Adversarial review → `oh-my-claudecode:architect` agent

The review phase **never gets skipped**.

### Phase 4: Fix (route by finding type)

**Quick scoped fixes** (1-2 files, clear location):
- Primary: Codex (`/codex:rescue --resume`)
- Fallback: Claude ralph

**Complex fixes** (multi-file, architectural):
- Primary: Claude ralph
- Fallback: Codex (`/codex:rescue --write`)

After fixes, re-run review (Phase 3 lite — structured review only).
Max 3 fix cycles.

### Phase 5: Report

```
## Pipeline Complete

### Plan
- Planner: Claude / Codex (fallback)
- [summary]

### Build
- Builder: Claude ralph / Codex (fallback)
- [files created/modified]

### Review
- Reviewer: Codex / Claude (fallback)
- Structured: [verdict]
- Adversarial: [concerns]

### Fixes
- Quick: Codex [N items] / Complex: Claude [N items]
- Fix cycles: N

### Result
- [CLEAN / SHIPPED WITH NOTES]
```

## Abort Conditions

Stop and report only when:
- **Both** Claude AND Codex are unavailable for the same phase
- Build fails after 5 iterations with both models attempted
- Fix loop exceeds 3 cycles with critical findings remaining
