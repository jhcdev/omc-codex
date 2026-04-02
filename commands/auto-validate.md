---
description: "Cross-model validation: Codex structured review + adversarial review + Claude synthesis — run after any workflow"
argument-hint: "[focus area]"
context: fork
allowed-tools: "*"
---

# Auto-Validate: Dual Review + Claude Synthesis

Runs Codex structured review and adversarial review in sequence, then Claude synthesizes both into a prioritized action plan. Use after any omc workflow (autopilot, ralph, ultrawork, team) to cross-validate with a different model.

## Workflow

User request: $ARGUMENTS

### Step 1: Codex Structured Review

Run implementation-focused review:

**Large-repo safety:** Check diff size first:
```bash
DIFF_BYTES=$(git diff HEAD~1 2>/dev/null | wc -c || echo "0")
```

```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" review --wait --json
```

**If Codex fails (ENOBUFS/timeout):** fall back to `oh-my-claudecode:code-reviewer` agent with `git diff --name-only HEAD~1` as input.

Save the result as `structured_review`.

### Step 2: Codex Adversarial Review

Run design-focused review. If the user provided a focus area, include it:

```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" adversarial-review --wait --json $ARGUMENTS
```

**If Codex fails:** fall back to `oh-my-claudecode:architect` agent with the same focus area.

Save the result as `adversarial_review`.

### Step 3: Claude Synthesis

Analyze both reviews and produce a unified report:

**Format:**

```
## Cross-Model Validation Report

### Critical (fix now)
- [finding] — source: structured/adversarial, severity, file:line

### Important (fix soon)
- [finding] — source, severity, file:line

### Minor (fix later)
- [finding] — source, severity

### Design Concerns
- [concern from adversarial review]

### Summary
- Structured review: X findings (Y critical, Z high)
- Adversarial review: X concerns
- Overall verdict: PASS / NEEDS WORK / BLOCK
```

### Step 4: Auto-Fix Option

After presenting the report, ask the user:

Use AskUserQuestion:
- **Auto-fix critical issues** — Invoke `/codex:rescue --resume` with the critical findings
- **I'll fix manually** — End here
- **Run ralph to fix all** — Invoke `oh-my-claudecode:ralph` with all findings as the task

## Fallback

If Codex is not installed:
- Use `oh-my-claudecode:code-reviewer` agent for structured review
- Use `oh-my-claudecode:architect` agent for design review
- Claude still synthesizes both
