# LangGraph Python with Threads Integration

CopilotKit supports LangGraph Python agents with persistent conversation threads using CopilotKit Intelligence. This example demonstrates a collaborative todo list application with thread-based conversation history.

## Overview

This is the `langgraph-python-threads` pattern - a monorepo with a React frontend, Hono BFF (Backend for Frontend), and Python LangGraph agent, enhanced with CopilotKit Intelligence for persistent conversation threads. The agent can manipulate todo state while maintaining conversation history across sessions.

## Prerequisites

- Node.js 18+
- Python 3.12+
- OpenAI API key
- Docker (for threads/intelligence support)
- CopilotKit license token

## Architecture

This monorepo contains three main services plus supporting infrastructure:

| Service                   | Port | Description                                |
| ------------------------- | ---- | ------------------------------------------ |
| **Frontend** (`apps/app`) | 3000 | Vite + React app with CopilotKit chat UI   |
| **BFF** (`apps/bff`)      | 4000 | Hono server running the CopilotKit runtime |
| **Agent** (`apps/agent`)  | 8123 | Python LangGraph agent                     |

When threads are enabled, additional infrastructure runs via Docker Compose:

| Service          | Port       | Description                                                                                                                                       |
| ---------------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| **PostgreSQL**   | 5432       | Thread and event storage                                                                                                                          |
| **Redis**        | 6379       | Session/cache                                                                                                                                     |
| **Intelligence** | 4201, 4401 | All-in-one CopilotKit Intelligence container (app-api on 4201, realtime-gateway on 4401, plus thread-culler and db-migrations, under s6-overlay). |

## Dependencies

### Python Dependencies (apps/agent/pyproject.toml)

```toml
[project]
dependencies = [
    "copilotkit==0.1.86",
    "ag-ui-langgraph==0.0.22",
    "langchain==1.0.1",
    "langchain-openai>=1.1.0",
    "langgraph==1.0.5",
    "fastapi>=0.115.5",
    "uvicorn>=0.29.0",
    "python-dotenv>=1.0.0",
]
```

### Frontend Dependencies

```json
{
  "dependencies": {
    "@copilotkit/react-core": "1.57.0",
    "@copilotkit/runtime": "1.57.0",
    "react": "^19",
    "vite": "^7"
  }
}
```

## Project Structure

```
apps/
├── app/                         # Vite + React frontend
│   ├── src/
│   │   ├── App.tsx             # Main app with thread management
│   │   └── components/
│   │       ├── threads-drawer/ # Thread management UI
│   │       └── example-canvas/ # Todo list components
├── bff/                        # Hono BFF server
│   └── src/
│       └── server.ts           # CopilotKit runtime with Intelligence
├── agent/                      # Python LangGraph agent
│   ├── main.py                 # Agent definition
│   └── src/
│       ├── todos.py            # Todo management tools
│       └── query.py            # Data query tools
docker-compose.yml              # Intelligence infrastructure
```

## Key Files Walkthrough

### Agent Definition (apps/agent/main.py)

The agent uses CopilotKit's state management pattern with todo tools:

```python
from typing import TypedDict, Literal
from langgraph.graph import StateGraph
from langgraph.checkpoint.memory import MemorySaver
from langchain_openai import ChatOpenAI
from copilotkit import CopilotKitState
from src.todos import manage_todos, get_todos

class AgentState(CopilotKitState):
    todos: list[dict]

async def chat_node(state: AgentState, config):
    model = ChatOpenAI(model="gpt-4o")
    
    # Bind frontend tools and backend tools
    fe_tools = state.get("copilotkit", {}).get("actions", [])
    model_with_tools = model.bind_tools([*fe_tools, manage_todos, get_todos])
    
    system_message = f"You are a helpful assistant managing todos. Current todos: {state.get('todos', [])}"
    response = await model_with_tools.ainvoke([system_message, *state["messages"]], config)
    
    # Route tool calls appropriately
    if response.tool_calls and should_route_to_tool_node(response.tool_calls, fe_tools):
        return Command(goto="tool_node", update={"messages": response})
    return Command(goto="__end__", update={"messages": response})

workflow = StateGraph(AgentState)
workflow.add_node("chat_node", chat_node)
workflow.add_node("tool_node", ToolNode([manage_todos, get_todos]))
workflow.add_edge("tool_node", "chat_node")
workflow.set_entry_point("chat_node")

graph = workflow.compile(checkpointer=MemorySaver())
```

### Todo Tools (apps/agent/src/todos.py)

```python
from typing import TypedDict, Literal, List
from langchain.tools import tool
from copilotkit import ToolRuntime

class Todo(TypedDict):
    id: str
    title: str
    description: str
    emoji: str
    status: Literal["pending", "completed"]

@tool
def manage_todos(todos: List[Todo], runtime: ToolRuntime):
    """Manage the current todos."""
    # Ensure todos have unique IDs
    for todo in todos:
        if "id" not in todo or not todo["id"]:
            todo["id"] = str(uuid.uuid4())
    
    return Command(update={
        "todos": todos,
        "messages": [ToolMessage(content=f"Updated {len(todos)} todos")]
    })

@tool
def get_todos(runtime: ToolRuntime):
    """Get the current todos."""
    return runtime.state.get("todos", [])
```

### BFF with Intelligence (apps/bff/src/server.ts)

```typescript
import { serve } from "@hono/node-server";
import {
  CopilotRuntime,
  CopilotKitIntelligence,
  createCopilotHonoHandler,
} from "@copilotkit/runtime/v2";
import { LangGraphAgent } from "@copilotkit/runtime/langgraph";

const intelligence = new CopilotKitIntelligence({
  apiKey: process.env.INTELLIGENCE_API_KEY ?? "cpk_sPRVSEED_seed0privat0longtoken00",
  apiUrl: process.env.INTELLIGENCE_API_URL ?? "http://localhost:4201",
  wsUrl: process.env.INTELLIGENCE_GATEWAY_WS_URL ?? "ws://localhost:4401",
});

const agent = new LangGraphAgent({
  deploymentUrl: process.env.LANGGRAPH_DEPLOYMENT_URL ?? "http://localhost:8123",
  graphId: "sample_agent",
});

const app = createCopilotHonoHandler({
  basePath: "/api/copilotkit",
  runtime: new CopilotRuntime({
    intelligence,
    identifyUser: () => ({ id: "jordan-beamson", name: "Jordan Beamson" }),
    licenseToken: process.env.COPILOTKIT_LICENSE_TOKEN,
    agents: { default: agent },
  }),
});

serve({ fetch: app.fetch, port: 4000 });
```

### Frontend with Threads (apps/app/src/App.tsx)

```typescript
import { useState } from "react";
import {
  CopilotChat,
  CopilotChatConfigurationProvider,
  CopilotKit,
} from "@copilotkit/react-core/v2";
import { ThreadsDrawer } from "@/components/threads-drawer";
import { ExampleCanvas } from "@/components/example-canvas";

function HomePage() {
  const [threadId, setThreadId] = useState<string | undefined>(undefined);

  return (
    <div className="layout">
      <ThreadsDrawer
        agentId="default"
        threadId={threadId}
        onThreadChange={setThreadId}
      />
      <div className="mainPanel">
        <CopilotChatConfigurationProvider agentId="default" threadId={threadId}>
          <div className="chatSection">
            <CopilotChat />
          </div>
          <div className="canvasSection">
            <ExampleCanvas />
          </div>
        </CopilotChatConfigurationProvider>
      </div>
    </div>
  );
}

export default function App() {
  return (
    <CopilotKit runtimeUrl="/api/copilotkit">
      <HomePage />
    </CopilotKit>
  );
}
```

### Todo Canvas with Agent State (apps/app/src/components/example-canvas/index.tsx)

```typescript
import { useAgent } from "@copilotkit/react-core/v2";
import { TodoList } from "./todo-list";

export function ExampleCanvas() {
  const { agent } = useAgent();

  return (
    <div className="h-full overflow-y-auto">
      <div className="max-w-4xl mx-auto px-8 py-10 h-full">
        <TodoList
          todos={agent.state?.todos || []}
          onUpdate={(updatedTodos) => agent.setState({ todos: updatedTodos })}
          isAgentRunning={agent.isRunning}
        />
      </div>
    </div>
  );
}
```

## How It Connects to CopilotKit

This example demonstrates several key CopilotKit integration patterns:

### 1. Agent State Management
- **State Definition**: The agent defines `AgentState(CopilotKitState)` with a `todos` field
- **Bidirectional Sync**: Frontend reads via `agent.state.todos` and writes via `agent.setState()`
- **Tool Integration**: Agent tools like `manage_todos` can modify the same state

### 2. Thread Management
- **CopilotKit Intelligence**: Provides persistent thread storage and real-time synchronization
- **Thread UI**: The `ThreadsDrawer` component uses `useThreads()` hook for thread management
- **Thread Switching**: `CopilotChatConfigurationProvider` ensures chat and canvas share the same thread context

### 3. AG-UI Protocol
- **LangGraphAgent**: Connects to the Python agent via AG-UI protocol over HTTP
- **Tool Routing**: Frontend tools (via `useFrontendTool`) and backend tools coexist in the same agent
- **State Streaming**: Agent state changes stream to the frontend in real-time

### 4. Persistence Flow
1. User interaction updates `agent.state.todos` 
2. CopilotKit syncs state to Intelligence backend
3. Thread events are persisted to PostgreSQL
4. On thread resume, state is restored and synced back to frontend

## Running the Example

1. Install dependencies:
```bash
npm install
```

2. Set up environment:
```bash
cp .env.example .env
# Add OPENAI_API_KEY and COPILOTKIT_LICENSE_TOKEN
```

3. Get a license token:
```bash
copilotkit license -n my-project
```

4. Start all services:
```bash
npm run dev
```

This starts Docker Compose infrastructure, then runs the frontend, BFF, and agent concurrently. The application will be available at http://localhost:3000 with persistent thread support.

The key difference from basic LangGraph integration is the addition of CopilotKit Intelligence for threads, which enables conversation history to persist across browser sessions and provides a rich thread management UI.
