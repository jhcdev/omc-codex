# omc-codex

> Bridge between oh-my-claudecode and OpenAI Codex — use Claude and Codex together in the same session for planning, building, reviewing, and verifying.

## Why omc-codex?

Claude and Codex each have strengths. This plugin lets you **combine them in a single workflow** instead of switching between tools:

- **Claude plans, Codex builds** — Claude Opus designs the architecture, Codex implements it at scale
- **Codex reviews, Claude analyzes** — Codex runs structured JSON reviews, Claude synthesizes the findings
- **Claude debugs, Codex fixes** — Claude deep-dives into root causes, Codex applies the fix
- **Both run in parallel** — omc team spawns Claude agents while Codex reviews in the background

Without this plugin, you'd have to copy-paste context between Claude Code and Codex CLI manually. With it, everything flows in one session.

---

## Quick Start

```bash
# 1. Install Codex CLI & authenticate
npm install -g @openai/codex
codex auth login

# 2. Clone the plugin
git clone https://github.com/jhcdev/omc-codex.git ~/.claude/plugins/marketplaces/omc-codex

# 3. Add to ~/.claude/settings.json (see Configuration below)

# 4. Reload in Claude Code
/reload-plugins

# 5. Try your first combo — Claude plans, Codex builds, Codex reviews:
/oh-my-claudecode:plan "add search feature to the API"
/omcx:rescue --write implement search feature per the plan above
/omcx:review --wait
```

## Configuration

Add to `~/.claude/settings.json`:

```json
{
  "enabledPlugins": {
    "omcx@omc-codex": true
  },
  "extraKnownMarketplaces": {
    "omc-codex": {
      "source": {
        "source": "url",
        "url": "https://raw.githubusercontent.com/jhcdev/omc-codex/main/.claude-plugin/marketplace.json"
      }
    }
  }
}
```

### Prerequisites

| Tool | Required | Notes |
|------|----------|-------|
| Node.js >= 18.18 | Yes | Runtime |
| Claude Code v2.1+ | Yes | Host environment |
| oh-my-claudecode | Yes | Core orchestration layer |
| Codex CLI (`@openai/codex`) | Optional | Falls back to Claude agents if missing |

---

## Core Concept: Mix Claude + Codex in One Session

The real power isn't in individual commands — it's in **chaining omc skills with Codex actions**. Here are battle-tested patterns:

### Pattern 1: Plan → Build → Review (Full Cycle)

Claude designs, Codex implements, Codex validates. The most common workflow.

```bash
# Claude Opus architects the solution
/oh-my-claudecode:plan "add refund feature to payment system"

# Codex implements based on Claude's plan
/omcx:rescue --write implement refund feature per the plan above

# Codex structured review (JSON: severity, file, line, confidence)
/omcx:review --wait

# Codex fixes review findings
/omcx:rescue --resume fix the issues from the review above
```

**Why this works:** Claude sees the full codebase and designs holistically. Codex executes large-scale implementations faster. The structured review catches what both might miss.

### Pattern 2: Build → Verify Loop (Codex + ralph)

Codex builds the first draft, omc ralph grinds until tests pass.

```bash
# Codex creates the initial implementation
/omcx:rescue --write implement the new caching layer with Redis

# ralph loops until all tests pass (Claude agents with tool access)
/oh-my-claudecode:ralph "make all caching tests pass. fix and re-run on failure."
```

**Why this works:** Codex is fast at initial implementation. ralph's persistence loop uses Claude's MCP tool access (test execution, file reading) to iterate on fixes — something Codex alone can't do.

### Pattern 3: Dual Review (Cross-model Validation)

Two different models review the same code from different angles.

```bash
# Codex structured review (implementation bugs: null checks, race conditions)
/omcx:review --wait

# Codex adversarial review (design flaws: assumptions, rollback safety)
/omcx:adversarial-review --wait

# Claude synthesizes both reviews into a prioritized action plan
"Combine both reviews above. Prioritize by impact and split into fix-now vs fix-later."
```

**Why this works:** `review` catches implementation defects. `adversarial-review` challenges design assumptions. Claude's synthesis creates an actionable plan from two perspectives.

### Pattern 4: Parallel Work (team + Background Review)

Claude agents build while Codex reviews simultaneously.

```bash
# Start Codex background review on current changes
/omcx:review --background

# Meanwhile, omc team runs Claude agents in parallel
/oh-my-claudecode:team 2:executor "refactor module A, add tests for module B"

# After team finishes, grab the Codex review results
/omcx:result
```

**Why this works:** No idle time. Codex reviews existing code while Claude agents write new code. Both finish around the same time.

### Pattern 5: Investigate → Fix → Gate (Deep-dive + rescue)

Claude analyzes, Codex fixes, review gate prevents bad exits.

```bash
# Enable auto-review before session end
/omcx:setup --enable-review-gate

# Claude deep-dives into the root cause
/oh-my-claudecode:deep-dive "investigate why API response exceeds 3 seconds"

# Codex applies the fix based on Claude's analysis
/omcx:rescue --write optimize the N+1 query based on the analysis above

# Continue in the same Codex thread
/omcx:rescue --resume also add database index for the user_id foreign key

# Session end → review gate fires automatically (ALLOW/BLOCK)
```

**Why this works:** Claude reads the entire codebase to find root causes. Codex applies precise surgical fixes. The review gate ensures nothing ships without a final check.

### Pattern 6: Autopilot → Cross-validation

omc autopilot runs the full pipeline, Codex validates with a different model.

```bash
# Autopilot: idea → code (Claude agents only)
/oh-my-claudecode:autopilot "implement notification system — email, slack, in-app"

# Cross-validate with Codex (GPT-5.x catches what Claude missed)
/omcx:review --wait
/omcx:adversarial-review --wait focusing on failure modes when channels are down
```

**Why this works:** Autopilot uses only Claude agents, which can have blind spots. Codex's different model (GPT-5.x) provides genuine cross-model validation.

### Pattern Selection Guide

| Scenario | Pattern |
|----------|---------|
| New feature end-to-end | 1: Plan → rescue → review |
| Implementation + QA | 2: rescue → ralph verification loop |
| Pre-PR quality check | 3: Dual review pipeline |
| Maximize throughput | 4: team + background review |
| Debug performance/bugs | 5: deep-dive → rescue → review gate |
| Full auto + safety net | 6: autopilot → Codex cross-validation |

---

## Auto-Chaining Commands (NEW in v1.1)

These commands automatically chain omc skills with Codex — no manual copy-paste between tools.

### `/omcx:auto-ralph`
Ralph persistence loop + automatic Codex review. Ralph grinds until done, Codex validates, findings go back to ralph. Repeats until both are satisfied.

```bash
# Ralph fixes + Codex reviews in a loop until clean
/omcx:auto-ralph fix all TypeScript errors and make tests pass

# Ralph implements + Codex validates the implementation
/omcx:auto-ralph implement retry logic for all API calls
```

### `/omcx:auto-plan`
Full cycle: Claude plans → Codex builds → Codex reviews → auto-fix. One command, end-to-end.

```bash
# Claude designs, Codex implements, Codex reviews, auto-fixes
/omcx:auto-plan add refund feature to payment system

# Architecture to working code in one command
/omcx:auto-plan implement search API with elasticsearch
```

### `/omcx:auto-validate`
Cross-model validation after any workflow. Runs Codex structured + adversarial review, Claude synthesizes into a prioritized action plan.

```bash
# After finishing any work, cross-validate
/omcx:auto-validate

# Focus on specific area
/omcx:auto-validate auth flow and session handling
```

### `/omcx:pipeline`
Full autonomous pipeline: plan → build → test → review → fix. Chains everything end-to-end.

```bash
# Idea to reviewed, tested, working code
/omcx:pipeline implement user notification system with email and slack

# Full autonomous feature delivery
/omcx:pipeline add rate limiting to all public API endpoints
```

### Auto-Chaining vs Manual Patterns

| Command | What it chains | When to use |
|---------|---------------|-------------|
| `/omcx:auto-ralph` | ralph ↔ Codex review loop | Grinding tasks that need quality validation |
| `/omcx:auto-plan` | plan → rescue → review → fix | New features from scratch |
| `/omcx:auto-validate` | review + adversarial + synthesis | Post-work quality check |
| `/omcx:pipeline` | plan → build → test → review → fix | Full autonomous delivery |

All commands fall back to Claude-only agents if Codex is unavailable.

---

## Command Reference

### Code Review

```bash
/omcx:review --wait                  # Structured review (foreground)
/omcx:review --background            # Run in background
/omcx:review --base main             # Compare against branch
/omcx:review --scope working-tree    # Uncommitted changes only

/omcx:adversarial-review --wait      # Challenge design assumptions
/omcx:adversarial-review --wait auth flow and session handling
```

### Task Delegation

```bash
/omcx:rescue --write <task>          # Delegate with write access
/omcx:rescue <question>              # Read-only investigation
/omcx:rescue --resume <follow-up>    # Continue previous thread
/omcx:rescue --fresh <task>          # Force new thread
/omcx:rescue --background --write <task>
```

### Review Gate & Setup

```bash
/omcx:setup                          # Check CLI status + auth
/omcx:setup --enable-review-gate     # Auto-review on session end
/omcx:setup --disable-review-gate    # Disable auto-review
```

### Job Management

```bash
/omcx:status                         # List jobs
/omcx:result                         # Latest result
/omcx:cancel                         # Cancel running job
```

---

## Without Codex Installed

The plugin **doesn't break** if Codex is missing. It gracefully falls back:

| Situation | Behavior |
|-----------|----------|
| Codex not installed | Automatically uses Claude agents instead |
| Codex not authenticated | Prompts `!codex login` + offers Claude fallback |
| Codex runtime error | Returns error, omc reroutes to Claude |
| No omc either | Core commands (`/omcx:review`, `rescue`) still work standalone |

---

## Architecture

```
┌──────────────────────────────────────────────────┐
│  Claude Code Session                              │
│                                                   │
│  ┌───────────┐  ┌─────────────┐  ┌────────────┐ │
│  │ omc       │  │ omc-codex   │  │ Codex CLI  │ │
│  │           │  │ (bridge)    │  │            │ │
│  │ plan ─────┼──┼→ rescue ────┼──┼→ implement │ │
│  │ ralph ────┼──┼→ review ────┼──┼→ validate  │ │
│  │ team ─────┼──┼→ adv-review ┼──┼→ challenge │ │
│  │ autopilot │  │ gate ───────┼──┼→ enforce   │ │
│  │ deep-dive │  │             │  │            │ │
│  │           │  │  (fallback) │  │            │ │
│  │           │  │  → Claude ──┼──┘            │ │
│  └───────────┘  └─────────────┘  └────────────┘ │
│                        │                          │
│               ┌────────┴────────┐                 │
│               │ Hooks           │                 │
│               │ SessionStart    │                 │
│               │ SessionEnd      │                 │
│               │ Stop (gate)     │                 │
│               └─────────────────┘                 │
└──────────────────────────────────────────────────┘
```

## What This Adds (beyond omc alone)

| Capability | omc only | omc + codex |
|------------|----------|-------------|
| Code review | Claude text review | Codex structured JSON (severity/file/line/confidence) |
| Design validation | Manual prompting | Adversarial review with dedicated prompts |
| Review enforcement | None | Stop-time review gate (BLOCK/ALLOW) |
| Task delegation | Claude agents | Codex + Claude agents (cross-model) |
| Thread continuity | Per-session | `--resume` across Codex threads |
| Failure handling | N/A | Graceful fallback to Claude agents |

## File Structure

```
omc-codex/
├── .claude-plugin/              # Plugin + marketplace metadata
├── commands/                    # /omcx:review, rescue, setup, etc.
├── agents/codex-rescue.md       # Codex forwarding agent
├── skills/                      # Runtime, result handling, prompting
├── hooks/hooks.json             # Session lifecycle + review gate
├── scripts/                     # codex-companion runtime + lib
├── prompts/                     # Review prompt templates
├── schemas/                     # Review output JSON schema
└── README.md
```

## License

MIT — See [LICENSE](LICENSE) for details.

## Credits

Based on [openai/codex-plugin-cc](https://github.com/openai/codex-plugin-cc) by OpenAI.
Designed to work with [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode).
