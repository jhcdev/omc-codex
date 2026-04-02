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
   - Run `/codex:review --wait` automatically
   - If review verdict is **PASS** (no critical/high severity findings) → done
   - If review has **critical or high severity** findings → feed findings back to ralph as the next iteration's task
3. Repeat until both ralph AND Codex review are satisfied

## Execution

User request: $ARGUMENTS

### Step 1: Run ralph

Invoke the `oh-my-claudecode:ralph` skill with the user's task, but append this instruction:

> After completing the task, DO NOT claim completion yet. Instead, report what you did and stop so Codex can review.

### Step 2: Codex Review

After ralph reports completion, run:

```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" review --wait --json
```

Parse the JSON result. Check the `verdict` field and `findings` array.

### Step 3: Evaluate

- If `verdict === "APPROVE"` or no findings with severity `critical` or `high`:
  - Report success to the user with both ralph's output and Codex review summary
  - Done

- If there are `critical` or `high` severity findings:
  - Format the findings as a fix list
  - Re-invoke ralph with: "Fix these Codex review findings: [findings list]"
  - Go back to Step 2

### Step 4: Max iterations safety

After 5 ralph↔codex cycles, stop and report:
- What ralph accomplished
- Remaining Codex findings
- Let the user decide whether to continue

## Fallback

If Codex is not installed or fails, skip the review step and run ralph normally.
Report that Codex review was skipped.
