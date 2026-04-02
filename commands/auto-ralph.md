---
description: "Claude grinds (ralph) → Codex validates — keeps iterating until both agree the work is done"
argument-hint: "<task description>"
context: fork
allowed-tools: "*"
---

# Auto-Ralph: Claude Builds + Codex Validates Loop

Claude does what it's best at: persistent iteration with full context.
Codex does what it's best at: independent validation from a different perspective.
The loop continues until both models agree the work is complete.

## Role Assignment

- **Claude (ralph)**: Implementation, debugging, test fixing — deep reasoning with full codebase context
- **Codex (review)**: Independent validation — structured findings with severity ratings, edge case detection

## Workflow

1. **Claude works** via ralph with the user's task
2. When ralph believes it's done:
   - Codex reviews automatically (cross-model validation)
   - If review is **PASS** (no critical/high) → done
   - If review has **critical/high** findings → Claude fixes them via ralph
3. Repeat until both Claude AND Codex are satisfied

## Execution

User request: $ARGUMENTS

### Step 1: Claude Implements (ralph)

Invoke the `oh-my-claudecode:ralph` skill with the user's task, but append:

> After completing the task, DO NOT claim completion yet. Instead, report what you did and stop so Codex can review.

### Step 2: Codex Validates

After ralph reports completion, run Codex review with large-repo safety:

```bash
DIFF_BYTES=$(git diff HEAD~1 2>/dev/null | wc -c || echo "0")

if [ "$DIFF_BYTES" -gt 500000 ]; then
  node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" review --wait --json --scope working-tree 2>/dev/null
else
  node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" review --wait --json 2>/dev/null
fi
```

**If Codex fails:** fall back to `oh-my-claudecode:architect` agent review.

The validation step **never gets skipped**.

### Step 3: Route Findings

- No critical/high findings → report success, done
- Has critical/high findings:
  - **Quick fixes** (clear file:line, 1-2 files) → `/codex:rescue --resume` (Codex is fast for surgical fixes)
  - **Complex fixes** (multi-file, logic rework) → re-invoke ralph (Claude understands the full context)
  - After fixes, go back to Step 2

### Step 4: Safety limit

After 5 build↔review cycles, stop and report:
- What Claude accomplished
- Remaining Codex findings
- Let the user decide

## Why This Pairing

- Claude **builds** because complex tasks need multi-file reasoning and persistent iteration
- Codex **reviews** because a different model catches blind spots the builder missed
- Quick fixes go to **Codex** because it's fast and sandboxed for scoped changes
- Complex fixes go back to **Claude** because it already has full context from building
