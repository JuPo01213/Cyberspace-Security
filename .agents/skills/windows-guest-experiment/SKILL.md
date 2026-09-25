---
name: windows-guest-experiment
description: Execute, recover, or hand off experiments where a stable Host controls an unstable Windows Guest/VM. Use for VM snapshot/checkpoint runs, long-running Guest jobs, debugger/instrumentation runs, artifact harvesting, transport failures, safe retry after disconnects, or multi-agent control of the same VM. Do not use for ordinary static-only analysis that does not execute a Guest.
---

# Windows Guest Experiment

Use this skill as the **canonical execution procedure** for Host→Windows Guest experiments.

## Mandatory loading rule

Before any state-changing Guest/VM action, read `references/runbook.md` completely.

Read `references/patterns.md` only when:
- changing this skill;
- choosing between platform-native orchestration and the fallback;
- explaining why a rule exists.

Use `assets/run-record.example.json` only when the current platform has **no native durable task/run state**.

Run `scripts/validate-run-record.py` when using the fallback record.

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
11. One mutable VM/debug session has one writer. Use a real atomic primitive (platform Lease/CAS, DB transaction, OS mutex/file lock), not a JSON owner field.
12. Repository-facing records must be desensitized: no personal emails, user-profile paths, machine-specific private paths, credentials, tokens, or private addresses.

## Required final outcome

Every run ends in exactly one class:

- `POSITIVE`
- `NEGATIVE`
- `INCONCLUSIVE`
- `INVALID_INSTRUMENT`
- `INFRA_FAILURE`

Do not invent stronger conclusions than the runbook permits.
