# WORKBOARD.md

Rule: maximum **3 items in NOW**. Everything else stays in NEXT, LATER or BLOCKED.

## NOW
1. Define and sell the first simple cash-generating offer(s) around Business Systems / Odoo / AI / ASPAR Solutions.
2. Record and publish the first founder-led master video, then repurpose it instead of building separate content factories.
3. Complete canonical Agent OS migration in `ASPAR-SOLUTIONS/aspar-group`, obtain green CI, then wire local Claude Code/MCP to `agent-os/langgraph/`.

## NEXT
- Validate pricing, delivery scope and contribution margin for the first sellable offer.
- Build one complete proof/demo around a real or representative business workflow.
- Simplify content production into one-source-to-many-outputs.
- Formalize the minimum client-facing ASPAR Agent scope versus internal delivery engine.
- Add concrete Drive/Canva/Odoo/Supabase source adapters only where an execution workflow requires them; keep the current injected-source interface as the boundary.

## LATER
- Mature proprietary ASPAR Business concepts after commercial traction and/or operating proof.
- Deeper cloud/local agent orchestration and scheduled multi-agent execution.
- Additional Supabase runtime components only when a concrete product need appears.
- More advanced content automation after repeated human-approved production reveals stable patterns.

## BLOCKED
- Full Brand Factory commercialization: blocked by lack of sufficient real operating proof and limited capital/time.
- Any promise of fully autonomous client operations: blocked until capability, permissions and reliability are demonstrated.

## Completed gate
The executable LangGraph + LangChain pre-execution gate is implemented. Its required path is:
`intake -> classify -> resolve_role -> resolve_brand -> source_router -> retrieve_context -> validate -> SOURCE_LOCK PASS/STOP -> plan -> execute(preflight) -> QA -> writeback`.

The gate is now being consolidated under `agent-os/langgraph/` in the canonical ASPAR Group repository. Visual Majdi requests STOP when canonical Canva/Drive sources are not resolved; factual claims STOP without verified evidence.

## Execution rule
Before adding a new NOW task, move or finish an existing NOW item. Do not use this file as an unlimited backlog.
