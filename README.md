# omc-codex

> Codex integration for oh-my-claudecode — run structured code reviews, delegate tasks, and perform adversarial reviews using OpenAI Codex directly from Claude Code.

## Quick Start

```bash
# 1. Install Codex CLI
npm install -g @openai/codex

# 2. Authenticate Codex (browser login or API key)
codex auth login

# 3. Clone the plugin
git clone https://github.com/jhcdev/omc-codex.git ~/.claude/plugins/marketplaces/omc-codex

# 4. Add to ~/.claude/settings.json
# (see Configuration section below)

# 5. Reload plugins in Claude Code
/reload-plugins

# 6. Verify setup
/codex:setup
```

## Installation

### Option A: Clone directly

```bash
git clone https://github.com/jhcdev/omc-codex.git ~/.claude/plugins/marketplaces/omc-codex
```

### Option B: Via Claude Code Plugin Marketplace

```
/plugin install codex
```

### Configuration

Add the following to `~/.claude/settings.json`:

```json
{
  "enabledPlugins": {
    "codex@omc-codex": true
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
| Codex CLI (`@openai/codex`) | Optional | Falls back to Claude agents if not installed |
| oh-my-claudecode (omc) | Optional | Enables combo recipes with omc skills |

---

## Getting Started

Once installed, try these commands inside Claude Code:

```bash
# Check that everything is wired up
/codex:setup

# Run a code review on your current changes
/codex:review --wait

# Delegate a task to Codex
/codex:rescue --write fix the failing tests in src/auth

# Run an adversarial design review
/codex:adversarial-review --wait

# Enable the stop-time review gate (auto-review before session end)
/codex:setup --enable-review-gate
```

---

## Command Reference

### Code Review

#### `/codex:review`
Structured code review powered by Codex built-in reviewer.
Returns JSON schema results with verdict, severity, file, line range, and confidence.

```bash
/codex:review --wait                  # Foreground (wait for result)
/codex:review --background            # Background
/codex:review --base main             # Review against a specific branch
/codex:review --scope working-tree    # Review uncommitted changes only
```

#### `/codex:adversarial-review`
Adversarial review that challenges design choices and assumptions.
Focuses on design weaknesses rather than implementation bugs.

```bash
/codex:adversarial-review --wait
/codex:adversarial-review --wait auth flow and session management
/codex:adversarial-review --background
```

### Task Delegation

#### `/codex:rescue`
Delegate bug fixes, investigation, or implementation tasks to Codex.

```bash
/codex:rescue --write fix the race condition in auth middleware
/codex:rescue investigate why tests fail on CI
/codex:rescue --resume apply the top fix          # Continue previous thread
/codex:rescue --fresh rewrite the caching layer    # Force new thread
/codex:rescue --background --write implement pagination
/codex:rescue --model spark quick fix for typo
```

### Review Gate

#### `/codex:setup`
Check Codex CLI status, authentication, and manage the review gate.

```bash
/codex:setup                        # Check status
/codex:setup --enable-review-gate   # Auto-review before session end
/codex:setup --disable-review-gate  # Disable auto-review
```

When enabled, Codex automatically reviews changes before session end.
**ALLOW** = normal exit. **BLOCK** = suggests fixes before exiting.

### Job Management

```bash
/codex:status                        # List all jobs
/codex:status task-abc123            # Job details
/codex:status task-abc123 --wait     # Wait for completion

/codex:result                        # Latest job result
/codex:result task-abc123            # Specific job result

/codex:cancel                        # Cancel running job
/codex:cancel task-abc123            # Cancel specific job
```

---

## Combo Recipes (with omc)

omc-codex works seamlessly alongside omc skills in the same session.

### Recipe 1: Plan → Codex Build → Structured Review

```bash
/oh-my-claudecode:plan "add refund feature to payment system"
/codex:rescue --write implement refund feature per the plan above
/codex:review --wait
/codex:rescue --resume fix the issues from the review above
```

### Recipe 2: Codex Build + omc ralph Verification Loop

```bash
/codex:rescue --write implement the new caching layer with Redis
/oh-my-claudecode:ralph "make all caching tests pass. fix and re-run on failure."
```

### Recipe 3: Dual Review Pipeline

```bash
/codex:review --wait                    # Implementation bugs
/codex:adversarial-review --wait        # Design weaknesses
"Summarize both reviews and prioritize action items"
```

### Recipe 4: omc team + Codex Background Review

```bash
/codex:review --background
/oh-my-claudecode:team 2:executor "refactor module A, add tests for module B"
/codex:result
```

### Recipe 5: Deep-dive → Codex Fix → Review Gate

```bash
/codex:setup --enable-review-gate
/oh-my-claudecode:deep-dive "investigate why API response exceeds 3s"
/codex:rescue --write optimize the N+1 query based on analysis above
# Review gate fires automatically on session end
```

### Recipe 6: Autopilot + Codex Cross-validation

```bash
/oh-my-claudecode:autopilot "implement notification system — email, slack, in-app"
/codex:review --wait
/codex:adversarial-review --wait focusing on failure modes
```

### Recipe Selection Guide

| Scenario | Recommended Recipe |
|----------|-------------------|
| New feature (design → review) | Recipe 1: Plan → rescue → review |
| Post-implementation QA | Recipe 2: rescue → ralph loop |
| Pre-PR final check | Recipe 3: Dual review pipeline |
| Time-saving (parallel) | Recipe 4: team + background review |
| Performance / bug fix | Recipe 5: deep-dive → rescue → gate |
| Full automation + cross-check | Recipe 6: autopilot → Codex review |

---

## Behavior Without Codex

| Situation | Behavior |
|-----------|----------|
| Codex CLI not installed | Automatically falls back to Claude agents |
| Codex not authenticated | Prompts `!codex login` + offers Claude alternative |
| Codex runtime error | Returns error, workflow reroutes to Claude |
| No omc either | `/codex:review`, `rescue`, etc. work independently |

---

## Architecture

```
┌─────────────────────────────────────────────────┐
│ Claude Code Session                              │
│                                                  │
│  ┌──────────┐  ┌──────────────┐  ┌───────────┐ │
│  │ omc      │  │ omc-codex    │  │ Codex     │ │
│  │ skills   │  │ plugin       │  │ CLI       │ │
│  │          │  │              │  │           │ │
│  │ ralph    │  │ /review ─────┼──┼→ app-     │ │
│  │ ultrawork│  │ /adv-review ─┼──┼→ server   │ │
│  │ team     │  │ /rescue ─────┼──┼→ broker   │ │
│  │ autopilot│  │ /setup       │  │           │ │
│  │ plan     │  │              │  │ (fallback)│ │
│  │ ...      │  │              │  │ → Claude  │ │
│  └──────────┘  └──────────────┘  └───────────┘ │
│                       │                          │
│              ┌────────┴────────┐                 │
│              │  Hooks          │                 │
│              │  SessionStart   │                 │
│              │  SessionEnd     │                 │
│              │  Stop (gate)    │                 │
│              └─────────────────┘                 │
└─────────────────────────────────────────────────┘
```

## Unique Value (what omc alone can't do)

1. **Structured code review** — Codex app-server's built-in reviewer with JSON schema output (severity/file/line/confidence)
2. **Review gate** — Automatic code review enforced before session end (Stop hook, BLOCK/ALLOW)
3. **Thread resume** — `--resume` continues previous Codex conversation context
4. **Graceful fallback** — No Codex? Automatically switches to Claude agents without breaking workflows

## Skills

| Skill | Description |
|-------|-------------|
| `codex-cli-runtime` | Internal helper contract for calling codex-companion runtime |
| `codex-result-handling` | Guidance for presenting Codex output back to the user |
| `gpt-5-4-prompting` | Prompt engineering guidance for Codex and GPT-5.4 tasks |

## Agents

| Agent | Description |
|-------|-------------|
| `codex-rescue` | Root-cause analysis, regression isolation, and fix attempts via Codex |

## File Structure

```
omc-codex/
├── .claude-plugin/
│   ├── plugin.json              # Plugin metadata
│   └── marketplace.json         # Marketplace registration
├── commands/                    # Slash commands
│   ├── review.md                # Structured code review
│   ├── adversarial-review.md    # Adversarial review
│   ├── rescue.md                # Task delegation
│   ├── setup.md                 # Setup & review gate
│   ├── status.md                # Job status
│   ├── result.md                # Job results
│   └── cancel.md                # Cancel jobs
├── agents/
│   └── codex-rescue.md          # Codex forwarding agent
├── skills/
│   ├── codex-cli-runtime/       # Runtime contract
│   ├── codex-result-handling/   # Result presentation
│   └── gpt-5-4-prompting/      # Prompt engineering
├── hooks/hooks.json             # SessionStart/End, Stop hooks
├── scripts/                     # Runtime (codex-companion + lib)
├── prompts/                     # Review prompt templates
├── schemas/                     # Review output JSON schema
├── LICENSE
└── README.md
```

## License

MIT — See [LICENSE](LICENSE) for details.

## Credits

Based on [openai/codex-plugin-cc](https://github.com/openai/codex-plugin-cc) by OpenAI.
