---
description: "Ralph persistence loop with automatic Codex review after each iteration — keeps grinding until tests pass AND review is clean"
argument-hint: "<task description>"
context: fork
allowed-tools: "*"
---

# Auto-Ralph: ralph + Codex Review Loop

Run omc ralph with automatic Codex structured review at the end of each iteration.
Ralph grinds until the task is done, then Codex validates. If Codex finds issues, ralph fixes them.

## Workflow

1. **Start ralph** with the user's task
2. When ralph completes an iteration and believes it's done:
   - Run Codex review automatically
   - If review verdict is **PASS** (no critical/high severity findings) → done
   - If review has **critical or high severity** findings → feed findings back to ralph as the next iteration's task
3. Repeat until both ralph AND Codex review are satisfied

## Execution

User request: $ARGUMENTS

### Step 1: Run ralph

Invoke the `oh-my-claudecode:ralph` skill with the user's task, but append this instruction:

> After completing the task, DO NOT claim completion yet. Instead, report what you did and stop so Codex can review.

### Step 2: Codex Review

After ralph reports completion, run Codex review with large-repo safety:

```bash
# Check repo size first to avoid ENOBUFS
DIFF_SIZE=$(git diff --stat HEAD~1 2>/dev/null | tail -1 | grep -oP '\d+ files? changed' | grep -oP '\d+' || echo "0")
DIFF_BYTES=$(git diff HEAD~1 2>/dev/null | wc -c || echo "0")

if [ "$DIFF_BYTES" -gt 500000 ]; then
  # Large diff: review only changed files, chunked
  CHANGED_FILES=$(git diff --name-only HEAD~1 2>/dev/null | head -50)
  echo "Large repo detected ($DIFF_BYTES bytes diff). Reviewing changed files only."
  node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" review --wait --json --scope working-tree 2>/dev/null
  REVIEW_EXIT=$?
else
  node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" review --wait --json 2>/dev/null
  REVIEW_EXIT=$?
fi
```

**If Codex review fails with ENOBUFS or any error:**

Do NOT skip review entirely. Instead, fall back to Claude architect verification:

1. Get the list of changed files: `git diff --name-only HEAD~1`
2. Invoke `oh-my-claudecode:architect` agent with: "Review these changed files for critical issues: [file list]. Check for bugs, security issues, and design problems."
3. Use the architect's findings as the review result for Step 3.

This ensures **every iteration gets reviewed** — by Codex if possible, by Claude architect if not.

### Step 3: Evaluate

- If review (Codex or architect fallback) finds no critical issues:
  - Report success to the user with both ralph's output and review summary
  - Done

- If there are critical or high severity findings:
  - Format the findings as a fix list
  - Re-invoke ralph with: "Fix these review findings: [findings list]"
  - Go back to Step 2

### Step 4: Max iterations safety

After 5 ralph↔review cycles, stop and report:
- What ralph accomplished
- Remaining findings
- Let the user decide whether to continue

## Fallback Chain

| Condition | Action |
|-----------|--------|
| Codex installed + small diff | Codex structured review (preferred) |
| Codex installed + large diff (>500KB) | Codex review with `--scope working-tree` |
| Codex fails (ENOBUFS/timeout/error) | Claude architect agent review |
| Codex not installed | Claude architect agent review |

The review step **never gets skipped**. Quality validation always happens.
