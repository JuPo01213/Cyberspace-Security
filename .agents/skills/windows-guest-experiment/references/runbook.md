# Executable Runbook

This file is procedural. Execute the steps in order. Do not skip a gate unless the step explicitly says it is optional.

## Inputs

Resolve these from the task/environment when possible:

- OBJECTIVE
- ACCEPTANCE[]
- TARGET and TARGET_SHA256
- VM
- BASELINE snapshot/checkpoint
- HYPERVISOR / sandbox
- CONTROL_ADAPTER
- DATA_ADAPTER
- OBSERVATION_MODE = natural | attach-after-launch | debugger-launch
- EXPECTED_DURATION
- DEADLINE

If target identity, baseline, or safe side-effect boundaries cannot be established, stop before launching the target.

---

## WGE-00 — Choose the execution backend

**Action**

Check whether the environment already provides task state/history, VM lifecycle, artifact/result storage, retry semantics, or Lease/CAS.

Examples: CAPE/Cuckoo or an existing durable job/workflow system.

**Pass**

The Agent can name the authoritative task state, artifact store, and writer-lock mechanism.

**Branch**

- Platform provides them → use them; do **not** create fallback state.
- Direct Host→Guest experiment → continue with this runbook and use fallback only if required.

---

## WGE-01 — Freeze the run definition

Create a new unique RUN_ID and record:

- objective;
- acceptance criteria as observable facts;
- target hash;
- VM + baseline;
- observation mode;
- deadline.

Acceptance must describe the real final behavior/evidence.

The following are never final acceptance by themselves:

- debugger attached;
- harness passed;
- breakpoint hit;
- static candidate found;
- communication restored;
- script executed.

**Pass**

A different Agent could decide completion without reading chat history.

---

## WGE-02 — Acquire one writer

Acquire exclusive write control over the VM/debug session using, in order of preference:

1. platform Lease/CAS;
2. database transaction/lock;
3. OS mutex/file lock;
4. an external scheduler that already guarantees serial execution.

Do not implement locking as “read owner field, then write my name”.

**Failure**

If another live writer owns the resource, remain read-only and do not execute side effects.

---

## WGE-03 — Restore/start the baseline

Before restore, harvest any unique evidence from the previous state if it still matters.

Restore the required baseline, then start/resume the VM.

A hypervisor state such as `Running` is only a hypervisor fact.

**Pass**

The VM is ready for Guest canaries.

**Failure outcome**

`INFRA_FAILURE` if the VM cannot reach the canary stage.

---

## WGE-04 — Control canary

Use the selected control adapter to:

1. read Guest identity/OS/current user;
2. execute one short benign command;
3. return an unambiguous random marker;
4. confirm expected privilege and working directory.

Do **not** substitute VM Running, open port, SSH banner, login UI, or Guest Additions state for this test.

**Pass**

The command actually executed and returned the expected marker.

**Failure classes**

- CONTROL_NOT_READY
- AUTH_FAILED
- TRANSPORT_FAILED
- COMMAND_NOT_EXECUTED
- CONTEXT_UNEXPECTED

Do not run the real target until fixed.

---

## WGE-05 — Data canary

1. Guest writes a small file containing a random nonce.
2. Guest calculates size/hash.
3. Host retrieves the actual file through the intended data path.
4. Host independently calculates size/hash.
5. Compare them.

Repeat this canary for every new PSSession, SMB/UNC mapping, mapped drive, SCP path, shared folder, or identity context whose scope may differ.

**Pass**

Host acquired the file and content/hash matches.

**Failure classes**

- PATH_INVALID
- PATH_SCOPE_MISMATCH
- AUTH_FAILED
- FILE_NOT_READY
- TRANSFER_FAILED
- HOST_NOT_ACQUIRED

A path error is an immediate path error; do not convert it into a long polling timeout.

---

## WGE-06 — Long-runner canary (only for long tasks)

Skip if the platform already supplies a durable worker/job.

1. Start a benign detached test job.
2. Close the control session that launched it.
3. Open a fresh control session.
4. Prove the job survived or completed.
5. Harvest its result through the data path.

**Pass**

Runner lifetime is independent from the foreground control session.

**Failure**

Do not run the real long task. Switch to a scheduled task, service, independent worker/agent job, or a proven detach mechanism.

---

## WGE-07 — Instrumentation canary (only when instrumenting)

Skip for a natural run with no debugger/instrumentation.

Using a benign target, prove:

- debugger/observer starts or attaches;
- command/script syntax is valid;
- expected marker is distinguishable from command echo;
- stdout/stderr/raw log are harvestable;
- parser recognizes a real event, not configuration text.

**Pass**

Instrumentation and its output chain are independently proven.

**Failure outcome**

`INVALID_INSTRUMENT`. Fix the observer before the real target.

---

## WGE-08 — Define side-effect verification

Before every non-idempotent/state-changing operation, define:

- OP_ID;
- operation;
- exact verification method after a disconnect.

Typical operations:

- launch target;
- modify target/system state;
- restore checkpoint;
- create/delete persistent resource;
- debugger mutation that is unsafe to repeat.

Verification must use a concrete fact such as platform task state, a nonce-bound runner marker, or run-specific PID/PPID lineage.

Reads, health queries, and log reads do not need OP_ID.

**Pass**

The Agent knows how to classify the operation later as APPLIED / NOT_APPLIED / UNKNOWN.

---

## WGE-09 — Launch once

1. Record/submit OP_STARTED using the platform history or fallback event log.
2. Dispatch the operation exactly once.
3. Perform only a short confirmation.
4. Do not keep the whole run attached to the control call.
5. Enter observation.

If control is lost, go to WGE-10A. **Do not dispatch again.**

---

## WGE-10 — Observe for new information

On each observation cycle ask only:

1. New business marker?
2. New infrastructure/instrument failure?
3. New artifact?
4. Deadline reached?
5. Acceptance closed?

Continue waiting only when the target is plausibly still progressing and the observer remains valid.

Repeated identical errors with no changed environment, parameter, channel, hypothesis, or observation method must stop at the retry budget.

Branch:
- acceptance closed → WGE-11;
- deadline reached → WGE-11;
- control/Guest loss → WGE-10A;
- observer failed → WGE-11 and classify INVALID_INSTRUMENT.

---

## WGE-10A — Reconcile after disconnect

Before any retry:

1. query hypervisor/platform task state;
2. query Guest spool/job history if available;
3. check the OP verification marker;
4. classify the operation.

### APPLIED

Do not rerun it. Resume observation/harvest.

### NOT_APPLIED

A new OP_ID may be used for a retry only if the failure condition was fixed or the next attempt changes a meaningful variable.

### UNKNOWN

Do not issue another side effect. Recover observability first. If it cannot be resolved, the run cannot end as a business-negative result.

---

## WGE-11 — Harvest

Stop introducing new side effects.

Harvest, in priority order:

1. acceptance/terminal markers;
2. runner/task terminal status;
3. critical raw logs;
4. required PRE/POST state;
5. dump/PCAP/screenshot/dropped files or other critical artifacts;
6. Host-side control/instrument logs.

Evidence level:

`GUEST_OBSERVED → HOST_ACQUIRED → HOST_VERIFIED`

A conclusion-critical artifact must be at least HOST_ACQUIRED. Use hash/size verification for irreplaceable or formal evidence.

Never report “dump acquired” merely because the Guest reported its size.

---

## WGE-12 — Outcome gate

Choose exactly one:

### POSITIVE
Acceptance-required behavior was validly observed and is supported by Host/platform evidence.

### NEGATIVE
Use only if all are true:
- predefined observation window completed;
- control/data/completion remained adequate;
- instrumentation (if any) remained valid;
- observer coverage was sufficient;
- no evidence gap can explain the absence.

### INCONCLUSIVE
Use for timeout with unresolved result, control/data loss, missing critical artifacts, UNKNOWN operation state, or insufficient observer coverage.

### INVALID_INSTRUMENT
Debugger/script/filter/parser/observer failure invalidated the run.

### INFRA_FAILURE
VM/control/data infrastructure failed before or during the run such that no business conclusion is valid.

Hard rules:

- WAIT_TIMEOUT ≠ NEGATIVE
- no breakpoint hit ≠ NEGATIVE
- no stdout ≠ NEGATIVE
- GuestControl/SSH disconnect ≠ NEGATIVE
- VM Running ≠ POSITIVE
- harness success ≠ POSITIVE

---

## WGE-13 — Restore and release

Order:

1. stop new side effects;
2. confirm harvest is complete;
3. terminate/clean the run if required;
4. restore baseline or preserve scene only when explicitly justified;
5. run the minimum control canary after restore;
6. resolve/freeze outstanding operations;
7. release writer lock.

Do not create a new snapshot for every run. Keep an extra snapshot only for a unique failure/postmortem or explicit request.

---

## WGE-14 — Agent handoff/recovery

Do not maintain a live handoff document by default.

A new Agent restores from:

1. platform/fallback current run state;
2. recent run history/events;
3. conclusion-critical artifacts;
4. outstanding OP reconciliation;
5. writer lock acquisition.

If those are insufficient, generate a handoff as a derived view; do not make it a second runtime authority.

---

## Fallback state (only when no platform state exists)

Use:

```text
runs/<RUN_ID>/
├── run.json
├── events.ndjson
└── artifacts/
```

Rules:

- `run.json`: current facts only; atomic replace.
- `events.ndjson`: append only; only information-gaining events.
- `artifacts/`: Host-acquired raw evidence.
- No live manifest + channel-state + lease.json + handoff + summary + artifact-index fan-out.
- Use an OS/platform lock for the writer; do not put locking semantics in JSON.
