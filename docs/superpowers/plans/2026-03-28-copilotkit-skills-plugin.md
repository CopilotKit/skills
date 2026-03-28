# CopilotKit Skills Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a cross-tool AI agent skills plugin for CopilotKit, with 6 skills covering the full developer lifecycle (setup, develop, integrations, debug, upgrade, contribute), auto-generated reference docs from the v2 codebase, and multi-tool packaging for Claude Code + Codex.

**Architecture:** Plugin repo at CopilotKit/skills with SKILL.md files following the agentskills.io open standard. Reference docs auto-generated from CopilotKit/CopilotKit v2 source + examples. Plugin packaging for Claude Code (.claude-plugin/) and Codex (agents/openai.yaml). MCP integration via mcp-docs server.

**Tech Stack:** Markdown (SKILL.md), YAML (plugin manifests), JSON (hooks, MCP config), Bash (install script, hooks, extraction scripts)

**Source of truth for v2 APIs:** /Users/jpr5/CopilotKit (local clone)

---

### Task 1: Create GitHub Repo and Scaffold Directory Structure

**Files:**
- Create: `CopilotKit/skills` GitHub repo
- Create: all directories

- [ ] **Step 1: Create repo on GitHub**

```bash
gh repo create CopilotKit/skills --public --description "AI agent skills for CopilotKit — setup, develop, debug, upgrade, and contribute" --license MIT
```

- [ ] **Step 2: Clone and create directory structure**

```bash
git clone git@github.com:CopilotKit/skills.git /Users/jpr5/proj/copilotkit-skills
cd /Users/jpr5/proj/copilotkit-skills
mkdir -p .claude-plugin agents hooks scripts
mkdir -p skills/copilotkit-setup/references skills/copilotkit-setup/assets
mkdir -p skills/copilotkit-develop/references
mkdir -p skills/copilotkit-integrations/references/integrations
mkdir -p skills/copilotkit-debug/references
mkdir -p skills/copilotkit-upgrade/references
mkdir -p skills/copilotkit-contribute/references
```

- [ ] **Step 3: Commit scaffold**

```bash
# Add .gitkeep to empty dirs, then:
git add -A && git commit -m "Scaffold directory structure for 6 skills"
```

---

### Task 2: Plugin Packaging (Claude Code + Codex)

**Files:**
- Create: `.claude-plugin/plugin.json`
- Create: `.claude-plugin/marketplace.json`
- Create: `agents/openai.yaml`

- [ ] **Step 1: Create Claude Code plugin manifest**

Write `.claude-plugin/plugin.json`:
```json
{
  "name": "copilotkit",
  "description": "AI agent skills for CopilotKit — setup, develop, integrate, debug, upgrade, and contribute to CopilotKit projects",
  "version": "1.0.0",
  "author": {
    "name": "CopilotKit",
    "url": "https://copilotkit.ai"
  },
  "homepage": "https://docs.copilotkit.ai",
  "repository": "https://github.com/CopilotKit/skills",
  "license": "MIT",
  "keywords": [
    "copilotkit", "ai", "agents", "react", "next.js",
    "langgraph", "crewai", "pydantic-ai", "mastra",
    "ag-ui", "mcp", "copilot", "chatbot"
  ],
  "mcpServers": "./.mcp.json"
}
```

- [ ] **Step 2: Create marketplace metadata**

Write `.claude-plugin/marketplace.json`:
```json
{
  "plugins": [
    {
      "name": "copilotkit",
      "description": "AI agent skills for CopilotKit — setup, develop, integrate, debug, upgrade, and contribute",
      "category": "ai-frameworks",
      "tags": ["copilotkit", "ai", "agents", "react"]
    }
  ]
}
```

- [ ] **Step 3: Create Codex plugin metadata**

Write `agents/openai.yaml`:
```yaml
interface:
  display_name: "CopilotKit Skills"
  description: "AI agent skills for CopilotKit — setup, develop, integrate, debug, upgrade, and contribute"
```

- [ ] **Step 4: Commit**

```bash
git add .claude-plugin/ agents/ && git commit -m "Add plugin packaging for Claude Code and Codex"
```

---

### Task 3: MCP Configuration

**Files:**
- Create: `.mcp.json`

- [ ] **Step 1: Create MCP config for mcp-docs**

Write `.mcp.json`:
```json
{
  "mcpServers": {
    "copilotkit-docs": {
      "command": "npx",
      "args": ["-y", "@copilotkit/mcp-docs"]
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add .mcp.json && git commit -m "Add MCP server config for CopilotKit docs"
```

---

### Task 4: Hooks (Auto-Approve Read-Only Ops)

**Files:**
- Create: `hooks/hooks.json`
- Create: `hooks/auto-approve-copilotkit.sh`

- [ ] **Step 1: Create hooks config**

Write `hooks/hooks.json`:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/auto-approve-copilotkit.sh"
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 2: Create auto-approve script**

Write `hooks/auto-approve-copilotkit.sh` — auto-approve read-only CopilotKit operations:

The script should:
- Parse the Bash command from stdin JSON
- Auto-approve: `npx copilotkit --help`, `npx copilotkit --version`, `pnpm list @copilotkit/*`, `pnpm list @copilotkitnext/*`, `npm ls @copilotkit/*`
- Auto-approve (contributor-scoped): `nx run @copilotkit/*:test`, `nx run @copilotkitnext/*:test`, `vitest run`
- Never auto-approve: `install`, `add`, `remove`, `delete`, `publish`, `deploy`, `push`
- Output JSON: `{"permissionDecision": "allow", "reason": "..."}` or no output to defer

Model after render-oss/skills hooks/auto-approve-render.sh but adapted for CopilotKit commands.

- [ ] **Step 3: Make executable and commit**

```bash
chmod +x hooks/auto-approve-copilotkit.sh
git add hooks/ && git commit -m "Add auto-approve hooks for read-only CopilotKit operations"
```

---

### Task 5: Multi-Tool Install Script

**Files:**
- Create: `scripts/install.sh`

- [ ] **Step 1: Write install script**

The script should:
- Detect installed tools (Claude Code, Codex, Cursor, OpenCode)
- Let user choose which skills to install (default: all 6)
- Copy skills to the correct directory per tool
- Offer MCP setup guidance
- Support `--update` flag for re-installation

Model after render-oss/skills scripts/install.sh but adapted for CopilotKit.

- [ ] **Step 2: Make executable and commit**

```bash
chmod +x scripts/install.sh
git add scripts/ && git commit -m "Add multi-tool install script"
```

---

### Task 6: CLAUDE.md and AGENTS.md

**Files:**
- Create: `CLAUDE.md`
- Create: `AGENTS.md`

- [ ] **Step 1: Write CLAUDE.md**

```markdown
# CopilotKit Skills

This plugin provides AI agent skills for working with CopilotKit.

## Available Skills

- `copilotkit-setup` — Add CopilotKit to a project
- `copilotkit-develop` — Build AI features with CopilotKit v2 APIs
- `copilotkit-integrations` — Integration guides for agent frameworks
- `copilotkit-debug` — Diagnose and fix CopilotKit issues
- `copilotkit-upgrade` — Migrate between CopilotKit versions
- `copilotkit-contribute` — Contribute to CopilotKit OSS

## Key Context

- CopilotKit v2 packages are under `@copilotkitnext/*`
- V1 packages (`@copilotkit/*`) are public API wrappers around v2
- Communication uses AG-UI protocol (SSE-based events)
- Use mcp-docs MCP server for querying live CopilotKit documentation
```

- [ ] **Step 2: Write AGENTS.md with same content**

Copy CLAUDE.md content to AGENTS.md (Codex equivalent).

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md AGENTS.md && git commit -m "Add instruction files for Claude Code and Codex"
```

---

### Task 7: Bootstrap copilotkit-setup Skill

**Files:**
- Create: `skills/copilotkit-setup/SKILL.md`
- Create: `skills/copilotkit-setup/references/framework-detection.md`
- Create: `skills/copilotkit-setup/references/runtime-architecture.md`
- Create: `skills/copilotkit-setup/assets/` (starter templates)

**Source:** Analyze /Users/jpr5/CopilotKit — read examples/integrations/*, packages/v2/runtime/src/*, and CopilotKit docs via mcp-docs.

- [ ] **Step 1: Generate SKILL.md from v2 codebase**

Agent must:
1. Read /Users/jpr5/CopilotKit/packages/v2/runtime/src/ to understand runtime setup
2. Read /Users/jpr5/CopilotKit/examples/ to understand framework patterns
3. Read /Users/jpr5/CopilotKit/.claude/docs/architecture.md for architecture context
4. Generate SKILL.md with: frontmatter (name, description), prerequisites, framework detection logic, step-by-step setup workflow for Next.js App Router + other frameworks, quick reference

- [ ] **Step 2: Generate reference docs**

Extract framework-specific setup patterns from examples/ directory. Generate runtime-architecture.md from packages/v2/runtime/ source.

- [ ] **Step 3: Extract starter templates**

Copy/adapt working starter configs from CopilotKit examples/ into assets/.

- [ ] **Step 4: Commit**

```bash
git add skills/copilotkit-setup/ && git commit -m "Add copilotkit-setup skill with v2 reference docs"
```

---

### Task 8: Bootstrap copilotkit-develop Skill

**Files:**
- Create: `skills/copilotkit-develop/SKILL.md`
- Create: `skills/copilotkit-develop/references/api-surface.md`
- Create: `skills/copilotkit-develop/references/chat-customization.md`
- Create: `skills/copilotkit-develop/references/runtime-api.md`

**Source:** Analyze /Users/jpr5/CopilotKit — read packages/v2/react/src/hooks/, packages/v2/core/src/, and examples/.

- [ ] **Step 1: Extract v2 public API surface**

Agent must:
1. Read /Users/jpr5/CopilotKit/packages/v2/react/src/hooks/ — list all exported hooks with signatures and descriptions
2. Read /Users/jpr5/CopilotKit/packages/v2/react/src/components/ — list all exported components with props
3. Read /Users/jpr5/CopilotKit/packages/v2/core/src/ — list core types and abstractions
4. Generate api-surface.md with complete v2 API reference

CRITICAL: Use ONLY v2 API names. NOT useCopilotAction, NOT CoAgents, NOT CopilotTextarea, NOT useCopilotReadable. These are all deprecated v1 terminology.

- [ ] **Step 2: Generate SKILL.md**

Workflow guidance for building AI features: adding chat, registering frontend tools, sharing context, working with agents. All using v2 hooks and components.

- [ ] **Step 3: Generate reference docs**

chat-customization.md from CopilotChat component props. runtime-api.md from runtime package exports.

- [ ] **Step 4: Commit**

```bash
git add skills/copilotkit-develop/ && git commit -m "Add copilotkit-develop skill with v2 API reference"
```

---

### Task 9: Bootstrap copilotkit-integrations Skill

**Files:**
- Create: `skills/copilotkit-integrations/SKILL.md`
- Create: `skills/copilotkit-integrations/references/integrations/langgraph.md`
- Create: `skills/copilotkit-integrations/references/integrations/crewai.md`
- Create: `skills/copilotkit-integrations/references/integrations/pydantic-ai.md`
- Create: one file per integration found in examples/integrations/

**Source:** Analyze /Users/jpr5/CopilotKit/examples/integrations/ — each subdirectory is one integration.

- [ ] **Step 1: Enumerate all integrations**

Read each directory under /Users/jpr5/CopilotKit/examples/integrations/. For each:
1. Read the README, package.json/pyproject.toml, and main source files
2. Understand how it wires up to CopilotKit runtime
3. Extract the integration pattern

- [ ] **Step 2: Generate per-integration reference docs**

One markdown file per integration in references/integrations/. Each should cover:
- Prerequisites (Python vs Node, packages needed)
- How to wire the agent to CopilotRuntime
- AG-UI protocol details specific to this integration
- Working example code extracted from the examples/ directory

- [ ] **Step 3: Generate SKILL.md**

Overview of all integrations, decision tree for choosing one, common patterns across integrations.

- [ ] **Step 4: Commit**

```bash
git add skills/copilotkit-integrations/ && git commit -m "Add copilotkit-integrations skill with per-framework guides"
```

---

### Task 10: Bootstrap copilotkit-debug Skill

**Files:**
- Create: `skills/copilotkit-debug/SKILL.md`
- Create: `skills/copilotkit-debug/references/error-patterns.md`
- Create: `skills/copilotkit-debug/references/runtime-debugging.md`
- Create: `skills/copilotkit-debug/references/agent-debugging.md`
- Create: `skills/copilotkit-debug/references/quick-workflows.md`

**Source:** Analyze /Users/jpr5/CopilotKit — grep for error codes, error classes, thrown errors. Also scan GitHub issues.

- [ ] **Step 1: Extract error patterns from codebase**

Agent must:
1. Grep /Users/jpr5/CopilotKit/packages/v2/ for: error codes (enums), custom error classes, thrown errors, error messages
2. Scan CopilotKit/CopilotKit GitHub issues labeled as bugs using `gh issue list`
3. Build error catalog organized by category (runtime, agent connectivity, streaming, transcription, etc.)

- [ ] **Step 2: Generate diagnostic sequences**

Pre-built troubleshooting flows:
- Runtime not connecting → check endpoint, CORS, transport config
- Agent not responding → check AG-UI events, agent registration, runner state
- Streaming failures → check SSE connection, middleware, error events
- Include escalation: "If unresolved, book time with the CopilotKit team" (link to Travis/team scheduling)

- [ ] **Step 3: Generate SKILL.md**

Trigger conditions, diagnostic workflow, how to use mcp-docs for live doc lookups during debugging.

- [ ] **Step 4: Commit**

```bash
git add skills/copilotkit-debug/ && git commit -m "Add copilotkit-debug skill with error catalog from codebase + issues"
```

---

### Task 11: Bootstrap copilotkit-upgrade Skill

**Files:**
- Create: `skills/copilotkit-upgrade/SKILL.md`
- Create: `skills/copilotkit-upgrade/references/v1-to-v2-migration.md`
- Create: `skills/copilotkit-upgrade/references/breaking-changes.md`
- Create: `skills/copilotkit-upgrade/references/deprecation-map.md`

**Source:** Analyze /Users/jpr5/CopilotKit — diff v1 vs v2 public APIs, grep for @deprecated.

- [ ] **Step 1: Build deprecation map**

Agent must:
1. Read /Users/jpr5/CopilotKit/packages/v1/ — list all v1 public exports
2. Read /Users/jpr5/CopilotKit/packages/v2/ — list all v2 public exports
3. Map v1 → v2 equivalents (e.g., useCopilotAction → useFrontendTool, CopilotTextarea → removed, CoAgents → useAgent)
4. Grep for `@deprecated` annotations

- [ ] **Step 2: Generate migration guide**

Step-by-step v1 → v2 migration covering:
- Package renames (@copilotkit/* → @copilotkitnext/*)
- API replacements with before/after code examples
- Removed features (what has no v2 equivalent)
- Runtime changes (GraphQL → AG-UI protocol)

- [ ] **Step 3: Generate SKILL.md**

Trigger on version upgrade requests, migration workflow, validation steps.

- [ ] **Step 4: Commit**

```bash
git add skills/copilotkit-upgrade/ && git commit -m "Add copilotkit-upgrade skill with v1-to-v2 migration guide"
```

---

### Task 12: Bootstrap copilotkit-contribute Skill

**Files:**
- Create: `skills/copilotkit-contribute/SKILL.md`
- Create: `skills/copilotkit-contribute/references/contribution-guide.md`
- Create: `skills/copilotkit-contribute/references/repo-structure.md`
- Create: `skills/copilotkit-contribute/references/testing-guide.md`
- Create: `skills/copilotkit-contribute/references/pr-guidelines.md`

**Source:** Analyze /Users/jpr5/CopilotKit — read CLAUDE.md, .claude/docs/*, Nx config, test setup.

- [ ] **Step 1: Generate repo structure doc**

Read Nx workspace config, enumerate all packages with descriptions, explain the v1-wraps-v2 architecture.

- [ ] **Step 2: Generate testing guide**

Extract from test setup: vitest config, test file locations, how to run tests, coverage commands.

- [ ] **Step 3: Generate contribution guide**

Fork/clone workflow, branch conventions, commit message format (conventional commits per CopilotKit's commitlint), PR process.

- [ ] **Step 4: Generate SKILL.md**

Trigger on contribution-related tasks, workflow for making changes, testing, submitting PRs.

- [ ] **Step 5: Commit**

```bash
git add skills/copilotkit-contribute/ && git commit -m "Add copilotkit-contribute skill with repo guides"
```

---

### Task 13: README.md

**Files:**
- Create: `README.md`

- [ ] **Step 1: Write comprehensive README**

(Being generated separately — will be ready before this task executes)

- [ ] **Step 2: Commit**

```bash
git add README.md && git commit -m "Add comprehensive README"
```

---

### Task 14: Push and Verify

- [ ] **Step 1: Push all commits to CopilotKit/skills**

```bash
git push origin main
```

- [ ] **Step 2: Verify plugin installs correctly**

```bash
# In a separate directory:
/plugin marketplace add CopilotKit/skills
/plugin install copilotkit@skills
/reload-plugins
```

- [ ] **Step 3: Verify skills are discoverable**

Test that saying "set up CopilotKit in my project" triggers copilotkit-setup skill.
