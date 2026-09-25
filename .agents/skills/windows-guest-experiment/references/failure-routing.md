# Failure Routing

Use this after a failed canary or operation. Do not collapse distinct failures into timeout.

| Symptom | What it proves | What it does not prove | Next action |
|---|---|---|---|
| VM state is Running but Guest command fails | Hypervisor says VM is running | Guest OS/control path is ready | Re-run control canary; classify CONTROL_NOT_READY or TRANSPORT_FAILED |
| SSH port/banner responds but command cannot execute | Network/service answered | Authentication or command execution works | Test authentication and nonce execution separately |
| PowerShell Direct/PSSession works but mapped drive is absent | Current session is usable | Another logon/session shares mappings | Use UNC or recreate mapping in the exact session; rerun data canary |
| Path-not-found appears immediately | Referenced path is invalid in that context | File is merely slow to appear | Fix path/context; do not poll |
| Guest reports file size but Host has no file | Guest observed a file | Host acquired evidence | Copy to Host and verify size/hash |
| Control call returns but long task later vanishes | Foreground call completed | Runner is durable | Fail long-runner canary; use scheduled task/service/durable worker |
| Control disconnects after target launch | Transport was lost | Launch failed or target stopped | Reconcile OP as APPLIED/NOT_APPLIED/UNKNOWN before retry |
| stdout is empty | No stdout was captured | No behavior occurred | Check Guest spool, task state, raw log, artifacts |
| CDB command text contains expected marker | Marker text exists in log | Debugger emitted the event | Require a nonce/event format that cannot be satisfied by command echo |
| No breakpoint hit | Breakpoint did not produce a hit in this run | Target behavior is absent | Check coverage, symbols/address validity, mode, and observer validity |
| Natural run shows child/process activity but debugger run does not | Modes differ | Natural behavior disappeared globally | Keep separate RUN_IDs; treat debugger perturbation as possible |
| GUI target started from service/session 0 but no visible UI | Process may exist outside interactive desktop | User-desktop behavior was exercised | Use an interactive-session-capable runner if UI behavior matters |
| WMI/CIM polling changes timing or causes load | Observer is perturbing target | Target itself is unstable | Reduce polling; use lighter process/event APIs or offline artifacts |
| Same error repeats with unchanged inputs | No new information is being gained | More retries will help | Stop that path at retry budget and change adapter/hypothesis |
| Restore/start command disconnects mid-operation | Control path failed during side effect | Restore was or was not applied | Query hypervisor state and reconcile before issuing another restore |
| Instrument script/parser fails | Observer invalid | Business result is negative | INVALID_INSTRUMENT |
| Deadline reached with control/evidence gap | Observation window ended with uncertainty | Business result is negative | INCONCLUSIVE |

## Session and path rules

Windows path visibility depends on identity and session scope.

Never assume:

- a mapped drive exists in a fresh PSSession;
- a service account sees a user mapping;
- session 0 is equivalent to an interactive desktop;
- a path verified by one transport is valid in another.

For a new context, use a fresh nonce data canary.

## Retry routing

A retry is allowed only when at least one changed:

- environment state;
- credentials/context;
- path/channel;
- command/tool syntax;
- observation method;
- hypothesis;
- known failure condition.

Otherwise stop the route and preserve the error as evidence.

## Conclusion routing

Infrastructure and instrumentation failures override absence-based business conclusions.

Priority when the run ends:

1. if the observer itself is invalid -> INVALID_INSTRUMENT;
2. else if infrastructure prevented meaningful observation -> INFRA_FAILURE or INCONCLUSIVE depending on when evidence became insufficient;
3. else if acceptance is directly satisfied -> POSITIVE;
4. else NEGATIVE only when the full negative gate in the runbook is satisfied;
5. otherwise -> INCONCLUSIVE.
