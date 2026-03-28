#!/usr/bin/env bash
#
# detect-new-integrations.sh
#
# Compares integration example directories in CopilotKit/CopilotKit against
# existing guide files in this repo. Outputs names of integrations that have
# an example directory but no corresponding guide.
#
# Usage:
#   ./scripts/detect-new-integrations.sh <copilotkit-repo-path> [guides-dir]
#
# Arguments:
#   copilotkit-repo-path  Path to the checked-out CopilotKit/CopilotKit repo
#   guides-dir            Path to integration guides (default: skills/copilotkit-integrations/references/integrations)
#
# Output:
#   One integration name per line for each new (unmatched) integration.
#   Exit code 0 if new integrations found, 1 if none found.

set -euo pipefail

COPILOTKIT_REPO="${1:?Usage: $0 <copilotkit-repo-path> [guides-dir]}"
GUIDES_DIR="${2:-skills/copilotkit-integrations/references/integrations}"

EXAMPLES_DIR="${COPILOTKIT_REPO}/examples/integrations"

if [ ! -d "$EXAMPLES_DIR" ]; then
    echo "WARNING: examples/integrations directory not found at ${EXAMPLES_DIR}" >&2
    echo "This may mean the CopilotKit repo structure has changed." >&2
    exit 1
fi

if [ ! -d "$GUIDES_DIR" ]; then
    echo "ERROR: Guides directory not found at ${GUIDES_DIR}" >&2
    exit 1
fi

# Collect existing guide names (filename without .md extension)
declare -A existing_guides
for guide_file in "$GUIDES_DIR"/*.md; do
    [ -f "$guide_file" ] || continue
    basename="${guide_file##*/}"
    name="${basename%.md}"
    existing_guides["$name"]=1
done

# Compare against example directories
new_integrations=()
for example_dir in "$EXAMPLES_DIR"/*/; do
    [ -d "$example_dir" ] || continue
    dirname="${example_dir%/}"
    name="${dirname##*/}"

    # Skip hidden directories and common non-integration dirs
    [[ "$name" == .* ]] && continue
    [[ "$name" == "node_modules" ]] && continue

    if [ -z "${existing_guides[$name]+x}" ]; then
        new_integrations+=("$name")
    fi
done

# Exit code convention: 0 = new integrations found (success/action needed),
# 1 = no new integrations (nothing to do). This is intentional -- the CI
# workflow treats "found new integrations" as the success case that triggers
# Strategy 2 guide generation. Callers should use `|| true` to prevent
# set -e from aborting when no new integrations exist.
if [ ${#new_integrations[@]} -eq 0 ]; then
    echo "No new integrations detected." >&2
    exit 1
fi

# Output new integration names, one per line
for name in "${new_integrations[@]}"; do
    echo "$name"
done
