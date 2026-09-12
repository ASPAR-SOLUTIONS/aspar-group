# HANDOFF.md

Use this file only for concise continuation context between substantial sessions or agents. Replace the active handoff when a newer one supersedes it; durable strategy belongs elsewhere.

## ACTIVE HANDOFF

**Date:** 2026-09-12
**From:** ChatGPT
**To:** Claude Code / next ASPAR agent

### Objective
Use `ASPAR-SOLUTIONS/aspar-group` as the canonical shared repository. The active pre-execution runtime is `agent-os/langgraph/`; all local Claude Code/MCP and downstream Canva/image/social execution must pass through it before side effects.

### Read first
1. `ASPAR_CONTEXT.md`
2. `CURRENT_STATE.md`
3. `WORKBOARD.md`
4. `agent-os/README.md`
5. Relevant brand `SOURCE_LOCK.md`

### What changed
- Created the shared `agent-os/` location in ASPAR Group.
- Migrated the verified LangGraph/LangChain gate from `mynotoriastudio-cmd/Notoria-studio` source commit `6124e45037950f4424eef5ce4f8a1f5cbd7f0e0f`.
- Preserved the former NOTORIA V1 monorepo under `archive/notoria-v1/` as non-active legacy.
- Brought existing Claude agent definitions under `.claude/agents/` in the same branch.
- Added target-repository CI for the migrated gate.

### Decisions made
- Canonical repository: `ASPAR-SOLUTIONS/aspar-group`.
- Shared active runtime location: `agent-os/`.
- Legacy NOTORIA video/TTS/lipsync runtime must not be activated by default.
- SOURCE LOCK remains mandatory; STOP bypasses plan/execute.
- `execute` remains preflight-only; actual external side effects stay downstream.

### Blockers
- Local Mac/Claude Code/MCP caller wiring still requires local verification after the repository migration is merged.

### Next exact action
1. Confirm CI on PR #4 is green after canonical root context/SOURCE LOCK is present.
2. Merge PR #4 only after green tests and smoke.
3. Sync the canonical repository locally.
4. From `agent-os/langgraph/`, install `.[dev,postgres]`, run pytest and smoke, then start `langgraph dev --no-browser`.
5. Point Claude Code/MCP and downstream executors at this gate.

## HANDOFF TEMPLATE

```markdown
**Date:** YYYY-MM-DD
**From:** agent/session
**To:** agent/session

### Objective

### What changed

### Decisions made

### Files changed

### Blockers

### Next exact action
```
