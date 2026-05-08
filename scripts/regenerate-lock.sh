#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"
LOCK_FILE="$REPO_ROOT/skills-lock.json"

CHECK_MODE=false
if [[ "${1:-}" == "--check" ]]; then
    CHECK_MODE=true
fi

compute_hash() {
    local skill_dir="$1"
    python3 -c '
import hashlib, os, sys

skill_dir = sys.argv[1]
h = hashlib.sha256()

for root, dirnames, filenames in os.walk(skill_dir, followlinks=False):
    dirnames.sort()
    for fname in sorted(filenames):
        if fname == ".DS_Store":
            continue
        fpath = os.path.join(root, fname)
        if not os.path.isfile(fpath) or os.path.islink(fpath):
            print(f"ERROR: non-regular file: {fpath}", file=sys.stderr)
            sys.exit(1)
        relpath = os.path.relpath(fpath, skill_dir).replace(os.sep, "/")
        h.update(relpath.encode("utf-8"))
        h.update(b"\0")
        with open(fpath, "rb") as f:
            h.update(f.read())
        h.update(b"\0")

print(h.hexdigest())
' "$skill_dir"
}

# Collect skill names (alphabetically sorted)
skills=()
for skill_dir in "$SKILLS_DIR"/*/; do
    skill_name="$(basename "$skill_dir")"
    # Skip skills without SKILL.md
    if [[ ! -f "$skill_dir/SKILL.md" ]]; then
        continue
    fi
    skills+=("$skill_name")
done

# Sort skill names
IFS=$'\n' skills=($(sort <<<"${skills[*]}")); unset IFS

# Build JSON output
json='{\n  "version": 1,\n  "skills": {'
first=true
for skill_name in "${skills[@]}"; do
    skill_dir="$SKILLS_DIR/$skill_name"
    hash=$(compute_hash "$skill_dir")
    if [[ "$first" == true ]]; then
        first=false
    else
        json+=','
    fi
    json+="\n    \"$skill_name\": {"
    json+="\n      \"source\": \"skills/$skill_name\","
    json+="\n      \"sourceType\": \"local\","
    json+="\n      \"computedHash\": \"$hash\""
    json+="\n    }"
done
json+='\n  }\n}\n'

generated=$(printf "$json")

if [[ "$CHECK_MODE" == true ]]; then
    if [[ ! -f "$LOCK_FILE" ]]; then
        echo "ERROR: $LOCK_FILE does not exist" >&2
        exit 1
    fi
    existing=$(cat "$LOCK_FILE")
    if [[ "$generated" == "$existing" ]]; then
        echo "skills-lock.json is up to date."
        exit 0
    else
        echo "ERROR: skills-lock.json is out of date. Run scripts/regenerate-lock.sh to update." >&2
        diff <(echo "$existing") <(echo "$generated") || true
        exit 1
    fi
else
    printf '%s' "$generated" > "$LOCK_FILE"
    echo "Generated $LOCK_FILE with ${#skills[@]} skill entries."
fi
