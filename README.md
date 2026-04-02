# omc-codex

> Bridge between oh-my-claudecode and OpenAI Codex — one command chains Claude planning, Codex building, structured reviews, and auto-fixes.

## Why omc-codex?

Claude and Codex each have strengths. This plugin **chains them automatically** so you don't have to:

```bash
# One command: Claude plans → Codex builds → tests → reviews → fixes
/omcx:pipeline implement user notification system with email and slack

# Ralph grinds + Codex validates in a loop until both are satisfied
/omcx:auto-ralph fix all TypeScript errors and make tests pass

# Claude designs, Codex implements, Codex reviews, auto-fixes
/omcx:auto-plan add refund feature to payment system

# Cross-model validation after any work
/omcx:auto-validate
```

**Without this plugin** you'd manually copy-paste between Claude Code and Codex CLI. **With it**, everything flows in one session — and falls back to Claude-only agents if Codex isn't installed.

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

# 5. Run your first auto-chaining pipeline:
/omcx:pipeline add search feature to the API
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

## Auto-Chaining Commands

The core of this plugin. Each command automatically chains omc skills with Codex actions.

### `/omcx:pipeline` — Full Autonomous Delivery

Plan → build → test → review → fix. Idea to working, reviewed code in one command.

```bash
/omcx:pipeline implement user notification system with email and slack
/omcx:pipeline add rate limiting to all public API endpoints
/omcx:pipeline migrate payment module from Stripe v2 to v3
```

**What happens:**
1. Claude Opus plans the architecture
2. Codex implements the plan
3. omc ralph runs tests until green
4. Codex runs structured + adversarial review
5. Auto-fixes any critical/high findings
6. Reports final summary

### `/omcx:auto-ralph` — Grind + Validate Loop

Ralph persistence loop with automatic Codex review. Keeps going until tests pass AND review is clean.

```bash
/omcx:auto-ralph fix all TypeScript errors and make tests pass
/omcx:auto-ralph implement retry logic for all API calls
/omcx:auto-ralph refactor the auth module to use JWT
```

**What happens:**
1. Ralph grinds on the task
2. When ralph thinks it's done → Codex reviews
3. If review has critical findings → ralph fixes them
4. Repeats until both are satisfied (max 5 cycles)

### `/omcx:auto-plan` — Design to Delivery

Claude plans → Codex builds → Codex reviews → auto-fix cycle.

```bash
/omcx:auto-plan add refund feature to payment system
/omcx:auto-plan implement search API with elasticsearch
/omcx:auto-plan build admin dashboard for user management
```

**What happens:**
1. Claude Opus designs the architecture
2. Codex implements based on the plan
3. Codex runs structured review
4. Auto-fixes review findings (max 3 cycles)

### `/omcx:auto-validate` — Cross-Model QA

Run after any workflow. Two Codex reviews + Claude synthesis into prioritized action plan.

```bash
/omcx:auto-validate
/omcx:auto-validate auth flow and session handling
/omcx:auto-validate database query performance
```

**What happens:**
1. Codex structured review (implementation bugs)
2. Codex adversarial review (design weaknesses)
3. Claude synthesizes both into fix-now / fix-later action plan
4. Offers auto-fix, manual fix, or ralph fix

### Command Selection Guide

| What you need | Command | Example |
|---------------|---------|---------|
| Build a feature end-to-end | `/omcx:pipeline` | `/omcx:pipeline add OAuth2 login` |
| Fix something + validate | `/omcx:auto-ralph` | `/omcx:auto-ralph fix failing tests` |
| Design + implement + review | `/omcx:auto-plan` | `/omcx:auto-plan add caching layer` |
| Quality check after work | `/omcx:auto-validate` | `/omcx:auto-validate` |

---

## Manual Commands

For fine-grained control, use individual commands and chain them yourself.

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

## Manual Combo Patterns

Chain omc skills with omcx commands for custom workflows.

### Pattern 1: Plan → Build → Review

```bash
/oh-my-claudecode:plan "add refund feature"
/omcx:rescue --write implement refund feature per the plan above
/omcx:review --wait
/omcx:rescue --resume fix the issues from the review
```

### Pattern 2: Build → Verify Loop

```bash
/omcx:rescue --write implement caching layer with Redis
/oh-my-claudecode:ralph "make all caching tests pass"
```

### Pattern 3: Parallel Work

```bash
/omcx:review --background
/oh-my-claudecode:team 2:executor "refactor module A, test module B"
/omcx:result
```

### Pattern 4: Investigate → Fix → Gate

```bash
/omcx:setup --enable-review-gate
/oh-my-claudecode:deep-dive "why is API response > 3 seconds"
/omcx:rescue --write optimize the N+1 query
# Review gate fires on session end
```

---

## Without Codex Installed

Every command gracefully falls back:

| Situation | Behavior |
|-----------|----------|
| Codex not installed | Uses Claude agents instead |
| Codex not authenticated | Prompts `!codex login` + Claude fallback |
| Codex runtime error | Reroutes to Claude |
| No omc either | Manual commands still work standalone |

---

## Architecture

```
┌──────────────────────────────────────────────────┐
│  Claude Code Session                              │
│                                                   │
│  ┌───────────┐  ┌─────────────┐  ┌────────────┐ │
│  │ omc       │  │ omcx        │  │ Codex CLI  │ │
│  │           │  │ (bridge)    │  │            │ │
│  │ plan ─────┼──┼→ rescue ────┼──┼→ implement │ │
│  │ ralph ────┼──┼→ review ────┼──┼→ validate  │ │
│  │ team ─────┼──┼→ adv-review ┼──┼→ challenge │ │
│  │ autopilot │  │ gate ───────┼──┼→ enforce   │ │
│  │ deep-dive │  │             │  │            │ │
│  │           │  │  auto-ralph │  │            │ │
│  │           │  │  auto-plan  │  │            │ │
│  │           │  │  auto-val   │  │            │ │
│  │           │  │  pipeline   │  │            │ │
│  │           │  │  (fallback) │  │            │ │
│  │           │  │  → Claude ──┼──┘            │ │
│  └───────────┘  └─────────────┘  └────────────┘ │
└──────────────────────────────────────────────────┘
```

## What This Adds (beyond omc alone)

| Capability | omc only | omc + omcx |
|------------|----------|------------|
| Code review | Claude text review | Codex structured JSON (severity/file/line/confidence) |
| Design validation | Manual prompting | Adversarial review with dedicated prompts |
| Review enforcement | None | Stop-time review gate (BLOCK/ALLOW) |
| Task delegation | Claude agents | Codex + Claude (cross-model) |
| Thread continuity | Per-session | `--resume` across Codex threads |
| Auto-chaining | Manual multi-step | One command: pipeline, auto-ralph, auto-plan |
| Failure handling | N/A | Graceful fallback to Claude agents |

## File Structure

```
omc-codex/
├── .claude-plugin/              # Plugin + marketplace metadata
├── commands/                    # /omcx:* commands
│   ├── pipeline.md              # Full autonomous pipeline
│   ├── auto-ralph.md            # Ralph + Codex review loop
│   ├── auto-plan.md             # Plan → build → review → fix
│   ├── auto-validate.md         # Dual review + synthesis
│   ├── review.md                # Structured code review
│   ├── adversarial-review.md    # Adversarial review
│   ├── rescue.md                # Task delegation
│   ├── setup.md                 # Setup & review gate
│   ├── status.md                # Job status
│   ├── result.md                # Job results
│   └── cancel.md                # Cancel jobs
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
