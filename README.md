# omc-codex

Claude Code plugin for Codex CLI integration — delegate tasks, run code reviews, and manage Codex sessions directly from Claude Code.

## Features

- **Task Delegation** — Send coding tasks to Codex from within Claude Code
- **Code Review** — Run Codex-powered adversarial code reviews
- **Session Management** — Start, monitor, cancel, and retrieve Codex sessions
- **Stop-time Review Gate** — Optional hook that reviews changes before session end
- **Rescue Agent** — Dedicated agent for deep investigation and fix attempts via Codex

## Installation

### Via Claude Code Plugin Marketplace

```
/plugin install codex
```

### Manual Installation

Clone this repo into your Claude Code plugins directory:

```bash
git clone https://github.com/jhcdev/omc-codex.git ~/.claude/plugins/marketplaces/omc-codex
```

Add to `~/.claude/settings.json`:

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

## Commands

| Command | Description |
|---------|-------------|
| `/codex:setup` | Check Codex CLI readiness and toggle review gate |
| `/codex:review` | Run a Codex code review on current changes |
| `/codex:adversarial-review` | Run an adversarial (red team) code review |
| `/codex:status` | Check status of running Codex sessions |
| `/codex:result` | Retrieve results from a completed Codex session |
| `/codex:cancel` | Cancel a running Codex session |
| `/codex:rescue` | Delegate deep investigation to Codex rescue agent |

## Skills

| Skill | Description |
|-------|-------------|
| `codex-cli-runtime` | Internal helper for calling the codex-companion runtime |
| `codex-result-handling` | Guidance for presenting Codex output back to the user |
| `gpt-5-4-prompting` | Prompt engineering guidance for Codex and GPT-5.4 tasks |

## Agents

| Agent | Description |
|-------|-------------|
| `codex-rescue` | Root-cause analysis, regression isolation, and fix attempts via Codex |

## Hooks

- **SessionStart** — Initializes Codex companion lifecycle
- **SessionEnd** — Optional stop-time review gate (enable via `/codex:setup`)

## Prerequisites

- [Claude Code](https://code.claude.com) v2.1+
- [Codex CLI](https://github.com/openai/codex) installed and authenticated
- OpenAI API key or ChatGPT login (`codex auth login`)

## Configuration

Run `/codex:setup` to check readiness and configure the review gate.

The review gate can also be toggled manually:
```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" setup --enable-review-gate --json
node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" setup --disable-review-gate --json
```

## License

MIT — See [LICENSE](LICENSE) for details.

## Credits

Based on [openai/codex-plugin-cc](https://github.com/openai/codex-plugin-cc) by OpenAI.
