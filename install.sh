#!/usr/bin/env bash
set -euo pipefail

# omc-codex installer
# Usage: curl -fsSL https://raw.githubusercontent.com/jhcdev/omc-codex/main/install.sh | bash

REPO_URL="https://github.com/jhcdev/omc-codex.git"
PLUGIN_DIR="${HOME}/.claude/plugins/marketplaces/omc-codex"
SETTINGS_FILE="${HOME}/.claude/settings.json"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { printf "${GREEN}[omcx]${NC} %s\n" "$1"; }
warn()  { printf "${YELLOW}[omcx]${NC} %s\n" "$1"; }
error() { printf "${RED}[omcx]${NC} %s\n" "$1"; }

# Step 1: Check prerequisites
info "Checking prerequisites..."

if ! command -v node &>/dev/null; then
  error "Node.js is required but not installed."
  echo "  Install: https://nodejs.org/ (v18.18+)"
  exit 1
fi

NODE_VERSION=$(node -v | sed 's/v//' | cut -d. -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
  error "Node.js v18.18+ required, found $(node -v)"
  exit 1
fi

if ! command -v git &>/dev/null; then
  error "Git is required but not installed."
  exit 1
fi

info "Node.js $(node -v) ✓"

# Step 2: Install or update plugin
if [ -d "$PLUGIN_DIR/.git" ]; then
  info "Updating existing installation..."
  cd "$PLUGIN_DIR"
  git pull --ff-only origin main 2>/dev/null || {
    warn "Pull failed — resetting to latest"
    git fetch origin main
    git reset --hard origin/main
  }
  info "Updated ✓"
else
  info "Installing omc-codex..."
  mkdir -p "$(dirname "$PLUGIN_DIR")"
  git clone "$REPO_URL" "$PLUGIN_DIR"
  info "Installed to $PLUGIN_DIR ✓"
fi

# Step 3: Configure settings.json
info "Configuring Claude Code settings..."

mkdir -p "$(dirname "$SETTINGS_FILE")"

if [ ! -f "$SETTINGS_FILE" ]; then
  cat > "$SETTINGS_FILE" << 'SETTINGS'
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
SETTINGS
  info "Created settings.json ✓"
else
  # Use node to safely merge into existing settings
  node -e "
    const fs = require('fs');
    const path = '$SETTINGS_FILE';
    let settings = {};
    try { settings = JSON.parse(fs.readFileSync(path, 'utf8')); } catch {}

    if (!settings.enabledPlugins) settings.enabledPlugins = {};
    settings.enabledPlugins['omcx@omc-codex'] = true;

    if (!settings.extraKnownMarketplaces) settings.extraKnownMarketplaces = {};
    settings.extraKnownMarketplaces['omc-codex'] = {
      source: {
        source: 'url',
        url: 'https://raw.githubusercontent.com/jhcdev/omc-codex/main/.claude-plugin/marketplace.json'
      }
    };

    fs.writeFileSync(path, JSON.stringify(settings, null, 2) + '\n');
  "
  info "Updated settings.json ✓"
fi

# Step 4: Check Codex CLI
if command -v codex &>/dev/null; then
  info "Codex CLI found ✓"

  if codex login status &>/dev/null; then
    info "Codex authenticated ✓"
  else
    warn "Codex CLI installed but not authenticated."
    echo "  Run: codex login"
  fi
else
  warn "Codex CLI not installed (optional — Claude-only fallback works)."
  echo "  Install: npm install -g @openai/codex"
  echo "  Then:    codex login"
fi

# Step 5: Done
echo ""
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "  omc-codex installed successfully!"
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Next steps:"
echo "    1. Reload plugins in Claude Code:  /reload-plugins"
echo "    2. Try the forge:  /omcx:forge implement hello world API"
echo ""
echo "  All commands:"
echo "    /omcx:forge         — Full cross-model forge (plan→TDD→build→stress→review)"
echo "    /omcx:pipeline      — Strength-based pipeline with fallback"
echo "    /omcx:team          — Mixed-model team (N:claude,M:codex)"
echo "    /omcx:race          — Multi-agent competition"
echo "    /omcx:blind-test    — Cross-model TDD"
echo "    /omcx:stress        — Red team vs blue team hardening"
echo "    /omcx:auto-ralph    — Build + validate loop"
echo "    /omcx:auto-plan     — Design → build → review"
echo "    /omcx:auto-validate — Cross-model quality gate"
echo "    /omcx:review        — Codex structured review"
echo "    /omcx:rescue        — Delegate task to Codex"
echo ""
