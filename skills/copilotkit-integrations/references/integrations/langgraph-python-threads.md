# LangGraph Python Threads Integration

CopilotKit integrates with LangGraph Python agents using the AG-UI protocol for streaming agent state and tool execution. This example demonstrates thread-based conversation persistence using CopilotKit Intelligence infrastructure.

## Overview

The `langgraph-python-threads` example is a monorepo showcasing:
- **Frontend**: Next.js app with CopilotKit chat UI and threads drawer
- **BFF** (Backend for Frontend): Hono server running CopilotKit runtime with Intelligence
- **Agent**: Python LangGraph agent with todo management capabilities
- **Intelligence Infrastructure**: PostgreSQL, Redis, and CopilotKit Intelligence services for thread persistence

## Prerequisites

- Node.js 18+
- Python 3.8+
- Docker and Docker Compose
- [pnpm](https://pnpm.io/installation)
- OpenAI API Key
- CopilotKit license token

## Project Structure

```
apps/
├── app/                    # Next.js frontend
│   ├── src/
│   │   ├── app/
│   │   │   ├── page.tsx           # Main page with threads UI
│   │   │   └── layout.tsx         # Root layout with providers
│   │   └── components/
│   │       ├── threads-drawer/    # Thread management UI
│   │       ├── example-canvas/    # Todo list components
│   │       └── example-layout/    # Chat + app layout
├── bff/                    # Backend for Frontend
│   └── src/
│       └── server.ts              # Hono server with Intelligence
├── agent/                  # Python LangGraph agent
│   ├── main.py                    # Agent entry point
│   └── src/
│       ├── todos.py               # Todo tools and state
│       └── query.py               # Data query tool
└── docker-compose.yml             # Intelligence infrastructure
```

## Dependencies

### Frontend Dependencies

```json
{
  "dependencies": {
    "@copilotkit/react-core": "latest",
    "next": "latest",
    "react": "latest"
  }
}
```

### BFF Dependencies

```json
{
  "dependencies": {
    "@copilotkit/runtime": "latest",
    "@hono/node-server": "^1.13.6",
    "hono": "^4.7.11"
  }
}
```

### Python Agent Dependencies

```toml
[project]
dependencies = [
    "copilotkit==0.1.78",
    "langchain==1.0.1",
    "langchain-openai>=1.1.0",
    "langgraph==1.0.5",
    "fastapi>=0.115.5",
    "uvicorn>=0.29.0",
    "python-dotenv>=1.0.0"
]
```

## Key Files Walkthrough

### Agent Definition (`apps/agent/main.py`)

The agent extends basic LangGraph functionality with CopilotKit state management:

```python
import uuid
from typing import TypedDict, Literal
from langchain.tools import tool
from langchain_core.messages import SystemMessage, ToolMessage
from langchain_openai import ChatOpenAI
from langgraph.graph import StateGraph
from langgraph.checkpoint.memory import MemorySaver
from copilotkit import CopilotKitState
from src.todos import Todo

class AgentState(CopilotKitState):
    todos: list[Todo]

@tool
def manage_todos(todos: list[Todo]) -> dict:
    """Manage the current todos list."""
    # Ensure todos have unique IDs
    for todo in todos:
        if not todo.get("id"):
            todo["id"] = str(uuid.uuid4())
    
    return {
        "todos": todos,
        "messages": [ToolMessage(content=f"Updated {len(todos)} todos", tool_call_id="manage_todos")]
    }

async def chat_node(state: AgentState):
    model = ChatOpenAI(model="gpt-4o")
    
    # Get frontend actions from CopilotKit state
    fe_actions = state.get("copilotkit", {}).get("actions", [])
    model_with_tools = model.bind_tools([manage_todos, *fe_actions])
    
    system_message = SystemMessage(
        content=f"You are a helpful todo assistant. Current todos: {state.get('todos', [])}"
    )
    
    response = await model_with_tools.ainvoke([system_message, *state["messages"]])
    return {"messages": [response]}

# Build the graph
workflow = StateGraph(AgentState)
workflow.add_node("chat_node", chat_node)
workflow.set_entry_point("chat_node")
workflow.set_finish_point("chat_node")

graph = workflow.compile(checkpointer=MemorySaver())
```

### BFF Server (`apps/bff/src/server.ts`)

The BFF connects the frontend to both the LangGraph agent and CopilotKit Intelligence:

```typescript
import { serve } from "@hono/node-server";
import {
  CopilotRuntime,
  CopilotKitIntelligence,
  createCopilotEndpoint,
} from "@copilotkit/runtime/v2";
import { LangGraphAgent } from "@copilotkit/runtime/langgraph";

// Intelligence configuration for threads
const intelligence = new CopilotKitIntelligence({
  apiKey: process.env.INTELLIGENCE_API_KEY || "cpk_sPRVSEED_seed0privat0longtoken00",
  apiUrl: process.env.INTELLIGENCE_API_URL || "http://localhost:4201",
  wsUrl: process.env.INTELLIGENCE_GATEWAY_WS_URL || "ws://localhost:4401",
  organizationId: process.env.INTELLIGENCE_ORGANIZATION_ID || "casa-de-erlang",
});

// Agent connection
const agent = new LangGraphAgent({
  deploymentUrl: process.env.LANGGRAPH_DEPLOYMENT_URL || "http://localhost:8123",
  graphId: "sample_agent",
  langsmithApiKey: process.env.LANGSMITH_API_KEY || "",
});

// Runtime with Intelligence and agent
const runtime = new CopilotRuntime({
  intelligence,
  identifyUser: () => ({ id: "jordan-beamson" }),
  licenseToken: process.env.COPILOTKIT_LICENSE_TOKEN,
  agents: { default: agent },
  a2ui: { injectA2UITool: true },
});

const endpoint = createCopilotEndpoint({
  runtime,
  basePath: "/api/copilotkit",
});

serve({ fetch: endpoint.fetch, port: 4000 });
```

### Frontend Layout (`apps/app/src/app/layout.tsx`)

```typescript
"use client";

import "./globals.css";
import "@copilotkit/react-core/v2/styles.css";
import { CopilotKitProvider } from "@copilotkit/react-core/v2";

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <CopilotKitProvider
          runtimeUrl={
            process.env.NEXT_PUBLIC_BFF_URL ||
            "http://localhost:4000/api/copilotkit"
          }
        >
          {children}
        </CopilotKitProvider>
      </body>
    </html>
  );
}
```

### Main Page with Threads (`apps/app/src/app/page.tsx`)

```typescript
"use client";

import { useState } from "react";
import { ExampleLayout } from "@/components/example-layout";
import { ExampleCanvas } from "@/components/example-canvas";
import { ThreadsDrawer } from "@/components/threads-drawer";
import { CopilotChat } from "@copilotkit/react-core/v2";

export default function HomePage() {
  const [threadId, setThreadId] = useState<string | undefined>(undefined);

  return (
    <div className="layout">
      <ThreadsDrawer
        agentId="default"
        threadId={threadId}
        onThreadChange={setThreadId}
      />
      <div className="mainPanel">
        <ExampleLayout
          chatContent={
            <CopilotChat
              agentId="default"
              threadId={threadId}
              input={{ disclaimer: () => null, className: "pb-6" }}
            />
          }
          appContent={<ExampleCanvas />}
        />
      </div>
    </div>
  );
}
```

### Threads Management (`apps/app/src/components/threads-drawer/threads-drawer.tsx`)

The threads drawer uses CopilotKit's `useThreads` hook to manage conversation history:

```typescript
"use client";

import { useThreads } from "@copilotkit/react-core/v2";

export default function ThreadsDrawer({
  agentId,
  threadId,
  onThreadChange,
}: ThreadsDrawerProps) {
  const [showArchived, setShowArchived] = useState(false);

  const {
    threads,
    archiveThread,
    deleteThread,
    error,
    isLoading,
    hasMoreThreads,
    isFetchingMoreThreads,
    fetchMoreThreads,
  } = useThreads({
    agentId,
    includeArchived: showArchived,
    limit: 20,
  });

  // Render threads list with actions
  return (
    <aside className="threadsDrawer">
      {/* ... drawer UI ... */}
      {threads.map((thread) => (
        <button
          key={thread.id}
          onClick={() => onThreadChange(thread.id)}
          className={threadId === thread.id ? "selected" : ""}
        >
          {thread.name || "New thread"}
          <span>{formatThreadTimestamp(thread.updatedAt)}</span>
        </button>
      ))}
    </aside>
  );
}
```

## How it Connects to CopilotKit

### 1. Thread Persistence
- **CopilotKitIntelligence** provides thread storage and management
- **useThreads** hook manages thread CRUD operations
- **CopilotChat** automatically loads/saves messages to the active thread

### 2. Agent State Synchronization
- Agent extends **CopilotKitState** to include frontend state (todos)
- Frontend uses **useAgent** to read/write agent state
- State changes sync bidirectionally via the AG-UI protocol

### 3. Tool Integration
- Agent receives frontend actions from `copilotkit.actions`
- **useFrontendTool** registers frontend-only tools
- **manage_todos** tool updates both agent state and database

### 4. Infrastructure Communication
- **LangGraphAgent** connects to the Python agent via AG-UI
- **Intelligence services** handle thread persistence, events, and real-time updates
- **BFF** orchestrates between frontend, agent, and Intelligence

## Running the Example

1. **Install dependencies:**
   ```bash
   pnpm install
   ```

2. **Set up environment:**
   ```bash
   cp .env.example .env
   # Edit .env with your OpenAI API key and license token
   ```

3. **Get CopilotKit license:**
   ```bash
   copilotkit license -n my-project
   # Add the COPILOTKIT_LICENSE_TOKEN to .env
   ```

4. **Start Intelligence infrastructure:**
   ```bash
   docker compose up -d --wait
   ```

5. **Start all services:**
   ```bash
   pnpm dev
   ```

This starts:
- Frontend at http://localhost:3000
- BFF at http://localhost:4000
- Agent at http://localhost:8123
- Intelligence services (PostgreSQL, Redis, API, Gateway)

The example demonstrates thread-based conversation persistence with agent-driven todo management, showcasing how CopilotKit Intelligence enables durable, multi-session AI interactions.
