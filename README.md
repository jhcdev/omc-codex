# omc-codex

> Bridge between oh-my-claudecode and OpenAI Codex — each model handles what it's best at, with automatic cross-model fallback when either is unavailable.

## Why omc-codex?

Claude and Codex each have distinct strengths. This plugin **assigns each model to the role it excels at** and **automatically falls back** when either is unavailable:

| Role | Primary | Fallback |
|------|---------|----------|
| Planning & architecture | Claude (deep reasoning) | Codex |
| Complex implementation | Claude ralph (multi-file context) | Codex rescue --write |
| Structured code review | Codex (fast, JSON output) | Claude code-reviewer |
| Adversarial review | Codex (skeptical stance) | Claude architect |
| Quick scoped fixes | Codex (sandboxed, fast) | Claude ralph |
| Synthesis & decisions | Claude (prioritization) | Codex task |

**When Claude hits rate limits, quota, or any error → Codex takes over automatically.**
**When Codex is unavailable → Claude agents cover all roles.**
**Work never stalls.**

```bash
# One command: Claude plans → Claude builds → Codex reviews → auto-fixes
/omcx:pipeline implement user notification system with email and slack

# Claude grinds + Codex validates in a loop until both agree
/omcx:auto-ralph fix all TypeScript errors and make tests pass

# Claude designs + builds, Codex reviews, auto-fixes
/omcx:auto-plan add refund feature to payment system

# Cross-model validation after any work
/omcx:auto-validate
```

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

# 5. Run your first pipeline:
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

## Strength-Based Role Routing

Each model is assigned to phases where it performs best:

### Claude Code Strengths → Builder & Thinker

- **Planning**: Handles ambiguous requirements, designs architecture with deep reasoning
- **Complex implementation**: Multi-file changes with full codebase context (ralph loop)
- **Debugging**: Reasoning chains for root-cause analysis
- **Synthesis**: Merges multiple review reports, prioritizes by real-world impact

### Codex Strengths → Reviewer & Validator

- **Structured review**: Fast scan with consistent JSON output (severity/file/line)
- **Adversarial review**: Skeptical stance, finds edge cases and failure modes
- **Quick fixes**: Sandboxed, fast execution for well-scoped changes (1-2 files)
- **Cross-model validation**: Different perspective catches blind spots

### Cross-Model Fallback

When one model is unavailable, the other covers all roles:

| Situation | Behavior |
|-----------|----------|
| Claude rate-limited | Codex takes over build/plan/fix with `--write` |
| Claude quota exhausted | Same — Codex continues all work |
| Claude context limit | Codex takes over remaining steps |
| Codex not installed | Claude agents handle review/validation |
| Codex auth failure | Claude code-reviewer + architect agents |
| Codex ENOBUFS/timeout | Claude agents as fallback reviewers |
| Both unavailable | Stop and report — manual intervention needed |

**Non-git directory support**: Codex adversarial review works in any directory, not just git repos. It walks the file tree and reviews all source files directly.

---

## Auto-Chaining Commands

The core of this plugin. Each command automatically chains the right model to the right phase.

### `/omcx:pipeline` — Full Autonomous Delivery

Plan → build → test → review → fix. Idea to working, reviewed code in one command.

```bash
/omcx:pipeline implement user notification system with email and slack
/omcx:pipeline add rate limiting to all public API endpoints
/omcx:pipeline migrate payment module from Stripe v2 to v3
```

**What happens:**
1. **Claude Opus** plans the architecture (→ Codex if Claude unavailable)
2. **Claude ralph** implements the plan (→ Codex rescue --write if rate-limited)
3. **Codex** runs structured + adversarial review (→ Claude agents if Codex unavailable)
4. **Fixes route by complexity**: simple → Codex, complex → Claude
5. Reports final summary with which model handled each phase

### `/omcx:auto-ralph` — Build + Validate Loop

Claude builds, Codex validates. Keeps going until both models agree the work is done.

```bash
/omcx:auto-ralph fix all TypeScript errors and make tests pass
/omcx:auto-ralph implement retry logic for all API calls
/omcx:auto-ralph refactor the auth module to use JWT
```

**What happens:**
1. **Claude ralph** grinds on the task (→ Codex --write if Claude unavailable)
2. When build completes → **Codex** reviews automatically
3. Critical findings → route back: complex to Claude, simple to Codex
4. Repeats until both are satisfied (max 5 cycles)

### `/omcx:auto-plan` — Design to Delivery

Claude designs and builds, Codex reviews, auto-fix cycle.

```bash
/omcx:auto-plan add refund feature to payment system
/omcx:auto-plan implement search API with elasticsearch
/omcx:auto-plan build admin dashboard for user management
```

**What happens:**
1. **Claude Opus** designs the architecture (→ Codex if unavailable)
2. **Claude ralph** implements the plan (→ Codex --write if unavailable)
3. **Codex** runs structured review (→ Claude code-reviewer if unavailable)
4. Auto-fixes review findings, routing by complexity (max 3 cycles)

### `/omcx:auto-validate` — Cross-Model QA

Two Codex reviews + Claude synthesis into prioritized action plan.

```bash
/omcx:auto-validate
/omcx:auto-validate auth flow and session handling
/omcx:auto-validate database query performance
```

**What happens:**
1. **Codex** structured review — implementation bugs (→ Claude code-reviewer)
2. **Codex** adversarial review — design weaknesses (→ Claude architect)
3. **Claude** synthesizes both into fix-now / fix-later priorities (→ Codex if unavailable)
4. Offers auto-fix, manual fix, or ralph fix

### `/omcx:team` — Mixed-Model Team

Scale Claude and Codex agents independently. Each handles tasks matching its strength.

```bash
/omcx:team 3:claude:executor,2:codex implement auth with OAuth2, JWT, RBAC
/omcx:team 2:claude,1:codex add pagination and caching
/omcx:team 1:claude:designer,2:claude:executor,2:codex build admin dashboard
/omcx:team 5:codex add JSDoc to all exported functions
```

**What happens:**
1. **Plan** decomposes task and tags each subtask: complex → Claude, scoped → Codex
2. **Claude agents** and **Codex agents** build in parallel, each on their assigned tasks
3. **Cross-model review**: Codex reviews Claude's code, Claude reviews Codex's code
4. Findings route back to the appropriate model for fixes (max 3 cycles)

**Why this matters:** Complex work goes to Claude (multi-file reasoning). Independent scoped tasks go to Codex (fast, sandboxed). Cross-model review catches blind spots that same-model review misses.

### `/omcx:race` — Multi-Agent Competition

N Claude agents vs M Codex agents solve the same task independently. Compare all results.

```bash
/omcx:race 2:claude,2:codex implement rate limiter with sliding window
/omcx:race 3:claude,1:codex design the caching architecture
/omcx:race 1:claude,3:codex add error handling to all API routes
/omcx:race implement search with fuzzy matching  # default: 1 vs 1
```

**What happens:**
1. All N+M racers implement the same task **in parallel** (isolated environments)
2. Claude compares all results in a tournament-style comparison
3. User chooses: apply winner, merge best of all, or view all diffs
4. The model that didn't produce the winner reviews it (cross-model safety net)

**When to use:** Critical code, multiple valid approaches, or when you want maximum solution diversity. All racers run in parallel — wall time ≈ slowest single racer.

### Command Selection Guide

| What you need | Command | Example |
|---------------|---------|---------|
| Build a feature end-to-end | `/omcx:pipeline` | `/omcx:pipeline add OAuth2 login` |
| Fix something + validate | `/omcx:auto-ralph` | `/omcx:auto-ralph fix failing tests` |
| Design + implement + review | `/omcx:auto-plan` | `/omcx:auto-plan add caching layer` |
| Quality check after work | `/omcx:auto-validate` | `/omcx:auto-validate` |
| Team build + cross-model review | `/omcx:team` | `/omcx:team 3:executor add auth` |
| Two models compete, best wins | `/omcx:race` | `/omcx:race implement rate limiter` |

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

**Note:** `/omcx:adversarial-review` works in non-git directories too — it scans files directly.

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

## Architecture

```
┌──────────────────────────────────────────────────────┐
│  Claude Code Session                                  │
│                                                       │
│  ┌───────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Claude    │  │ omcx         │  │ Codex CLI    │  │
│  │ (builder) │  │ (router)     │  │ (validator)  │  │
│  │           │  │              │  │              │  │
│  │ plan ─────┼──┼→ pipeline ───┼──┼→ review      │  │
│  │ ralph ────┼──┼→ auto-ralph ─┼──┼→ validate    │  │
│  │ ultrawork │  │  auto-plan ──┼──┼→ adversarial │  │
│  │ architect │  │  auto-val ───┼──┼→ challenge   │  │
│  │           │  │              │  │              │  │
│  │ ◄─────────┼──┼─ fallback ◄──┼──┼─ fallback    │  │
│  │ (covers   │  │ (routes to   │  │ (covers      │  │
│  │  Codex    │  │  available   │  │  Claude      │  │
│  │  roles)   │  │  model)      │  │  roles)      │  │
│  └───────────┘  └──────────────┘  └──────────────┘  │
└──────────────────────────────────────────────────────┘
```

## What This Adds (beyond omc alone)

| Capability | omc only | omc + omcx |
|------------|----------|------------|
| Role routing | Single model | Strength-based: Claude builds, Codex reviews |
| Code review | Claude text review | Codex structured JSON (severity/file/line) |
| Design validation | Manual prompting | Adversarial review with dedicated prompts |
| Review enforcement | None | Stop-time review gate (BLOCK/ALLOW) |
| Rate limit handling | Session stops | Auto-fallback to Codex — work continues |
| Cross-model validation | N/A | Two different models checking same code |
| Non-git review | N/A | Directory-based file scan for any project |
| Auto-chaining | Manual multi-step | One command: pipeline, auto-ralph, auto-plan |
| Failure handling | N/A | Bidirectional fallback: Claude ↔ Codex |

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
│   ├── team.md                  # Team build + Codex verification
│   ├── race.md                  # Dual-model parallel execution
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
