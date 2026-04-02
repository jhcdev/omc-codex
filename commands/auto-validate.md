---
description: "Cross-model validation: Codex reviews → Claude synthesizes — with fallback when either model is unavailable"
argument-hint: "[focus area]"
context: fork
allowed-tools: "*"
---

# Auto-Validate: Cross-Model Quality Gate

Codex does what it's best at: fast structured analysis + adversarial edge-case hunting.
Claude does what it's best at: synthesis, prioritization, and decision-making.
**When either model is unavailable, the other covers both roles.**

## Cross-Model Fallback

| Phase | Primary | Fallback |
|-------|---------|----------|
| Structured review | Codex review | Claude code-reviewer |
| Adversarial review | Codex adversarial | Claude architect |
| Synthesis | Claude | Codex task (summary prompt) |
| Auto-fix (simple) | Codex rescue | Claude ralph |
| Auto-fix (complex) | Claude ralph | Codex rescue |

## Workflow

User request: $ARGUMENTS

### Step 1: Structured Review (implementation focus)

**Primary: Codex** — Fast, consistent structured output.

```bash
DIFF_BYTES=$(git diff HEAD~1 2>/dev/null | wc -c || echo "0")
SCOPE_FLAG=""
[ "$DIFF_BYTES" -gt 500000 ] && SCOPE_FLAG="--scope working-tree"

node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" review --wait --json $SCOPE_FLAG
```

**Fallback: Claude** — `oh-my-claudecode:code-reviewer` agent.

Save as `structured_review`.

### Step 2: Adversarial Review (design focus)

**Primary: Codex** — Skeptical stance, edge case finding.

```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" adversarial-review --wait --json $SCOPE_FLAG $ARGUMENTS
```

**Fallback: Claude** — `oh-my-claudecode:architect` agent.

Save as `adversarial_review`.

### Step 3: Synthesis (reasoning + prioritization)

**Primary: Claude** — Deep reasoning merges both reports.

Deduplicate, assess actual impact, rank by severity:

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
- Structured: X findings (Y critical, Z high)
- Adversarial: X concerns
- Overall: PASS / NEEDS WORK / BLOCK
```

**Fallback: Codex** — If Claude is unavailable for synthesis:
```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" task --json "Merge these two code review reports into a single prioritized action list. Deduplicate overlapping findings. Report 1: [structured_review]. Report 2: [adversarial_review]"
```

### Step 4: Route Fixes by Model Availability

Use AskUserQuestion:
- **Auto-fix critical** — Simple → Codex, complex → Claude (or Codex if Claude unavailable)
- **I'll fix manually** — End here
- **Run ralph to fix all** — Claude ralph (or Codex if Claude unavailable)
