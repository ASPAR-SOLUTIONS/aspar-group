# ASPAR Agent OS Consolidation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Consolidate the verified ASPAR LangGraph/LangChain gate and the useful NOTORIA orchestration work into `ASPAR-SOLUTIONS/aspar-group` so Claude and ChatGPT use one repository and one shared execution area.

**Architecture:** `aspar-group` becomes the canonical repository. Active orchestration lives in `agent-os/`; the verified LangGraph pre-execution gate lives in `agent-os/langgraph/`; the older NOTORIA V1 monorepo is preserved under `archive/notoria-v1/` and is not active runtime. Shared ASPAR context and SOURCE LOCK files live at repository root so Claude and ChatGPT read the same durable context.

**Tech Stack:** Python 3.12, LangGraph, LangChain, pytest, PostgreSQL checkpointer, GitHub Actions, Claude Code agent files.

**Spec:** `agent-os/README.md`

## Global Constraints

- Canonical repository: `ASPAR-SOLUTIONS/aspar-group`.
- Shared runtime location: `agent-os/`.
- Do not activate legacy NOTORIA video/TTS/lipsync workers in the ASPAR runtime.
- Preserve source history by recording source repository/commit SHAs.
- SOURCE LOCK remains mandatory before visual execution.
- No image generation is part of this migration.

---

### Task 1: Establish shared repository structure

**Files:**
- Create: `agent-os/README.md`
- Create: `CLAUDE.md`
- Create/replace: root ASPAR context files

- [ ] Add the common Agent OS contract and source provenance.
- [ ] Put Claude and ChatGPT on the same repository-level context.
- [ ] Verify paths and source commit references.

### Task 2: Migrate verified LangGraph gate

**Files:**
- Create: `agent-os/langgraph/pyproject.toml`
- Create: `agent-os/langgraph/langgraph.json`
- Create: `agent-os/langgraph/src/aspar_agent/*`
- Create: `agent-os/langgraph/tests/test_preexecution_gate.py`

- [ ] Copy the already-tested source without behavior changes.
- [ ] Preserve PASS/STOP SOURCE LOCK routing.
- [ ] Add CI in the target repository.

### Task 3: Preserve legacy NOTORIA V1 safely

**Files:**
- Create: `archive/notoria-v1/` from source tree commit `8486a7d577631fca6434fcac33217c870d629c9d`.

- [ ] Preserve the old orchestrator/workers for reference.
- [ ] Mark it legacy and non-active.

### Task 4: Unify Claude workspace

**Files:**
- Create: `.claude/agents/` from the existing Claude branch where useful.

- [ ] Keep Claude agent definitions accessible in the same repository.
- [ ] Make `CLAUDE.md` point to `agent-os/` and root context.

### Task 5: Verification

- [ ] Open a PR from `consolidate/agent-os-notoria` to `main`.
- [ ] Run GitHub Actions tests for `agent-os/langgraph`.
- [ ] Confirm pytest and smoke test PASS before merge.
- [ ] Do not claim completion until CI evidence is available.
