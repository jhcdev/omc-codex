---
description: "Team build with Codex verification — Claude agents build in parallel, Codex reviews each piece, fix loop until both models agree"
argument-hint: "<N>:<agent-type> <task description>"
context: fork
allowed-tools: "*"
---

# Team + Codex: Cross-Model Team Verification

Claude agents build in parallel (their strength: multi-file, deep reasoning).
Codex reviews each completed piece (its strength: fast structured validation from a different perspective).
**Same-model review misses blind spots. Cross-model review catches them.**

## Why This Matters

Standard `/team` uses Claude verifier → Claude reviewing Claude's work.
This command replaces the verification stage with **Codex cross-model review**.
A different model family reviewing the code catches fundamentally different types of issues.

## Role Assignment

| Stage | Model | Why |
|-------|-------|-----|
| Plan | Claude (explore + planner) | Deep reasoning for task decomposition |
| Build | Claude agents (executor, etc.) | Multi-file context, complex implementation |
| **Verify** | **Codex (structured + adversarial)** | **Cross-model catches blind spots** |
| Fix | Route by finding: simple → Codex, complex → Claude | Each model's strength |

## Workflow

User request: $ARGUMENTS

Parse the team spec (e.g., `3:executor implement auth system`):
- Extract agent count (N) and agent type
- Extract the task description

### Stage 1: Plan (Claude)

Invoke `oh-my-claudecode:team` but **intercept after team-exec stage**.

Actually, use the standard team flow for plan + exec:

```
Invoke oh-my-claudecode:team with: "$ARGUMENTS"
```

But append this instruction to the team:

> **IMPORTANT: After team-exec completes (all tasks done), do NOT run team-verify internally.
> Instead, report completion with a summary of all changed files and what each worker did.
> External Codex verification will follow.**

### Stage 2: Codex Cross-Model Verification

After team-exec reports completion, run dual Codex review:

**Structured review** (implementation bugs):
```bash
DIFF_BYTES=$(git diff HEAD~1 2>/dev/null | wc -c || echo "0")
SCOPE_FLAG=""
[ "$DIFF_BYTES" -gt 500000 ] && SCOPE_FLAG="--scope working-tree"

node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" review --wait --json $SCOPE_FLAG
```

**Adversarial review** (design weaknesses):
```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" adversarial-review --wait --json $SCOPE_FLAG
```

**If Codex unavailable**: Fall back to Claude `code-reviewer` + `architect` agents.

### Stage 3: Route Fixes

Parse Codex findings:

- **No critical/high findings** → team output is clean, report success
- **Has findings** → route by type:

**Per-finding routing:**
- Finding affects 1-2 files with clear fix → **Codex** (`/codex:rescue --resume --write`)
- Finding is architectural or cross-cutting → **Claude** (re-invoke team with fix task)
- Claude unavailable → all fixes go to Codex

### Stage 4: Re-verify

After fixes, run Codex structured review again (lite pass).
Max 3 fix cycles.

### Stage 5: Final Report

```
## Team + Codex Complete

### Team Build
- Workers: N × [agent-type]
- Tasks completed: X/Y
- Files changed: [list]

### Codex Verification
- Structured review: [verdict] — [N findings]
- Adversarial review: [N concerns]
- Fix cycles: N

### Fixes Applied
- By Codex: [N quick fixes]
- By Claude: [N complex fixes]

### Result
- [CLEAN / SHIPPED WITH NOTES]
- [remaining minor findings if any]
```

## Fallback

| Situation | Behavior |
|-----------|----------|
| Claude unavailable during build | Team pauses, resume when available |
| Codex unavailable for review | Claude code-reviewer + architect agents |
| Claude unavailable for complex fixes | Codex handles all fixes |
| Both unavailable | Report and wait |

## Examples

```bash
# 3 executors build, Codex reviews everything
/omcx:team 3:executor implement user auth with OAuth2, JWT, and RBAC

# 2 executors build, Codex validates
/omcx:team 2:executor add pagination to all API endpoints

# Mixed: 1 designer + 2 executors build, Codex reviews
/omcx:team 1:designer,2:executor redesign the settings page with new UX
```
