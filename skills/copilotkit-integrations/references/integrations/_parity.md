# _parity Integration

The `_parity` framework is CopilotKit's internal integration-demo parity tooling that ensures consistency across multiple agent framework examples. It's not a user-facing integration but rather a development tool that keeps the various integration demos (LangGraph Python, LangGraph FastAPI, LangGraph JS) aligned to a single canonical implementation.

## Overview

The `_parity` system uses a manifest-driven approach to track specific files, package.json keys, and agent surface requirements across integration examples. It operates on the principle of a "north-star" demo (currently `langgraph-python`) that serves as the canonical reference, with other instances automatically synced to match its frontend components, dependencies, and agent interface.

## Prerequisites

- Node.js 18+
- TypeScript knowledge for understanding the tooling
- Access to the CopilotKit repository structure

## Dependencies

The parity tooling uses these internal dependencies:

```json
{
  "devDependencies": {
    "@types/node": "latest",
    "typescript": "latest"
  }
}
```

## Project Structure

```
examples/integrations/_parity/
├── README.md                    # Documentation and usage guide
├── manifest.json                # Declarative configuration
├── canonical/
│   └── PROMPT.md               # Canonical agent prompt
├── lib/
│   ├── manifest.ts             # Manifest loading and validation
│   ├── report.ts               # Report formatting and display
│   └── diff.ts                 # File comparison utilities
├── sync.ts                     # Synchronization script
└── verify.ts                   # Drift verification script
```

## Key Files Walkthrough

### manifest.json

The central configuration that declares what gets tracked:

```json
{
  "version": 1,
  "northStar": "langgraph-python",
  "canonicalPromptFile": "_parity/canonical/PROMPT.md",
  "tracked": {
    "verbatimFiles": [
      "src/app/page.tsx",
      "src/components/**",
      "public/**"
    ],
    "packageJsonPaths": [
      "dependencies.@copilotkit/react-core",
      "dependencies.@copilotkit/runtime",
      "scripts.dev"
    ],
    "agentSurface": {
      "toolNames": ["manage_todos", "get_todos", "query_data"],
      "stateKeys": ["todos", "messages"],
      "modelFamily": "openai"
    }
  },
  "instances": {
    "langgraph-js": {
      "role": "instance",
      "allowedDivergence": ["agent/**", "src/app/api/copilotkit/**"]
    }
  }
}
```

### sync.ts

Copies verbatim files and rewrites package.json keys from north-star to instances:

```typescript
function syncInstance(
  root: ParityRoot,
  instance: string,
  dryRun: boolean,
): SyncResult {
  const from = northStarDir(root);
  const to = instanceDir(root, instance);
  
  // Copy tracked verbatim files
  for (const pattern of manifest.tracked.verbatimFiles) {
    const matches = expandPattern(from, pattern);
    for (const relPath of matches) {
      if (!isAllowedDivergence(relPath, inst.allowedDivergence)) {
        copyIfChanged(join(from, relPath), join(to, relPath), dryRun);
      }
    }
  }
  
  // Rewrite package.json keys
  for (const keyPath of manifest.tracked.packageJsonPaths) {
    const override = inst.packageJsonOverrides[keyPath];
    const value = override !== undefined 
      ? override 
      : getByPath(pkgSrc, keyPath);
    setByPath(pkgDst, keyPath, value);
  }
}
```

### verify.ts

Checks instances for drift against the north-star:

```typescript
function verifyInstance(root: ParityRoot, instance: string): Report {
  const items: DriftItem[] = [];
  
  // Check verbatim file content
  for (const relPath of trackedFiles) {
    const srcSha = fileSha256(join(from, relPath));
    const dstSha = fileSha256(join(to, relPath));
    if (srcSha !== dstSha) {
      items.push({
        severity: "error",
        kind: "verbatim-file",
        subject: relPath,
        detail: "content differs from north-star"
      });
    }
  }
  
  // Check agent surface (grep-level)
  const agentText = readAgentText(to);
  for (const tool of manifest.tracked.agentSurface.toolNames) {
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

The `_parity` system ensures that all integration examples provide a consistent frontend experience and agent interface:

1. **Frontend Components**: All instances share identical React components, hooks, and UI from the north-star
2. **CopilotKit Dependencies**: Package versions are synchronized to prevent version skew
3. **Agent Interface**: Tools and state keys are verified across different agent implementations
4. **AG-UI Protocol**: Each instance maintains the same AG-UI communication pattern despite different backend implementations

The system allows for legitimate divergence in:
- Agent implementation (`agent/**` directories)
- CopilotKit API routes (`src/app/api/copilotkit/**`)
- Build/deployment tooling (Dockerfiles, scripts)

## Running the Example

From the repository root:

```bash
# Sync all instances to the north-star
pnpm parity:sync --all

# Sync a specific instance
pnpm parity:sync --target=langgraph-js

# Dry-run to see what would change
pnpm parity:sync --target=langgraph-js --dry-run

# Verify all instances for drift
pnpm parity:verify

# Verify specific instance
pnpm parity:verify --target=langgraph-js

# CI check (no color output)
pnpm parity:check
```

The typical workflow when the north-star changes:

```bash
# After modifying langgraph-python
pnpm parity:sync --all
pnpm parity:verify
# Manually fix any agent-surface drift
git add . && git commit -m "Sync integration demos to north-star"
```

This system ensures that users get a consistent experience across all CopilotKit integration examples while allowing each framework to implement agents in their idiomatic way.
