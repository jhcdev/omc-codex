---
description: "Mixed-model team: N Claude agents + M Codex agents working in parallel — each handles tasks matching its strength, cross-model review at the end"
argument-hint: "<N:claude[:type],M:codex> <task description>"
context: fork
allowed-tools: "*"
---

# Mixed-Model Team: Claude + Codex Agents

Scale both Claude and Codex agents independently.
Claude agents handle complex multi-file tasks.
Codex agents handle well-scoped independent tasks.
**Cross-model verification at the end — the model that didn't build reviews.**

## Syntax

```bash
# 3 Claude executors + 2 Codex workers
/omcx:team 3:claude:executor,2:codex implement full auth system

# 2 Claude + 1 Codex (default types)
/omcx:team 2:claude,1:codex add pagination and caching

# Claude only with Codex review (like before)
/omcx:team 3:claude:executor implement OAuth2

# Codex only with Claude review
/omcx:team 3:codex add input validation to all endpoints

# Mixed with specific Claude agent types
/omcx:team 2:claude:executor,1:claude:designer,2:codex redesign settings page
```

**Format:** `N:model[:agent-type]` separated by commas.

| Spec | Meaning |
|------|---------|
| `3:claude:executor` | 3 Claude agents, executor type |
| `2:codex` | 2 Codex workers (write-capable) |
| `1:claude:designer` | 1 Claude agent, designer type |
| `1:claude` | 1 Claude agent, auto-pick type |
| `3:codex:spark` | 3 Codex workers using spark model |

## Task Routing by Model Strength

During task decomposition, the lead assigns each subtask to the best-fit model:

| Task Characteristic | Assign To | Why |
|---------------------|-----------|-----|
| Multi-file, cross-cutting | Claude agent | Full codebase context |
| Depends on other tasks | Claude agent | Reasoning about dependencies |
| Architecture/design decisions | Claude agent | Deep reasoning |
| Well-scoped, independent | Codex worker | Fast, sandboxed |
| Single file, clear spec | Codex worker | Quick execution |
| Test writing | Either | Claude for complex, Codex for simple |
| Config/boilerplate | Codex worker | Mechanical, well-defined |

**Rule:** If unsure, assign to Claude (safer for complex work).

## Workflow

User request: $ARGUMENTS

### Step 1: Parse Team Spec

Extract from arguments:
- Claude agent count + types (e.g., `3:claude:executor`)
- Codex agent count + model (e.g., `2:codex` or `2:codex:spark`)
- Task description (remaining text after spec)

### Step 2: Plan & Decompose (Claude)

Invoke `oh-my-claudecode:plan` to:
1. Analyze the task
2. Decompose into subtasks
3. **Tag each subtask** with `model: claude` or `model: codex` based on the routing table above
4. Set dependencies between subtasks

Output: task list with model assignments.

**If Claude unavailable for planning:** Use a single Codex task to generate the plan:
```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" task --json "Decompose this task into subtasks. Tag each as 'claude' (complex/multi-file) or 'codex' (simple/scoped): $TASK"
```

### Step 3: Parallel Execution

**Launch Claude agents:**
For each Claude-tagged subtask, spawn Claude agents via `oh-my-claudecode:team`:

```
Invoke oh-my-claudecode:team with N:agent-type for Claude-tagged subtasks only.
Append: "Only work on tasks tagged model:claude. Skip codex-tagged tasks."
```

**Launch Codex agents in parallel:**
For each Codex-tagged subtask, run Codex tasks simultaneously:

```bash
# For each codex subtask, launch in parallel:
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" task --write --json --background "$SUBTASK_DESCRIPTION"
```

If M Codex agents requested, run up to M Codex tasks concurrently.
Queue remaining Codex tasks and launch as slots free up.

**Monitor both tracks:**
- Claude team: via TaskList polling
- Codex jobs: via `/codex:status` polling

### Step 4: Cross-Model Verification

**Key principle: the model that DIDN'T build a piece reviews it.**

**For Claude-built code → Codex reviews:**
```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" review --wait --json
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" adversarial-review --wait --json
```

**For Codex-built code → Claude reviews:**
Use `oh-my-claudecode:code-reviewer` + `oh-my-claudecode:architect` agents.

**For mixed output:** Run both reviewers on the combined diff.

### Step 5: Fix Loop

Route findings to the appropriate model:

| Finding Source | Finding Type | Fix By |
|----------------|-------------|--------|
| Codex found in Claude's code | Simple (1-2 files) | Codex rescue |
| Codex found in Claude's code | Complex | Claude team-fix |
| Claude found in Codex's code | Any | Codex rescue --resume |
| Either found in mixed code | Complex | Claude |
| Either found in mixed code | Simple | Codex |

Re-verify after fixes. Max 3 fix cycles.

### Step 6: Final Report

```
## Mixed-Model Team Complete

### Team Composition
- Claude agents: N × [types]
- Codex agents: M

### Task Distribution
- Claude tasks: X (complex/multi-file)
- Codex tasks: Y (scoped/independent)

### Build Results
- Claude: [files changed, iterations]
- Codex: [files changed, job IDs]

### Cross-Model Verification
- Codex reviewed Claude's work: [verdict]
- Claude reviewed Codex's work: [verdict]
- Fix cycles: N

### Result
- [CLEAN / SHIPPED WITH NOTES]
```

## Fallback

| Situation | Behavior |
|-----------|----------|
| Claude unavailable | All tasks route to Codex agents |
| Codex unavailable | All tasks route to Claude agents |
| Claude agent fails | Reassign that task to Codex |
| Codex agent fails | Reassign that task to Claude |
| Both unavailable | Stop and report |

## Scaling Guidelines

| Team Size | Recommended Split | Use Case |
|-----------|-------------------|----------|
| Small (3 total) | 2:claude,1:codex | Focused feature work |
| Medium (5 total) | 3:claude,2:codex | Full feature + tests |
| Large (8+ total) | 4:claude,4:codex | Large refactor/migration |
| Review-heavy | 1:claude,3:codex | Lots of independent validations |
| Build-heavy | 4:claude,1:codex | Complex interconnected work |

## Examples

```bash
# Standard mixed team
/omcx:team 3:claude:executor,2:codex implement user notification system

# Heavy build + light validation
/omcx:team 4:claude:executor,1:codex migrate database schema v2 to v3

# Heavy validation + light build
/omcx:team 1:claude:executor,3:codex add input validation to all 20 API endpoints

# Designer + executors + codex for tests
/omcx:team 1:claude:designer,2:claude:executor,2:codex build admin dashboard

# All Codex for many independent small tasks
/omcx:team 5:codex add JSDoc comments to all exported functions

# All Claude for deeply interconnected work
/omcx:team 4:claude:executor refactor the entire auth subsystem
```
