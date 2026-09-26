# Executable Runbook

Execute the gates in order. Do not skip a gate unless it explicitly says optional.

## Inputs

Resolve these from the task and environment when possible:

- OBJECTIVE
- ACCEPTANCE[]
- TARGET and TARGET_SHA256
- VM
- BASELINE snapshot/checkpoint
- HYPERVISOR or sandbox
- CONTROL_ADAPTER
- DATA_ADAPTER
- OBSERVATION_MODE = natural | attach-after-launch | debugger-launch
- EXPECTED_DURATION
- DEADLINE

If target identity, baseline, authorization/scope, or safe side-effect boundaries cannot be established, stop before launching the target.

---

## WGE-00 — Read-only preflight

Run scripts/preflight.ps1 on a Windows Host if possible.

The preflight must not start, stop, restore, attach, copy, or execute inside a Guest. It only discovers capabilities.

Required facts:

- Host PowerShell version and elevation state;
- Hyper-V cmdlet availability;
- PowerShell Direct parameter availability;
- VBoxManage availability and version;
- ssh/scp availability;
- CDB availability;
- candidate backend count and state summary.

Do not commit raw preflight output if it contains local identifiers.

Pass: at least one plausible control path can be named, or an existing sandbox/orchestrator is already authoritative.

Failure: no executable control path exists. End as INFRA_FAILURE unless provisioning a missing tool is explicitly in scope.

---

## WGE-01 — Choose backend and bind adapters

Prefer an existing sandbox or durable orchestrator if it already owns task state, VM lifecycle, result storage, and retries.

Otherwise select adapters using references/adapters.md.

The Agent must name:

- authoritative task/run state;
- writer-lock mechanism;
- control adapter;
- data adapter;
- completion source;
- artifact destination.

Do not silently switch adapters after a canary failure. Record why the current adapter failed, then test the next candidate with its own canary.

---

## WGE-02 — Freeze the run definition

Create a unique RUN_ID and record:

- objective;
- observable acceptance criteria;
- acceptance authority: current project contract path + revision/section, or an explicit current task directive;
- evidence scope class: TARGET_NATURAL | TARGET_CONTROLLED | TARGET_INJECTED | HARNESS | SYNTHETIC | OFFLINE_REFERENCE;
- optional project-specific scope detail when the generic class is not precise enough;
- target hash;
- VM and baseline;
- observation mode;
- expected duration and deadline.

Acceptance must describe the real final behavior or evidence.

These are never final acceptance by themselves:

- debugger attached;
- harness passed;
- breakpoint hit;
- static candidate found;
- communication restored;
- script executed.

Pass: another Agent could decide completion without chat history, and could tell whether the evidence came from the real target, a controlled/injected target run, a harness, or an offline/synthetic reference.

Authority rule: generated platform summaries, memories, handoffs, old status files, or prior assistant prose may help discovery but cannot redefine current acceptance. If they conflict with the bound authority, the bound authority wins until the user/project contract changes it.

Scope rule: HARNESS, SYNTHETIC, and OFFLINE_REFERENCE observations must not populate target-level result fields. TARGET_CONTROLLED and TARGET_INJECTED may describe real-target behavior only with the intervention/injection explicitly attached to the claim.

---

## WGE-03 — Acquire one writer

Acquire exclusive write control over the VM/debug session using, in preference order:

1. platform Lease/CAS;
2. database transaction/lock;
3. OS mutex/file lock;
4. an external scheduler that already guarantees serial execution.

Do not implement locking as read owner field then write my name.

If another live writer owns the resource, remain read-only.

---

## WGE-04 — Restore/start baseline

Before restore, harvest any unique evidence from the previous state if it still matters.

Restore the required baseline, then start or resume the VM.

A hypervisor state such as Running is only a hypervisor fact.

Pass: the VM is ready for Guest canaries.

Failure: INFRA_FAILURE if the VM cannot reach the canary stage.

---

## WGE-05 — Control canary

Use the selected control adapter to:

1. read Guest identity, OS, current user, privilege context, and working directory;
2. execute one short benign command;
3. return a fresh nonce marker;
4. verify the returned marker was produced by command execution, not command echo or stale output.

Do not substitute VM Running, an open port, an SSH banner, login UI, or Guest Additions presence for execution.

Pass: the expected nonce returns from the expected Guest context.

On failure, consult references/failure-routing.md. Do not launch the real target.

---

## WGE-06 — Data canary

1. Guest writes a small nonce file.
2. Guest computes size and hash.
3. Host retrieves the actual file through the intended data path.
4. Host independently computes size and hash.
5. Compare them.

Repeat for every new PSSession, SMB/UNC mapping, mapped drive, SCP path, shared folder, or identity context whose scope may differ.

Pass: Host acquired the file and the content/hash matches.

A path error is an immediate path error; do not convert it into a long polling timeout.

---

## WGE-07 — Long-runner canary

Required only for long tasks when the platform does not already provide a durable worker/job.

1. Start a benign detached test job.
2. Close the control session that launched it.
3. Open a fresh control session.
4. Prove the job survived or completed.
5. Harvest its result through the data path.

Pass: runner lifetime is independent from the foreground control session.

Failure: do not run the real long task. Switch to a scheduled task, service, independent worker/agent job, or another proven detach mechanism.

---

## WGE-08 — Instrumentation canary

Required only when instrumenting.

Using a benign target, prove:

- debugger/observer starts or attaches;
- command or script syntax is valid;
- marker output is distinguishable from command echo;
- raw log is harvestable;
- parser recognizes a real event rather than configuration text.

Pass: instrumentation and its output chain are independently proven.

Failure: INVALID_INSTRUMENT until fixed.

Natural runs do not inherit debugger-canary success.

---

## WGE-09 — Define side-effect verification

Before every non-idempotent or state-changing operation, define:

- OP_ID;
- operation;
- exact post-disconnect verification method.

Examples:

- launch target;
- modify system/target state;
- restore checkpoint;
- create/delete persistent resource;
- debugger mutation unsafe to repeat.

Verification must use a concrete fact such as platform task state, nonce-bound runner marker, run-specific PID/PPID lineage, or a durable result record.

Reads, health queries, and log reads do not need OP_ID.

Pass: the operation can later be classified APPLIED / NOT_APPLIED / UNKNOWN.

---

## WGE-10 — Launch once

1. Record OP_STARTED in platform history or fallback event log.
2. Dispatch exactly once.
3. Perform only a short confirmation.
4. Do not keep the full experiment coupled to that control call.
5. Enter observation.

If control is lost, go to WGE-11A. Do not dispatch again.

---

## WGE-11 — Observe

Each observation cycle asks only:

1. new business marker?
2. new infrastructure/instrument failure?
3. new artifact?
4. deadline reached?
5. acceptance closed?

Continue only while the target plausibly progresses and the observer remains valid.

Repeated identical errors without changed environment, parameter, channel, hypothesis, or observation method must stop at the retry budget.

Branches:

- acceptance closed -> WGE-12
- deadline reached -> WGE-12
- control/Guest loss -> WGE-11A
- observer failure -> WGE-12 then INVALID_INSTRUMENT

---

## WGE-11A — Reconcile after disconnect

Before retrying:

1. query hypervisor/platform task state;
2. query Guest spool/job history if available;
3. check the OP verification marker;
4. classify the operation.

APPLIED: do not rerun; resume observation or harvest.

NOT_APPLIED: a new OP_ID may be used only if the failure condition was fixed or the next attempt changes a meaningful variable.

UNKNOWN: do not issue another side effect. Recover observability first. If unresolved, the run cannot end NEGATIVE.

---

## WGE-12 — Harvest

Stop introducing new side effects.

Harvest in this order:

1. acceptance/terminal markers;
2. runner/task terminal status;
3. critical raw logs;
4. required PRE/POST state;
5. dump/PCAP/screenshot/dropped files or other critical artifacts;
6. Host-side control/instrument logs.

Evidence levels:

GUEST_OBSERVED -> HOST_ACQUIRED -> HOST_VERIFIED

A conclusion-critical artifact must be at least HOST_ACQUIRED. Use hash/size verification for irreplaceable or formal evidence.

Never report dump acquired merely because the Guest reported its size.

---

## WGE-13 — Outcome gate

Choose exactly one:

### POSITIVE

Acceptance-required behavior was validly observed and supported by Host/platform evidence.

### NEGATIVE

Use only if all are true:

- predefined observation window completed;
- control/data/completion remained adequate;
- instrumentation, if any, remained valid;
- observer coverage was sufficient;
- no evidence gap can explain the absence.

### INCONCLUSIVE

Use for timeout with unresolved result, control/data loss, missing critical artifacts, UNKNOWN operation state, or insufficient observer coverage.

### INVALID_INSTRUMENT

Debugger/script/filter/parser/observer failure invalidated the run.

### INFRA_FAILURE

VM/control/data infrastructure failed such that no business conclusion is valid.

Hard rules:

- WAIT_TIMEOUT is not NEGATIVE
- no breakpoint hit is not NEGATIVE
- no stdout is not NEGATIVE
- GuestControl/SSH/PSSession disconnect is not NEGATIVE
- VM Running is not POSITIVE
- harness success is not POSITIVE

---

## WGE-14 — Restore and release

Order:

1. stop new side effects;
2. confirm harvest is complete;
3. terminate/clean the run if required;
4. restore baseline, or preserve scene only when evidence preservation justifies it;
5. run the minimum control canary after restore;
6. resolve or freeze outstanding operations;
7. release writer lock.

Do not create a new snapshot for every run.

---

## WGE-15 — Agent handoff/recovery

Do not maintain a live handoff document by default.

A new Agent restores from:

1. platform/fallback current run state;
2. recent events;
3. conclusion-critical artifacts;
4. outstanding OP reconciliation;
5. writer lock acquisition.

Generate a handoff only as a derived view when these are insufficient.

---

## Human-stop gate

Do not ask the user merely because execution became inconvenient.

Stop for human input only when:

- credentials are required and unavailable;
- target/VM/baseline/scope is ambiguous;
- a destructive choice could erase unique evidence;
- a non-idempotent OP remains UNKNOWN after available reconciliation;
- equally valid next actions have materially different preservation consequences and no task preference resolves them.

Otherwise choose the next verified adapter or classify the failure.

---

## Fallback state

Use only when no platform-native durable state exists:

~~~text
runs/<RUN_ID>/
├── run.json
├── events.ndjson
└── artifacts/
~~~

Rules:

- run.json: current facts only; atomic replace.
- events.ndjson: append only; only information-gaining events.
- artifacts/: Host-acquired raw evidence.
- no live manifest + channel-state + lease.json + handoff + summary + artifact-index fan-out.
- use an OS/platform lock for the writer; do not put locking semantics in JSON.
