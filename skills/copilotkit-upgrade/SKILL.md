---
name: copilotkit-upgrade
description: "Use when migrating a CopilotKit v1 application to v2 -- updating package imports, replacing deprecated hooks and components, switching from GraphQL runtime to AG-UI protocol runtime, and resolving breaking API changes."
---

# CopilotKit v1 to v2 Migration Skill

## Overview

CopilotKit v2 is a ground-up rewrite built on the AG-UI protocol (`@ag-ui/client` / `@ag-ui/core`). The v1 packages (`@copilotkit/*`) still exist as thin wrappers that delegate to v2 (`@copilotkitnext/*`) under the hood, but new code should target v2 directly.

## Migration Workflow

### 1. Audit Current Usage

Scan the codebase for all v1 imports and API usage:

```
@copilotkit/react-core    -> hooks, CopilotKit provider, types
@copilotkit/react-ui      -> CopilotChat, CopilotPopup, CopilotSidebar
@copilotkit/react-textarea -> CopilotTextarea (removed in v2)
@copilotkit/runtime       -> CopilotRuntime, service adapters, framework integrations
@copilotkit/runtime-client-gql -> GraphQL client, message types
@copilotkit/shared         -> utility types, constants
@copilotkit/sdk-js         -> LangGraph/LangChain SDK
```

### 2. Identify Deprecated APIs

Key hooks and components to find and replace:

| v1 API | v2 Replacement |
|--------|---------------|
| `useCopilotAction` | `useFrontendTool` |
| `useCopilotReadable` | `useAgentContext` |
| `useCopilotChat` | `useAgent` + `useSuggestions` |
| `useCoAgent` | `useAgent` |
| `useCoAgentStateRender` | `useRenderToolCall` / `useRenderActivityMessage` |
| `useLangGraphInterrupt` | `useInterrupt` |
| `useCopilotChatSuggestions` | `useConfigureSuggestions` + `useSuggestions` |
| `useCopilotAdditionalInstructions` | `useAgentContext` |
| `useMakeCopilotDocumentReadable` | `useAgentContext` |
| `CopilotKit` (provider) | `CopilotKitProvider` |
| `CopilotTextarea` | Removed -- use standard textarea + `useFrontendTool` |

### 3. Map to v2 Equivalents

Refer to `references/v1-to-v2-migration.md` for detailed before/after code examples.

### 4. Update Package Dependencies

Replace v1 packages with their v2 equivalents:

```
@copilotkit/react-core       -> @copilotkitnext/react
@copilotkit/react-ui          -> @copilotkitnext/react
@copilotkit/react-textarea    -> removed (no v2 equivalent)
@copilotkit/runtime           -> @copilotkitnext/runtime + @copilotkitnext/agent
@copilotkit/runtime-client-gql -> @ag-ui/client (re-exported by @copilotkitnext/react)
@copilotkit/shared            -> @copilotkitnext/shared
@copilotkit/sdk-js            -> @copilotkitnext/agent
```

### 5. Update Runtime Configuration

The v1 `CopilotRuntime` accepted service adapters (OpenAI, Anthropic, LangChain, etc.) and endpoint definitions. The v2 `CopilotRuntime` accepts AG-UI `AbstractAgent` instances directly.

**v1 pattern** (service adapter + endpoints):
```ts
import { CopilotRuntime, OpenAIAdapter } from "@copilotkit/runtime";
const runtime = new CopilotRuntime({ actions: [...] });
// used with copilotKitEndpoint() for Next.js, Express, etc.
```

**v2 pattern** (agents + Hono endpoint):
```ts
import { CopilotRuntime, createCopilotEndpoint } from "@copilotkitnext/runtime";
import { BuiltInAgent } from "@copilotkitnext/agent";
const runtime = new CopilotRuntime({
  agents: { myAgent: new BuiltInAgent({ model: "openai:gpt-4o" }) },
});
const app = createCopilotEndpoint({ runtime, basePath: "/api/copilotkit" });
```

### 6. Update Provider

**v1:**
```tsx
import { CopilotKit } from "@copilotkit/react-core";
<CopilotKit runtimeUrl="/api/copilotkit">
  {children}
</CopilotKit>
```

**v2:**
```tsx
import { CopilotKitProvider } from "@copilotkitnext/react";
<CopilotKitProvider runtimeUrl="/api/copilotkit">
  {children}
</CopilotKitProvider>
```

### 7. Verify

- Run the application and check for runtime errors
- Verify all agent interactions work (chat, tool calls, interrupts)
- Check that tool renderers display correctly
- Confirm suggestions load and display

## Quick Reference

| Concept | v1 | v2 |
|---------|----|----|
| Package scope | `@copilotkit/*` | `@copilotkitnext/*` |
| Protocol | GraphQL | AG-UI (SSE) |
| Provider component | `CopilotKit` | `CopilotKitProvider` |
| Define frontend tool | `useCopilotAction` | `useFrontendTool` |
| Share app state | `useCopilotReadable` | `useAgentContext` |
| Agent interaction | `useCoAgent` | `useAgent` |
| Handle interrupts | `useLangGraphInterrupt` | `useInterrupt` |
| Render tool calls | `useCopilotAction({ render })` | `useRenderToolCall` |
| Chat suggestions | `useCopilotChatSuggestions` | `useConfigureSuggestions` |
| Runtime class | `CopilotRuntime` (adapters) | `CopilotRuntime` (agents) |
| Endpoint setup | `copilotKitEndpoint()` | `createCopilotEndpoint()` |
| Agent definition | `LangGraphAgent` endpoint | `AbstractAgent` / `BuiltInAgent` |
| Chat components | `CopilotChat`, `CopilotPopup`, `CopilotSidebar` | `CopilotChat`, `CopilotPopup`, `CopilotSidebar` (from `@copilotkitnext/react`) |
