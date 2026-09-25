---
name: windows-guest-experiment
description: Execute, recover, or hand off experiments where a stable Host controls an unstable Windows Guest/VM. Use for VM snapshot/checkpoint runs, long-running Guest jobs, debugger/instrumentation runs, artifact harvesting, transport failures, safe retry after disconnects, or multi-agent control of the same VM. Do not use for ordinary static-only analysis that does not execute a Guest.
---

# Windows Guest Experiment

This is the canonical execution skill for Host to Windows Guest experiments.

## Load and execute in this order

Before any state-changing Guest or VM action:

1. Read references/runbook.md completely.
2. Run scripts/preflight.ps1 on a Windows Host when a shell is available. If it cannot be run, reproduce the same read-only capability checks manually.
3. After the backend is selected, read only the applicable sections of references/adapters.md.
4. When any canary or operation fails, consult references/failure-routing.md before retrying.
5. Read references/patterns.md only when changing this skill, choosing architecture, or explaining provenance.

Use assets/run-record.example.json only when the current platform has no native durable task/run state.
Run scripts/validate-run-record.py when using that fallback record.

## Autonomy policy

Continue autonomously when the next action is read-only, reversible, or already covered by a verified operation contract.

Stop and require human input only when at least one is true:

- required credentials are unavailable;
- target, VM, baseline, or authorization/scope cannot be uniquely resolved;
- a destructive action could erase the only remaining evidence;
- a non-idempotent operation is UNKNOWN and cannot be reconciled safely;
- two valid next actions have materially different evidence or preservation consequences and the task does not choose between them.

Do not stop merely because one transport failed, one command returned no stdout, or one preferred tool is missing. Route to the next verified adapter or classify the run.

## Core execution rules

1. Prefer platform-native task state, retry, lease/CAS, result server, and artifact APIs. Do not build a second runtime protocol beside CAPE/Cuckoo or another durable orchestrator.
2. Define the real objective and observable acceptance criteria before instrumentation.
3. Use a unique RUN_ID for every real launch. Never reuse a failed run directory.
4. Prove Control, Data, long-runner lifetime, and required instrumentation with benign canaries before the real target.
5. Treat Control, Data, and Completion as separate facts.
6. A state-changing operation must have a verification method before dispatch. After a disconnect, reconcile it as APPLIED / NOT_APPLIED / UNKNOWN before retrying.
7. Guest-reported files are not evidence until the Host/platform has actually acquired them.
8. Natural, attach-after-launch, and debugger-launch observations are separate runs.
9. Timeout, transport loss, missing stdout, or instrument failure do not mean a business-negative result.
10. Harvest before rollback, shutdown, or destructive cleanup.
11. One mutable VM/debug session has one writer. Use a real atomic primitive, not a JSON owner field.
12. Repository-facing records must be desensitized. Runtime identifiers may exist transiently in local execution but must not be committed without sanitization.
13. Do not invent commands when an adapter already defines them. If local tool syntax differs by version, query local help first and record that divergence as an environment fact.

## Required final outcome

Every run ends in exactly one class:

- POSITIVE
- NEGATIVE
- INCONCLUSIVE
- INVALID_INSTRUMENT
- INFRA_FAILURE

Do not invent stronger conclusions than the runbook permits.
