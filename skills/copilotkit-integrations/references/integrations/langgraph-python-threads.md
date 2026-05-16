# LangGraph Python Threads Integration

CopilotKit supports LangGraph Python agents with durable conversation threads using CopilotKit Intelligence. This example demonstrates a complete monorepo setup with frontend, BFF (Backend for Frontend), and Python agent services, plus Docker infrastructure for thread persistence.

## Overview

This is the `langgraph-python-threads` pattern. It extends the basic LangGraph Python integration with persistent conversation threads that survive page reloads and work across devices. The agent manages todo state while threads maintain conversation history.

### Architecture Components

- **Frontend** (`apps/app`): Vite + React with CopilotKit v2 chat UI and threads drawer
- **BFF** (`apps/bff`): Hono server running CopilotKit runtime with Intelligence integration  
- **Agent** (`apps/agent`): Python LangGraph agent with todo management tools
- **Intelligence**: Docker-based thread persistence (PostgreSQL + Redis + CopilotKit Intelligence services)

## Prerequisites

- Node.js 18+
- Python 3.12+
- Docker & Docker Compose
- OpenAI API key
- CopilotKit license token

## Dependencies

### Python Dependencies (`apps/agent/pyproject.toml`)

```toml
[project]
dependencies = [
  "copilotkit==0.1.86",
  "ag-ui-langgraph[fastapi]==0.0.22", 
  "langchain==1.0.1",
  "langchain-openai>=1.1.0",
  "langgraph==1.0.5",
  "fastapi>=0.115.5",
  "uvicorn>=0.29.0",
  "python-dotenv>=1.0.0",
]
```

### Frontend Dependencies (`apps/app/package.json`)

```json
{
  "dependencies": {
    "@copilotkit/react-core": "1.57.0",
    "@copilotkit/a2ui-renderer": "latest",
    "react": "^19",
    "vite": "^7"
  }
}
```

### BFF Dependencies (`apps/bff/package.json`)

```json
{
  "dependencies": {
    "@copilotkit/runtime": "1.57.0",
    "@hono/node-server": "^1.13.6",
    "hono": "^4.7.11"
  }
}
```

## Project Structure

```
apps/
├── app/                    # Vite React frontend  
│   ├── src/
│   │   ├── App.tsx        # Main app with threads integration
│   │   ├── components/
│   │   │   ├── threads-drawer/     # Thread management UI
│   │   │   ├── example-canvas/     # Todo list UI  
│   │   │   └── example-layout/     # Chat + app layout
│   │   └── hooks/         # CopilotKit integration hooks
├── bff/                   # Backend for Frontend
│   └── src/server.ts      # Hono + CopilotRuntime + Intelligence
├── agent/                 # Python LangGraph agent
│   ├── main.py           # Agent graph definition
│   └── src/
│       ├── todos.py      # Todo management tools
│       └── query.py      # Data query tools
docker-compose.yml         # Intelligence infrastructure
serve.py                  # Docker agent wrapper
```

## Key Files Walkthrough

### Agent Definition (`apps/agent/main.py`)

The agent uses CopilotKit's AG-UI protocol with todo state management:

```python
from typing import TypedDict, List, Literal
from copilotkit import CopilotKitState
from langchain.tools import tool
from langchain_core.runnables import RunnableConfig  
from langchain_openai import ChatOpenAI
from langgraph.graph import StateGraph
from langgraph.checkpoint.memory import MemorySaver
from src.todos import manage_todos, get_todos
from src.query import query_data

class Todo(TypedDict):
    id: str
    title: str  
    description: str
    emoji: str
    status: Literal["pending", "completed"]

class AgentState(CopilotKitState):
    todos: List[Todo]

async def chat_node(state: AgentState, config: RunnableConfig):
    model = ChatOpenAI(model="gpt-4o")
    
    # Bind both frontend tools and backend tools
    fe_tools = state.get("copilotkit", {}).get("actions", [])
    model_with_tools = model.bind_tools([*fe_tools, manage_todos, get_todos, query_data])
    
    response = await model_with_tools.ainvoke(state["messages"], config)
    return {"messages": response}

# Create and compile the graph
workflow = StateGraph(AgentState)
workflow.add_node("chat_node", chat_node)
workflow.set_entry_point("chat_node")

graph = workflow.compile(checkpointer=MemorySaver())
```

Key pattern: The agent extends `CopilotKitState` to access frontend tools via `state.copilotkit.actions` and manages todo state through dedicated tools.

### Todo Management Tools (`apps/agent/src/todos.py`)

```python
from typing import List
from langchain.tools import tool
from copilotkit import ToolRuntime
from main import Todo

@tool
def manage_todos(todos: List[Todo], runtime: ToolRuntime):
    """Manage the current todos - add, update, or reorganize tasks."""
    # Ensure all todos have unique IDs
    for todo in todos:
        if "id" not in todo or not todo["id"]:
            todo["id"] = str(uuid.uuid4())
    
    # Update agent state 
    return runtime.update_state({"todos": todos})

@tool  
def get_todos(runtime: ToolRuntime) -> List[Todo]:
    """Get the current todos list."""
    return runtime.state.get("todos", [])
```

### Frontend Integration (`apps/app/src/App.tsx`)

The frontend uses CopilotKit v2 with threads support:

```typescript
import { useState } from "react";
import {
  CopilotChat,
  CopilotChatConfigurationProvider, 
  CopilotKit,
} from "@copilotkit/react-core/v2";
import { ThreadsDrawer } from "@/components/threads-drawer";
import { ExampleLayout } from "@/components/example-layout";
import { ExampleCanvas } from "@/components/example-canvas";

function HomePage() {
  const [threadId, setThreadId] = useState<string | undefined>(undefined);

  return (
    <div className={styles.layout}>
      <ThreadsDrawer
        agentId="default"
        threadId={threadId}
        onThreadChange={setThreadId}
      />
      <div className={styles.mainPanel}>
        {/* Shared threadId for chat and canvas */}
        <CopilotChatConfigurationProvider agentId="default" threadId={threadId}>
          <ExampleLayout
            chatContent={<CopilotChat />}
            appContent={<ExampleCanvas />}
          />
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

### Agent State Integration (`apps/app/src/components/example-canvas/index.tsx`)

The todo canvas reads from and writes to agent state:

```typescript
import { useAgent } from "@copilotkit/react-core/v2";
import { TodoList } from "./todo-list";

export function ExampleCanvas() {
  const { agent } = useAgent();

  return (
    <div className="h-full overflow-y-auto">
      <TodoList
        todos={agent.state?.todos || []}
        onUpdate={(updatedTodos) => agent.setState({ todos: updatedTodos })}
        isAgentRunning={agent.isRunning}
      />
    </div>
  );
}
```

### BFF Runtime with Intelligence (`apps/bff/src/server.ts`)

The BFF integrates CopilotKit Intelligence for thread persistence:

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

## How It Connects to CopilotKit

### AG-UI Protocol Communication

1. **Frontend** uses `useAgent()` hook to connect to agent via AG-UI protocol over Server-Sent Events
2. **BFF** runs `CopilotRuntime` with `LangGraphAgent` pointing to the Python agent  
3. **Agent** serves AG-UI protocol via `ag-ui-langgraph` and `LangGraphAGUIAgent`
4. **Intelligence** persists threads, messages, and state across sessions

### State Synchronization

1. **User interactions** (adding/editing todos) → `agent.setState({ todos: [...] })`
2. **Agent state updates** → CopilotKit syncs to backend via AG-UI
3. **Agent tool calls** → `manage_todos` tool modifies agent state
4. **State changes** → Sync back to frontend, React re-renders UI
5. **Thread persistence** → Intelligence stores state snapshots for thread resume

### Thread Management

The threads drawer uses CopilotKit's thread management APIs:

```typescript
import { useThreads } from "@copilotkit/react-core/v2";

const {
  threads,
  archiveThread,
  deleteThread, 
  hasMoreThreads,
  fetchMoreThreads,
} = useThreads({ agentId, includeArchived: false });
```

## Running the Example

1. **Install dependencies:**
```bash
npm install
```

2. **Set up environment variables:**
```bash
cp .env.example .env
# Add OPENAI_API_KEY and COPILOTKIT_LICENSE_TOKEN
```

3. **Get license token:**
```bash
npx copilotkit license -n my-project
```

4. **Start all services:**
```bash
npm run dev
```

This starts:
- Docker Compose infrastructure (PostgreSQL + Redis + Intelligence)
- Frontend on port 3000
- BFF on port 4000  
- Python agent on port 8123

The app supports persistent threads - conversations survive page reloads and can be resumed later. The todo state is maintained per-thread, so different threads can have different todo lists.

## Thread Architecture

Unlike basic CopilotKit patterns, this example includes durable thread persistence:

- **PostgreSQL** stores thread metadata and message history
- **Redis** provides session caching
- **Intelligence services** handle thread lifecycle and state snapshots
- **Frontend threads drawer** provides thread switching UI

Threads enable multi-conversation workflows where users can maintain separate todo lists and conversation contexts across different threads.
