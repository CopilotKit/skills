// File: src/app/page.tsx
// Next.js App Router frontend with CopilotKit provider and chat UI
//
// Prerequisites:
//   npm install @copilotkitnext/react @copilotkitnext/core
//
// Also add to layout.tsx:
//   import "@copilotkitnext/react/styles.css";

"use client";

import { CopilotKitProvider, CopilotChat } from "@copilotkitnext/react";

export default function Home() {
  return (
    <CopilotKitProvider runtimeUrl="/api/copilotkit" showDevConsole="auto">
      <div style={{ height: "100vh", margin: 0, padding: 0, overflow: "hidden" }}>
        <CopilotChat />
      </div>
    </CopilotKitProvider>
  );
}
