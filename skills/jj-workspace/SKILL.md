---
name: jj-workspace
description: Use Jujutsu workspaces to isolate task changes in a separate working copy
---

# Jujutsu Workspace Isolation

Use this skill when starting any new task that involves code changes. Jujutsu workspaces provide isolated working copies that share the same repository history, allowing you to work on tasks without affecting the main workspace.

## Workflow

### 1. Starting a New Task

When beginning a new task, create a dedicated workspace:

```bash
# Create a workspace with the agent- prefix and a descriptive name based on the task
jj workspace add agent-<task-name>

# Navigate to the new workspace
cd agent-<task-name>
```

**Naming conventions for workspaces:**
- Always use the `agent-` prefix to indicate the workspace was created by an agent
- Use lowercase with hyphens
- Keep it short but descriptive
- Include a ticket/issue number if applicable
- Examples: `agent-fix-auth-bug`, `agent-feature-user-export`, `agent-issue-1234`

### 2. Working in the Workspace

Perform all your work in the isolated workspace:

```bash
# Check current status
jj status

# View the change description
jj log

# Make changes to files...

# Describe what you're working on
jj describe -m "description of the change"

# Create a new commit when ready
jj commit -m "commit message"
```

### 3. Completing the Task

After finishing the work, inform the user that the task is complete and ask for confirmation before cleanup.

**Do NOT clean up the workspace automatically.** Wait for explicit user confirmation.

### 4. Cleanup (After User Confirmation)

Only after the user confirms the work is acceptable:

```bash
# Return to the main workspace
cd ..

# Remove the task workspace
jj workspace forget <workspace-name>

# Optionally remove the workspace directory
rm -rf agent-<task-name>
```

## Important Notes

- Always create a new workspace at the START of a task
- The workspace directory is created as a child to the main repo 
- All workspaces share the same commit history - commits made in one workspace are visible in others
- Never forget/delete a workspace without explicit user confirmation
- If you need to switch back to check something in the main workspace, just `cd` there - the task workspace will persist

## Commands Reference

| Command | Description |
|---------|-------------|
| `jj workspace add <path>` | Create a new workspace |
| `jj workspace list` | List all workspaces |
| `jj workspace forget <name>` | Remove a workspace (keeps commits) |
| `jj status` | Show working copy status |
| `jj log` | Show commit history |
| `jj describe -m "msg"` | Set description for current change |
| `jj commit -m "msg"` | Create a new commit |
| `jj new` | Start a new change on top of current |
