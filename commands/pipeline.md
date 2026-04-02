---
description: "Full autonomous pipeline: plan → build → test → review → fix — routes each phase to the model best suited for it"
argument-hint: "<feature or task description>"
context: fork
allowed-tools: "*"
---

# Pipeline: Strength-Based Autonomous Workflow

Routes each phase to the model that excels at it.
Claude handles planning, complex implementation, and debugging.
Codex handles code review, validation, and quick targeted fixes.

## Role Assignment

| Capability | Claude Code | Codex |
|------------|-------------|-------|
| Planning & architecture | **Primary** (deep reasoning) | — |
| Complex implementation | **Primary** (multi-file context) | — |
| Persistence & iteration | **Primary** (ralph loop) | — |
| Structured code review | — | **Primary** (fast, JSON output) |
| Adversarial review | — | **Primary** (skeptical stance) |
| Quick scoped fixes | — | **Primary** (sandboxed, fast) |
| Cross-model validation | Synthesis | Evidence gathering |

## Workflow

User request: $ARGUMENTS

### Phase 1: Plan (Claude — deep reasoning)

Claude excels at understanding ambiguous requirements and designing architecture.

Invoke `oh-my-claudecode:plan` with the user's request.
Output: implementation plan with clear steps.

### Phase 2: Build (Claude — complex implementation)

Claude excels at multi-file implementation with full codebase context.
Complex features need reasoning about dependencies, side effects, and integration.

Invoke `oh-my-claudecode:ralph` with:

> Implement the following plan precisely. Run tests after each major step.
>
> [paste the full plan from Phase 1]

Output: implemented and locally tested code.

### Phase 3: Review (Codex — structured validation)

Codex excels at fast, structured code review with consistent JSON output.
A different model reviewing Claude's work provides genuine cross-model validation.

Run both reviews:

**Large-repo safety:** Before calling Codex, check diff size:

```bash
DIFF_BYTES=$(git diff HEAD~1 2>/dev/null | wc -c || echo "0")
```

If diff > 500KB, use `--scope working-tree` to limit what Codex processes.

```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" review --wait --json
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" adversarial-review --wait --json
```

**If Codex fails (ENOBUFS, timeout, or not installed):** fall back to Claude agents:
- Structured review → `oh-my-claudecode:code-reviewer` agent
- Adversarial review → `oh-my-claudecode:architect` agent

The review phase **never gets skipped**.

### Phase 4: Fix (route by finding type)

Route fixes to the model best suited for each type:

**Quick scoped fixes** (single-file, clear location) → Codex:
- Invoke `/codex:rescue --resume` with the specific findings

**Complex fixes** (multi-file, architectural, logic rework) → Claude:
- Invoke `oh-my-claudecode:ralph` with the findings

Decision heuristic:
- Finding affects 1-2 files with clear file:line → Codex
- Finding is architectural, cross-cutting, or requires reasoning → Claude
- If unsure → Claude (safer for complex work)

After fixes, re-run Codex review (Phase 3 lite — structured review only).
Max 3 fix cycles.

### Phase 5: Report

Present final summary:

```
## Pipeline Complete

### Plan (Claude)
- [1-2 sentence summary of what was designed]

### Build (Claude ralph)
- [files created/modified]
- Iterations: N ralph cycles

### Review (Codex)
- Structured: [verdict] — [N findings summary]
- Adversarial: [N concerns]

### Fixes
- Quick fixes (Codex): [N items]
- Complex fixes (Claude): [N items]
- Fix cycles: N

### Result
- [overall status: CLEAN / SHIPPED WITH NOTES]
- [any remaining minor findings]
```

## Abort Conditions

Stop the pipeline and report to the user if:
- Phase 2 (build) fails after 5 ralph iterations
- Phase 4 (fix loop) exceeds 3 cycles with critical findings remaining
- Any phase throws an unrecoverable error

## Why This Routing

- **Claude plans** because it handles ambiguous requirements and complex tradeoffs
- **Claude builds** because implementation needs full codebase context and multi-file reasoning
- **Codex reviews** because a different model catches blind spots Claude might miss
- **Fixes split by complexity** because Codex is fast for surgical fixes, Claude is thorough for complex rework
