---
name: windows-guest-experiment
description: Route and interpret experiments where an Agent needs a Windows Guest/VM. Prefer a mature sandbox/runtime for task lifecycle and artifacts; use direct Hyper-V/VirtualBox control only for capabilities the runtime does not provide, such as precise debugger or GUI interaction.
---

# Windows Guest Experiment

This Skill is an **Agent policy and backend router**, not a workflow engine.

## What the Agent owns

The Agent owns only the parts that require investigation judgment:

- `goal_ref`: which current task/project contract defines success;
- `subject`: what object/process/code is actually being observed;
- `interventions`: what was deliberately changed, injected, patched, attached, or forced;
- interpretation of the returned evidence.

The execution platform, Agent client, harness/runner, VM label, transport, timestamps, PID, retry history, locks, and artifact bookkeeping are runtime/provenance details. Do not turn them into business evidence classes.

## Backend rule

1. If an existing sandbox/runtime already owns task state, VM lifecycle, retry/recovery, result storage, and artifacts, use it directly.
2. Do not duplicate that runtime with custom STATE/events/lease/handoff protocols.
3. Use the direct-lab path only when the requested capability is not provided by the mature runtime, for example precise CDB attach/breakpoint/memory work or an interactive GUI path.
4. A low-level adapter such as PowerShell Direct, VBoxManage, SSH, or SMB is **not** a workflow runtime by itself.

Read `references/runbook.md` for the execution path and only the selected backend section of `references/adapters.md`.

## Evidence rules

- The current task/project contract outranks generated summaries, memories, old status files, and prior assistant prose.
- Prove what actually happened, not what was configured: armed/configured/requested != hit/applied/observed.
- Keep one run's causal claims inside that run. Different runs may be compared, not spliced into one event chain.
- The subject matters more than the runner. A function extracted from a target is a different subject from the full target process even if the same Agent launches both.
- Any intervention that may change behavior must be attached to the resulting claim.
- Unknown stays unknown. Timeout, transport loss, missing stdout, or invalid instrumentation are not business-negative results.
- A Guest-reported artifact is not acquired evidence until the runtime/Host actually has it.
- Harvest before rollback or destructive cleanup.

## Direct-lab fallback

Use the fallback only when no mature runtime covers the needed operation.

Before the real target, prove only the capabilities actually required by the experiment:

- command execution in the expected Guest context;
- artifact round-trip;
- detached lifetime for long jobs;
- debugger/observer smoke when instrumentation is required;
- interactive desktop smoke when GUI interaction is required.

Do not build a general scheduler around these checks. Reuse verified capabilities until the environment/context that justified them changes.

## Fallback run record

Only when no backend provides durable task state, use the small record in `assets/run-record.example.json`.

It records intent and conclusion, not all runtime bookkeeping.

## Final outcome

When the backend/project requires a normalized conclusion, use one of:

- POSITIVE
- NEGATIVE
- INCONCLUSIVE
- INVALID_INSTRUMENT
- INFRA_FAILURE

Do not invent a stronger conclusion than the observed evidence supports.
