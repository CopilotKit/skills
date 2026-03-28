---
name: copilotkit-self-update
description: Use when the user wants to update, refresh, or reinstall CopilotKit skills. Triggers on "update copilotkit skills", "refresh skills", "skills are stale", "skills are outdated", "update copilotkit", "get latest skills", "my copilotkit knowledge is wrong", "copilotkit APIs changed", "skills seem old", "wrong API names", "reinstall skills", "skills not working right".
user_invocable: true
argument_hint: ""
---

# Update CopilotKit Skills

Run this command to pull the latest CopilotKit skills from GitHub:

```bash
npx skills add copilotkit/skills -y
```

This does a fresh clone every time — it always gets the latest version regardless of what's cached.

After the command completes, **start a new Claude Code session** to pick up the changes. There is no mid-session reload for skills installed this way.

## When to Suggest This

- User says the skills have wrong API names or outdated information
- User reports that a CopilotKit API doesn't match what the skill says
- User explicitly asks to update or refresh skills
- A new CopilotKit version was released and skills may be stale
