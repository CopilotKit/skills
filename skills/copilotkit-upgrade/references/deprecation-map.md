# CopilotKit v1 Deprecation Map

Complete mapping of every deprecated v1 API to its v2 replacement.

## Hooks

| v1 Hook | v1 Package | v2 Replacement | v2 Package | Status |
|---------|-----------|---------------|-----------|--------|
| `useCopilotAction` | `@copilotkit/react-core` | `useFrontendTool` | `@copilotkitnext/react` | Renamed + new parameter format (Zod) |
| `useCopilotReadable` | `@copilotkit/react-core` | `useAgentContext` | `@copilotkitnext/react` | Renamed, `parentId` removed |
| `useCopilotChat` | `@copilotkit/react-core` | `useAgent` | `@copilotkitnext/react` | Replaced (different API) |
| `useCoAgent` | `@copilotkit/react-core` | `useAgent` | `@copilotkitnext/react` | Renamed, different return type |
| `useCoAgentStateRender` | `@copilotkit/react-core` | `useRenderToolCall` / `useRenderActivityMessage` | `@copilotkitnext/react` | Split into two hooks |
| `useLangGraphInterrupt` | `@copilotkit/react-core` | `useInterrupt` | `@copilotkitnext/react` | Renamed + new API |
| `useCopilotChatSuggestions` | `@copilotkit/react-core` | `useConfigureSuggestions` + `useSuggestions` | `@copilotkitnext/react` | Split into two hooks |
| `useCopilotAdditionalInstructions` | `@copilotkit/react-core` | `useAgentContext` | `@copilotkitnext/react` | Use description/value context |
| `useMakeCopilotDocumentReadable` | `@copilotkit/react-core` | `useAgentContext` | `@copilotkitnext/react` | Pass content directly |
| `useCopilotRuntimeClient` | `@copilotkit/react-core` | `useCopilotKit` | `@copilotkitnext/react` | Access core via provider context |
| `useCopilotContext` | `@copilotkit/react-core` | `useCopilotKit` | `@copilotkitnext/react` | Returns `{ copilotkit }` |
| `useCopilotMessagesContext` | `@copilotkit/react-core` | -- | -- | Removed (use agent event stream) |
| `useCoAgentStateRenders` | `@copilotkit/react-core` | -- | -- | Removed (context no longer needed) |
| `useCopilotChatInternal` | `@copilotkit/react-core` | -- | -- | Internal, removed |
| `useCopilotChatHeadless_c` | `@copilotkit/react-core` | -- | -- | Internal, removed |
| `useCopilotAuthenticatedAction_c` | `@copilotkit/react-core` | -- | -- | Internal, removed |
| `useFrontendTool` | `@copilotkit/react-core` | `useFrontendTool` | `@copilotkitnext/react` | Same name, import path changes |
| `useHumanInTheLoop` | `@copilotkit/react-core` | `useHumanInTheLoop` | `@copilotkitnext/react` | Same name, import path changes |
| `useRenderToolCall` | `@copilotkit/react-core` | `useRenderToolCall` | `@copilotkitnext/react` | Same name, import path changes |
| `useDefaultTool` | `@copilotkit/react-core` | `useDefaultRenderTool` | `@copilotkitnext/react` | Renamed |
| `useLazyToolRenderer` | `@copilotkit/react-core` | -- | -- | Removed |
| `useChatContext` (react-ui) | `@copilotkit/react-ui` | `useCopilotChatConfiguration` | `@copilotkitnext/react` | Renamed |

## Components

| v1 Component | v1 Package | v2 Replacement | v2 Package | Status |
|-------------|-----------|---------------|-----------|--------|
| `CopilotKit` | `@copilotkit/react-core` | `CopilotKitProvider` | `@copilotkitnext/react` | Renamed |
| `CopilotChat` | `@copilotkit/react-ui` | `CopilotChat` | `@copilotkitnext/react` | Same name, new package |
| `CopilotPopup` | `@copilotkit/react-ui` | `CopilotPopup` | `@copilotkitnext/react` | Same name, new package |
| `CopilotSidebar` | `@copilotkit/react-ui` | `CopilotSidebar` | `@copilotkitnext/react` | Same name, new package |
| `CopilotTextarea` | `@copilotkit/react-textarea` | -- | -- | **Removed** |
| `CopilotDevConsole` | `@copilotkit/react-ui` | `CopilotKitInspector` | `@copilotkitnext/react` | Renamed |
| `Markdown` | `@copilotkit/react-ui` | -- | -- | Removed (use A2UI renderer) |
| `AssistantMessage` | `@copilotkit/react-ui` | `CopilotChatAssistantMessage` | `@copilotkitnext/react` | Renamed |
| `UserMessage` | `@copilotkit/react-ui` | `CopilotChatUserMessage` | `@copilotkitnext/react` | Renamed |
| `ImageRenderer` | `@copilotkit/react-ui` | -- | -- | Removed |
| `RenderSuggestionsList` | `@copilotkit/react-ui` | `CopilotChatSuggestionView` | `@copilotkitnext/react` | Renamed |
| `RenderSuggestion` | `@copilotkit/react-ui` | `CopilotChatSuggestionPill` | `@copilotkitnext/react` | Renamed |
| `CoAgentStateRendersProvider` | `@copilotkit/react-core` | -- | -- | Removed (no v2 equivalent) |
| `ThreadsProvider` | `@copilotkit/react-core` | -- | -- | Removed (threads managed by runtime) |

## Runtime Classes

| v1 Class/Function | v1 Package | v2 Replacement | v2 Package | Status |
|------------------|-----------|---------------|-----------|--------|
| `CopilotRuntime` | `@copilotkit/runtime` | `CopilotRuntime` | `@copilotkitnext/runtime` | Same name, different constructor API |
| `OpenAIAdapter` | `@copilotkit/runtime` | `BuiltInAgent({ model: "openai:..." })` | `@copilotkitnext/agent` | **Removed** |
| `AnthropicAdapter` | `@copilotkit/runtime` | `BuiltInAgent({ model: "anthropic:..." })` | `@copilotkitnext/agent` | **Removed** |
| `GoogleGenerativeAIAdapter` | `@copilotkit/runtime` | `BuiltInAgent({ model: "google:..." })` | `@copilotkitnext/agent` | **Removed** |
| `LangChainAdapter` | `@copilotkit/runtime` | Custom `AbstractAgent` | -- | **Removed** |
| `GroqAdapter` | `@copilotkit/runtime` | `BuiltInAgent` with Groq model | `@copilotkitnext/agent` | **Removed** |
| `UnifyAdapter` | `@copilotkit/runtime` | Custom `AbstractAgent` | -- | **Removed** |
| `OpenAIAssistantAdapter` | `@copilotkit/runtime` | Custom `AbstractAgent` | -- | **Removed** |
| `BedrockAdapter` | `@copilotkit/runtime` | `BuiltInAgent({ model: "vertex:..." })` | `@copilotkitnext/agent` | **Removed** |
| `OllamaAdapter` (experimental) | `@copilotkit/runtime` | Custom `AbstractAgent` | -- | **Removed** |
| `EmptyAdapter` | `@copilotkit/runtime` | -- | -- | **Removed** |
| `RemoteChain` | `@copilotkit/runtime` | -- | -- | **Removed** |
| `LangGraphAgent` | `@copilotkit/runtime` | `LangGraphAgent` | `@ag-ui/langgraph` | Moved to AG-UI package |
| `LangGraphHttpAgent` | `@copilotkit/runtime` | `LangGraphAgent` | `@ag-ui/langgraph` | Moved + renamed |

## Runtime Framework Integrations

| v1 Function | v1 Package | v2 Replacement | v2 Package | Status |
|------------|-----------|---------------|-----------|--------|
| `copilotRuntimeNextJSAppRouterEndpoint` | `@copilotkit/runtime` | `createCopilotEndpoint` | `@copilotkitnext/runtime` | **Removed** (use Hono) |
| `copilotRuntimeNextJSPagesRouterEndpoint` | `@copilotkit/runtime` | `createCopilotEndpoint` | `@copilotkitnext/runtime` | **Removed** (use Hono) |
| `CopilotRuntimeNodeExpressEndpoint` | `@copilotkit/runtime` | `createCopilotEndpointExpress` | `@copilotkitnext/runtime` | Renamed |
| `CopilotRuntimeNestEndpoint` | `@copilotkit/runtime` | `createCopilotEndpoint` | `@copilotkitnext/runtime` | **Removed** (use Hono) |
| `CopilotRuntimeNodeHttpEndpoint` | `@copilotkit/runtime` | `createCopilotEndpoint` | `@copilotkitnext/runtime` | **Removed** (use Hono) |

## Types

| v1 Type | v1 Package | v2 Replacement | v2 Package | Status |
|---------|-----------|---------------|-----------|--------|
| `CopilotKitProps` | `@copilotkit/react-core` | `CopilotKitProviderProps` | `@copilotkitnext/react` | Renamed |
| `CopilotContextParams` | `@copilotkit/react-core` | `CopilotKitContextValue` | `@copilotkitnext/react` | Renamed |
| `FrontendAction` | `@copilotkit/react-core` | `ReactFrontendTool` | `@copilotkitnext/react` | Renamed + restructured |
| `ActionRenderProps` | `@copilotkit/react-core` | `ReactToolCallRenderer` | `@copilotkitnext/react` | Renamed + restructured |
| `DocumentPointer` | `@copilotkit/react-core` | -- | -- | **Removed** |
| `SystemMessageFunction` | `@copilotkit/react-core` | -- | -- | **Removed** |
| `CopilotChatSuggestionConfiguration` | `@copilotkit/react-core` | `Suggestion` | `@copilotkitnext/core` | Renamed |
| `Parameter` | `@copilotkit/shared` | Zod schemas / `StandardSchemaV1` | `zod` / `@copilotkitnext/shared` | Replaced with schema-based |
| `CopilotServiceAdapter` | `@copilotkit/runtime` | `AbstractAgent` | `@ag-ui/client` | Replaced |
| `TextMessageEvents` | `@copilotkit/runtime` | -- | -- | **Removed** (@deprecated) |
| `ToolCallEvents` | `@copilotkit/runtime` | -- | -- | **Removed** (@deprecated) |
| `CustomEventNames` | `@copilotkit/runtime` | -- | -- | **Removed** (@deprecated) |
| `PredictStateTool` | `@copilotkit/runtime` | -- | -- | **Removed** (@deprecated) |

## v1 Props Marked @deprecated Within v1

These were already deprecated within v1 itself:

| Location | Deprecated API | Replacement |
|----------|---------------|-------------|
| `FrontendAction` | `disabled` | `available: "disabled"` |
| `ActionRenderProps` | `respond()` | Use `respond` (same, just documented differently) |
| `CopilotKitProps` | `guardrails_c` | Removed in v2 |
| `CopilotRuntime` | `onBeforeRequest` / `onAfterRequest` | `beforeRequestMiddleware` / `afterRequestMiddleware` |
| `useCopilotChat` | `visibleMessages` | Use AG-UI message stream |
| `useCopilotChat` | `appendMessage` | Use `sendMessage` or agent API |
| Chat component props | `AssistantMessage` / `UserMessage` / `Messages` render props | `RenderMessage` |
| `useA2UIStore` | `useA2UIStore` | `useA2UIContext` |
| `useA2UIStoreSelector` | `useA2UIStoreSelector` | `useA2UIContext` |
