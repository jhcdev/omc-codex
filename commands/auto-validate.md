---
description: "Cross-model validation: Codex reviews (structured + adversarial) → Claude synthesizes and decides — leverages each model's unique perspective"
argument-hint: "[focus area]"
context: fork
allowed-tools: "*"
---

# Auto-Validate: Cross-Model Quality Gate

Codex does what it's best at: fast structured analysis + adversarial edge-case hunting.
Claude does what it's best at: synthesis, prioritization, and decision-making.
Two different models examining the same code catches more issues than either alone.

## Role Assignment

- **Codex (structured review)**: Fast scan for bugs, security issues, correctness — JSON output with severity/file/line
- **Codex (adversarial review)**: Challenge design assumptions, find edge cases, race conditions, failure modes
- **Claude (synthesis)**: Merge both perspectives, deduplicate, prioritize by actual impact, decide next steps

## Workflow

User request: $ARGUMENTS

### Step 1: Codex Structured Review (implementation focus)

Codex excels at systematic scanning with consistent structured output.

**Large-repo safety:** Check diff size first:
```bash
DIFF_BYTES=$(git diff HEAD~1 2>/dev/null | wc -c || echo "0")
```

```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" review --wait --json
```

**If Codex fails:** fall back to `oh-my-claudecode:code-reviewer` agent.

Save the result as `structured_review`.

### Step 2: Codex Adversarial Review (design focus)

Codex's adversarial stance is excellent for skeptical analysis — it tries to break your code.

```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" adversarial-review --wait --json $ARGUMENTS
```

**If Codex fails:** fall back to `oh-my-claudecode:architect` agent.

Save the result as `adversarial_review`.

### Step 3: Claude Synthesizes (reasoning + prioritization)

Claude's deep reasoning merges both Codex reports into actionable priorities.
Deduplicate overlapping findings, assess actual impact, and rank by real-world severity.

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

### Step 4: Route Fixes by Model Strength

After presenting the report, ask the user:

Use AskUserQuestion:
- **Auto-fix critical issues** — Quick scoped fixes → Codex (`/codex:rescue --resume`), complex → Claude ralph
- **I'll fix manually** — End here
- **Run ralph to fix all** — Invoke `oh-my-claudecode:ralph` with all findings

## Why Cross-Model Validation Works

- Codex **reviews** because it provides a genuinely independent perspective from the model that built the code
- Two Codex passes (structured + adversarial) cover both **implementation bugs** and **design flaws**
- Claude **synthesizes** because prioritizing findings requires understanding the full project context and real-world impact
- Fixes **route by complexity** so each model handles what it's fastest and most reliable at
