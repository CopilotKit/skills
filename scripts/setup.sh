#!/usr/bin/env bash
#
# install-all.sh
#
# One-command setup for CopilotKit AI agent skills.
# Installs both public and internal skills, enables auto-updates.
#
# Usage:
#   bash <(gh api repos/CopilotKit/internal-skills/contents/scripts/install-all.sh --jq '.content' | base64 -d)
#
# Or if you have the repo cloned:
#   bash scripts/install-all.sh

set -euo pipefail

echo "=== CopilotKit Skills Setup ==="
echo ""

# 1. Install public skills
echo "Installing CopilotKit/skills (public)..."
npx skills add copilotkit/skills --full-depth -y
echo ""

# 2. Install internal skills
echo "Installing CopilotKit/internal-skills (private)..."
npx skills add CopilotKit/internal-skills -y
echo ""

# 3. Enable auto-updates
echo "Enabling auto-updates for CopilotKit marketplaces..."
SETTINGS_FILE="$HOME/.claude/settings.json"

if [ ! -f "$SETTINGS_FILE" ]; then
    echo '{}' > "$SETTINGS_FILE"
fi

python3 << 'PYEOF'
import json

settings_path = "$HOME/.claude/settings.json".replace("$HOME", __import__("os").path.expanduser("~"))
with open(settings_path) as f:
    settings = json.load(f)

markets = settings.get("extraKnownMarketplaces", {})
changes = []

for name in ["copilotkit-plugins", "copilotkit-internal-plugins"]:
    if name in markets and not markets[name].get("autoUpdate"):
        markets[name]["autoUpdate"] = True
        changes.append(name)

if changes:
    with open(settings_path, "w") as f:
        json.dump(settings, f, indent=2)
    for c in changes:
        print(f"  Enabled autoUpdate on {c}")
else:
    print("  Auto-updates already configured")
PYEOF

echo ""
echo "=== Done ==="
echo ""
echo "Start a new Claude Code session. Your skills are ready."
echo "Say 'onboard me for CopilotKit' for full setup (LSP, plugins, verification)."
