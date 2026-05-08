# Parity Integration

The `_parity` framework is an internal CopilotKit tooling system that ensures consistency across integration examples. It synchronizes verbatim files, package.json dependencies, and agent surface contracts between a "north-star" reference example and all other integration demos.

## Overview

Parity prevents drift across CopilotKit's integration examples by:
- Copying shared frontend code (components, hooks, UI) from a canonical source
- Aligning package.json dependencies and scripts
- Verifying that all agents implement the same tool surface and prompt
- Allowing controlled divergence for framework-specific code (agent implementations, API routes)

The system uses a declarative manifest (`manifest.json`) to specify what gets tracked, what's allowed to differ, and which example serves as the source of truth.

## Prerequisites

- Node.js 18+
- pnpm for workspace management
- TypeScript for the parity scripts

## Project Structure

```
examples/integrations/
├── _parity/                    # Parity tooling
│   ├── manifest.json          # Configuration
│   ├── canonical/PROMPT.md    # Shared prompt template
│   ├── lib/                   # Core libraries
│   ├── sync.ts               # Sync script
│   └── verify.ts             # Verification script
├── langgraph-python/         # North-star reference
├── langgraph-js/            # Instance (synced to north-star)
└── langgraph-fastapi/       # Instance (synced to north-star)
```

## Key Files Walkthrough

### Manifest Configuration (`manifest.json`)

Declares what gets synchronized across examples:

```json
{
  "version": 1,
  "northStar": "langgraph-python",
  "canonicalPromptFile": "_parity/canonical/PROMPT.md",
  "tracked": {
    "verbatimFiles": [
      "src/app/layout.tsx",
      "src/components/**",
      "public/**"
    ],
    "packageJsonPaths": [
      "dependencies.@copilotkit/react-core",
      "scripts.dev"
    ],
    "agentSurface": {
      "toolNames": ["manage_todos", "get_weather"],
      "stateKeys": ["todos", "messages"]
    }
  },
  "instances": {
    "langgraph-js": {
      "role": "instance",
      "allowedDivergence": ["agent/**", "src/app/api/copilotkit/**"],
      "packageJsonOverrides": {
        "scripts.dev:agent": "./scripts/run-agent.sh"
      }
    }
  }
}
```

### Sync Script (`sync.ts`)

Copies tracked content from north-star to instances:

```typescript
function syncInstance(root: ParityRoot, instance: string, dryRun: boolean) {
  // Copy verbatim files (respecting allowedDivergence)
  for (const pattern of manifest.tracked.verbatimFiles) {
    const matches = expandPattern(from, pattern);
    for (const relPath of matches) {
      if (isAllowedDivergence(relPath, inst.allowedDivergence)) continue;
      copyIfChanged(join(from, relPath), join(to, relPath), dryRun);
    }
  }
  
  // Rewrite package.json tracked keys
  for (const keyPath of manifest.tracked.packageJsonPaths) {
    const override = inst.packageJsonOverrides[keyPath];
    const value = override || getByPath(pkgSrc, keyPath);
    setByPath(pkgDst, keyPath, value);
  }
}
```

### Verification Script (`verify.ts`)

Checks for drift between north-star and instances:

```typescript
function verifyInstance(root: ParityRoot, instance: string): Report {
  const items: DriftItem[] = [];
  
  // Verify verbatim files are byte-equal
  for (const relPath of verbatimFiles) {
    if (fileSha256(srcPath) !== fileSha256(dstPath)) {
      items.push({
        severity: "error",
        kind: "verbatim-file",
        subject: relPath,
        detail: "content differs from north-star"
      });
    }
  }
  
  // Verify agent surface (tools/state) via grep
  const agentText = readAgentText(instanceDir);
  for (const tool of manifest.agentSurface.toolNames) {
    if (!agentText.includes(tool)) {
      items.push({
        severity: "error", 
        kind: "agent-tool",
        subject: tool,
        detail: "tool name not found in agent source"
      });
    }
  }
}
```

## How It Connects to CopilotKit

Parity ensures that all CopilotKit integration examples:

1. **Use consistent frontend patterns** - Same `useAgent`, `useFrontendTool`, and `CopilotChat` usage across examples
2. **Share identical dependencies** - All examples track the same `@copilotkit/*` package versions 
3. **Implement the same agent surface** - Every agent provides the required tools (`manage_todos`, `search_flights`, etc.) and state keys (`todos`, `messages`)
4. **Use the canonical prompt** - All agents inline the same system prompt for consistent behavior

The system allows framework-specific code (agent implementations, API routes) to diverge while keeping shared frontend code and contracts aligned.

## Running the Example

### Sync instances to north-star

```bash
# Sync a single instance
pnpm parity:sync --target=langgraph-js

# Dry-run to preview changes  
pnpm parity:sync --target=langgraph-js --dry-run

# Sync all instances
pnpm parity:sync --all
```

### Verify consistency

```bash
# Check all instances for drift
pnpm parity:verify

# Check specific instance
pnpm parity:verify --target=langgraph-js

# CI-friendly output (no color)
pnpm parity:check
```

### Typical workflow

When the north-star example changes:

```bash
# Sync shared code to all instances
pnpm parity:sync --all

# Verify no unexpected drift remains  
pnpm parity:verify

# Manually port agent-specific changes
# Edit agent/ directories as needed

# Verify again until clean
pnpm parity:verify
```

The parity system runs in CI on every PR touching `examples/integrations/**` to catch drift early and guide contributors back to this process.
