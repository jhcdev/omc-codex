---
description: "Race: same task to Claude and Codex in parallel — compare results, pick the best implementation or merge the strengths of both"
argument-hint: "<task description>"
context: fork
allowed-tools: "*"
---

# Race: Dual-Model Parallel Execution

Give the exact same task to Claude and Codex simultaneously.
Compare both implementations. Pick the best one, or merge the best parts of each.
**Two different models solving the same problem find different solutions.**

## Why This Matters

- Claude and Codex have different reasoning patterns and blind spots
- Running both in parallel costs time but not much more than running one
- For critical code, a second implementation perspective catches issues before they ship
- Sometimes Codex finds a simpler solution; sometimes Claude finds the edge cases

## When to Use

- **Critical implementations** where correctness matters more than speed
- **You're unsure** which approach is better and want to compare
- **Complex algorithms** where different solutions may have different tradeoffs
- **Refactoring** where you want to see two different restructuring approaches

## Workflow

User request: $ARGUMENTS

### Step 1: Launch Both in Parallel

**Claude track** (background):
Launch an `oh-my-claudecode:executor` agent (model: opus) with the task:

```
Agent(subagent_type="oh-my-claudecode:executor", model="opus", isolation="worktree",
  prompt="Implement this task in an isolated worktree: $ARGUMENTS")
```

**Codex track** (parallel):
```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" task --write --json "$ARGUMENTS"
```

Both run simultaneously. Neither knows about the other.

### Step 2: Collect Results

Wait for both to complete. Capture:

**From Claude:**
- Files changed (git diff in worktree)
- Implementation approach summary
- Test results if applicable

**From Codex:**
- Files changed (Codex touched files list)
- Implementation output
- Any test results

### Step 3: Compare & Judge

Use Claude to analyze both implementations side by side:

```
## Race Results

### Claude Implementation
- Approach: [summary]
- Files changed: [list]
- Strengths: [what Claude did well]
- Weaknesses: [concerns]

### Codex Implementation
- Approach: [summary]
- Files changed: [list]
- Strengths: [what Codex did well]
- Weaknesses: [concerns]

### Comparison
| Criterion | Claude | Codex |
|-----------|--------|-------|
| Correctness | [rating] | [rating] |
| Completeness | [rating] | [rating] |
| Code quality | [rating] | [rating] |
| Simplicity | [rating] | [rating] |
| Edge cases | [rating] | [rating] |

### Recommendation
- **Winner**: [Claude / Codex / Merge]
- **Reason**: [why]
```

### Step 4: Apply Decision

Ask the user with AskUserQuestion:

- **Apply Claude's implementation** — Use Claude's version from worktree
- **Apply Codex's implementation** — Use Codex's version
- **Merge best of both** — Claude synthesizes the strongest parts of each
- **Show me the diffs** — Display both diffs for manual decision

If "Merge best of both" is chosen:
1. Claude reads both implementations
2. Produces a merged version taking the best approach/patterns from each
3. Runs Codex review on the merged result for final validation

### Step 5: Validate Winner

After applying the chosen implementation:
- Run relevant tests
- Quick Codex structured review (if Claude's code was chosen — cross-model check)
- Quick Claude review (if Codex's code was chosen — cross-model check)

The losing model always reviews the winning model's code for a final safety net.

## Fallback

| Situation | Behavior |
|-----------|----------|
| Claude unavailable | Only Codex runs, apply its result directly |
| Codex unavailable | Only Claude runs, apply its result directly |
| Both fail | Report errors, ask user what to do |
| One finishes much faster | Wait for both (max 10 min timeout per track) |

## Examples

```bash
# Critical algorithm — want two perspectives
/omcx:race implement rate limiter with sliding window and token bucket fallback

# Unsure about approach — let both models try
/omcx:race refactor the payment module to support multiple providers

# Want the simplest correct solution
/omcx:race add input validation to all API endpoints
```

## Notes

- Race uses `isolation: "worktree"` for Claude so both can modify files without conflict
- Codex runs in its own sandbox
- Neither implementation is applied until the user chooses
- The comparison is done by Claude (synthesis is Claude's strength)
- Race is most valuable for tasks with multiple valid approaches
