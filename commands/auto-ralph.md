---
description: "Claude grinds (ralph) → Codex validates — with automatic Codex takeover when Claude is unavailable"
argument-hint: "<task description>"
context: fork
allowed-tools: "*"
---

# Auto-Ralph: Claude Builds + Codex Validates Loop

Claude does what it's best at: persistent iteration with full context.
Codex does what it's best at: independent validation from a different perspective.
**When Claude is unavailable, Codex takes over the build role automatically.**

## Role Assignment

- **Claude (ralph)**: Implementation, debugging, test fixing — deep reasoning with full codebase context
- **Codex (review)**: Independent validation — structured findings with severity ratings
- **Codex (fallback builder)**: Takes over implementation when Claude is unavailable

## Cross-Model Fallback

When Claude hits rate limit, quota, context limit, or any error during ralph:

1. Capture ralph's progress so far (completed steps, changed files, test status)
2. Hand off remaining work to Codex:
   ```bash
   node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" task --write --json "Continue this task. Completed so far: [progress]. Remaining: [remaining work]"
   ```
3. After Codex completes, proceed to Codex review (Step 2) as normal
4. If review finds issues and Claude is back, route complex fixes to Claude; otherwise Codex fixes

When Codex is unavailable for review:
- Fall back to `oh-my-claudecode:architect` agent review

**Work never stalls. If one model is down, the other keeps going.**

## Workflow

User request: $ARGUMENTS

### Step 1: Build (Claude → Codex fallback)

**Primary: Claude ralph**
Invoke `oh-my-claudecode:ralph` with the user's task, appending:

> After completing the task, DO NOT claim completion yet. Report what you did and stop so Codex can review.

**Fallback: Codex** — If Claude is unavailable:
Invoke `/codex:rescue --write` with the full task description.

### Step 2: Codex Validates

After build completes (by either model), run Codex review:

```bash
DIFF_BYTES=$(git diff HEAD~1 2>/dev/null | wc -c || echo "0")

if [ "$DIFF_BYTES" -gt 500000 ]; then
  node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" review --wait --json --scope working-tree 2>/dev/null
else
  node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" review --wait --json 2>/dev/null
fi
```

**Fallback: Claude architect** — If Codex is unavailable for review.

The validation step **never gets skipped**.

### Step 3: Route Findings by Model Availability & Complexity

- No critical/high findings → report success, done
- Has critical/high findings:
  - **Claude available + complex fix** → re-invoke ralph
  - **Claude available + simple fix** → `/codex:rescue --resume` (faster)
  - **Claude unavailable** → `/codex:rescue --resume` for all fixes
  - After fixes, go back to Step 2

### Step 4: Safety limit

After 5 build↔review cycles (counting both Claude and Codex iterations), stop and report:
- What was accomplished (and by which model)
- Remaining findings
- Let the user decide

## Why This Pairing

- Claude **builds** because complex tasks need multi-file reasoning and persistent iteration
- Codex **reviews** because a different model catches blind spots the builder missed
- Codex **falls back as builder** because work should never stall when Claude is rate-limited
- Complex fixes go to **Claude** when available, **Codex** when not — progress over perfection
