#!/usr/bin/env bash
#
# setup.sh
#
# One-command setup for CopilotKit AI agent skills.
# Installs public + internal skills, enables auto-updates,
# then launches Claude Code to complete onboarding.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/CopilotKit/skills/main/scripts/setup.sh | bash

set -euo pipefail

echo "=== CopilotKit Skills Setup ==="
echo ""

# 1. Install public skills
echo "Installing CopilotKit/skills (public)..."
npx skills add copilotkit/skills --full-depth -y
echo ""

# 2. Install internal skills (requires SSH access to CopilotKit org)
echo "Installing CopilotKit/internal-skills (private)..."
npx skills add CopilotKit/internal-skills -y 2>/dev/null || echo "  Skipped — no access to private repo (this is fine for external contributors)"
echo ""

# 3. Enable auto-updates
echo "Enabling auto-updates..."
SETTINGS_FILE="$HOME/.claude/settings.json"

if [ ! -f "$SETTINGS_FILE" ]; then
    mkdir -p "$HOME/.claude"
    echo '{}' > "$SETTINGS_FILE"
fi

python3 << 'PYEOF'
import json, os

settings_path = os.path.expanduser("~/.claude/settings.json")
with open(settings_path) as f:
    settings = json.load(f)

markets = settings.get("extraKnownMarketplaces", {})
changed = False

for name in ["copilotkit-plugins", "copilotkit-internal-plugins"]:
    if name in markets and not markets[name].get("autoUpdate"):
        markets[name]["autoUpdate"] = True
        changed = True
        print(f"  Enabled autoUpdate on {name}")

if changed:
    with open(settings_path, "w") as f:
        json.dump(settings, f, indent=2)
elif markets:
    print("  Auto-updates already configured")
else:
    print("  No marketplaces to configure yet (will be set after first plugin install)")
PYEOF

echo ""
echo "=== Skills installed ==="
echo ""

# 4. Launch Claude Code to complete onboarding
if command -v claude &>/dev/null; then
    echo "Launching Claude Code to complete setup..."
    echo ""
    claude "onboard me for CopilotKit"
else
    echo "Claude Code not found. After installing it, run:"
    echo "  claude \"onboard me for CopilotKit\""
fi
