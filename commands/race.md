---
description: "Race: N Claude agents vs M Codex agents solve the same task in parallel — compare all results, pick the best or merge strengths"
argument-hint: "<N:claude,M:codex> <task description>"
context: fork
allowed-tools: "*"
---

# Race: Multi-Agent Dual-Model Competition

Scale both Claude and Codex racers independently.
Each agent solves the same task independently in an isolated environment.
Compare all results. Pick the best, or merge the strongest parts.
**More racers = more solution diversity = higher chance of finding the optimal approach.**

## Syntax

```bash
# 2 Claude vs 2 Codex (4 parallel attempts)
/omcx:race 2:claude,2:codex implement rate limiter with sliding window

# 1 Claude vs 1 Codex (classic head-to-head)
/omcx:race 1:claude,1:codex refactor payment module

# 3 Claude vs 1 Codex (more Claude diversity)
/omcx:race 3:claude,1:codex implement caching strategy

# 1 Claude vs 3 Codex (more Codex diversity)
/omcx:race 1:claude,3:codex add input validation to user endpoints

# Default: 1:claude,1:codex if no spec given
/omcx:race implement search with fuzzy matching
```

**Format:** `N:claude,M:codex` — each agent runs independently in isolation.

## Why Multiple Racers?

| Racers | Benefit |
|--------|---------|
| 1 vs 1 | Basic comparison — two perspectives |
| 2 vs 2 | Solution diversity — 4 different approaches |
| 3 vs 1 | Deep exploration — Claude tries 3 strategies, Codex provides contrast |
| 1 vs 3 | Speed variants — Codex tries 3 fast approaches, Claude provides depth |

Each racer may:
- Choose a different algorithm or data structure
- Handle edge cases differently
- Organize code differently
- Make different tradeoff decisions

## Workflow

User request: $ARGUMENTS

### Step 1: Parse Race Spec

Extract:
- Claude racer count N (default: 1)
- Codex racer count M (default: 1)
- Task description

### Step 2: Launch All Racers in Parallel

**Claude racers** — each in an isolated worktree:

For each Claude racer (1..N), launch simultaneously:
```
Agent(subagent_type="oh-my-claudecode:executor", model="opus", isolation="worktree",
  name="claude-racer-{i}",
  prompt="Implement this task independently. Do not coordinate with other agents.
  Find the best approach YOU can think of: $TASK")
```

**Codex racers** — each as a separate background task:

For each Codex racer (1..M), launch simultaneously:
```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" task --write --background --json \
  "Implement this task. Find the best approach: $TASK"
```

All N+M racers run simultaneously. None knows about the others.

### Step 3: Collect All Results

Wait for all racers (max 10 min timeout per racer).

For each racer, capture:
- Files changed (diff)
- Implementation approach (summary)
- Test results (if applicable)
- Lines of code / complexity

### Step 4: Tournament Comparison

Claude analyzes all N+M results in a structured comparison:

```
## Race Results: N+M Implementations

### Racer Summaries

| # | Model | Approach | Files | LoC | Tests |
|---|-------|----------|-------|-----|-------|
| 1 | Claude-1 | [approach] | [N] | [N] | [pass/fail] |
| 2 | Claude-2 | [approach] | [N] | [N] | [pass/fail] |
| 3 | Codex-1 | [approach] | [N] | [N] | [pass/fail] |
| 4 | Codex-2 | [approach] | [N] | [N] | [pass/fail] |

### Head-to-Head Comparison

| Criterion | Claude-1 | Claude-2 | Codex-1 | Codex-2 |
|-----------|----------|----------|---------|---------|
| Correctness | ★★★ | ★★☆ | ★★★ | ★★☆ |
| Completeness | ★★★ | ★★★ | ★★☆ | ★★☆ |
| Code quality | ★★☆ | ★★★ | ★★☆ | ★★★ |
| Simplicity | ★★☆ | ★☆☆ | ★★★ | ★★★ |
| Edge cases | ★★★ | ★★☆ | ★☆☆ | ★★☆ |
| Performance | ★★☆ | ★★★ | ★★★ | ★★☆ |

### Best Parts of Each
- Claude-1: [strongest aspect]
- Claude-2: [strongest aspect]
- Codex-1: [strongest aspect]
- Codex-2: [strongest aspect]

### Recommendation
- **Winner**: [racer ID]
- **Reason**: [why this one is best overall]
- **Merge opportunity**: [which parts from other racers could improve the winner]
```

### Step 5: User Decision

Ask with AskUserQuestion:

- **Apply [winner]'s implementation** — Use the top-ranked result
- **Merge best of all** — Claude takes the strongest patterns from each racer and produces an optimal merged version
- **Show me all diffs** — Display every racer's diff for manual comparison
- **Re-race with different prompt** — Try again with refined instructions

If "Merge best of all" is chosen:
1. Claude reads all implementations
2. Produces a merged version combining the best approach, patterns, and edge case handling
3. The non-Claude model reviews the merge (Codex if Claude merged, or vice versa)

### Step 6: Validate Winner

After applying the chosen implementation:
- Run all relevant tests
- **Cross-model review**: the model family that DIDN'T produce the winning code reviews it
- This ensures the winner gets checked by a different perspective

## Fallback

| Situation | Behavior |
|-----------|----------|
| Claude unavailable | Only Codex racers run |
| Codex unavailable | Only Claude racers run |
| One racer fails | Compare remaining racers |
| All racers fail | Report errors, ask user to retry |
| One racer much slower | Don't wait forever — 10 min timeout, compare what's ready |

## Cost vs Value

| Config | Parallel Time | Value |
|--------|--------------|-------|
| 1:claude,1:codex | ~same as one | 2 perspectives |
| 2:claude,2:codex | ~same as one | 4 perspectives, high diversity |
| 3:claude,3:codex | ~same as one | 6 perspectives, maximum diversity |

Since all racers run **in parallel**, total wall time ≈ slowest single racer.
The cost is API tokens, not time.

## Examples

```bash
# Classic head-to-head
/omcx:race 1:claude,1:codex implement JWT auth middleware

# Tournament: 4 racers compete
/omcx:race 2:claude,2:codex build a connection pool manager

# Claude diversity: 3 different Claude approaches + 1 Codex baseline
/omcx:race 3:claude,1:codex design the caching architecture

# Speed contest: many Codex attempts + 1 deep Claude attempt
/omcx:race 1:claude,3:codex add error handling to all API routes

# Maximum diversity for critical code
/omcx:race 3:claude,3:codex implement the transaction reconciliation engine
```
