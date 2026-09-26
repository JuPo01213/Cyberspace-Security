# Executable Runbook

The normal path is short because mature backends should own execution state.

## WGE-00 — Bind the investigation intent

Before launching anything, resolve:

- `goal_ref`: current task/project contract that defines success;
- `subject`: the exact object/process/code being observed;
- `interventions`: only the changes that may affect behavior.

Do not copy the entire project goal into every run if a stable current contract already exists.

Generated summaries, memories, handoffs, old status files, and prior assistant prose are discovery aids only. They do not redefine the current goal.

---

## WGE-01 — Route to a backend

Choose the highest-level existing backend that can perform the required task.

### Managed runtime path

Use when a sandbox/orchestrator already owns:

- task identity and status;
- VM lifecycle;
- execution worker/Guest agent;
- retry/recovery;
- artifacts/results.

Examples include CAPE/Cuckoo-style sandbox execution or another durable task runtime.

**Delegate those responsibilities.** Do not mirror their state into a second custom workflow protocol.

The Agent should normally do only:

```text
submit/start
→ query status
→ retrieve artifacts/results
→ interpret against goal_ref
```

If the backend lacks one required capability, add only that capability through a thin adapter; do not reimplement the rest of the runtime.

### Direct-lab path

Use only when the task requires a capability the managed runtime cannot provide in the current environment, such as:

- precise debugger attach/breakpoint/memory interaction;
- project-specific transient patching/intervention;
- interactive Windows desktop/GUI control;
- an existing Hyper-V/VirtualBox lab that must be used directly.

Low-level transports are adapters, not runtimes.

---

## WGE-02 — Prove only required capabilities

Managed runtime: use its own documented readiness/task checks. Do not duplicate them unless project evidence shows a real gap.

Direct-lab: before the real target, prove only what this experiment requires.

### Command execution

Execute a benign fresh nonce in the intended Guest identity/context.

`VM Running`, port open, SSH banner, Guest Additions present, or login UI are not substitutes for command execution.

### Artifact round-trip

Have the Guest/runtime produce a small nonce artifact and verify the Host/runtime actually acquired it.

Immediate path/auth errors are immediate errors; do not turn them into polling timeouts.

### Long-job lifetime

Only when the experiment is long-running and there is no durable worker: prove the job survives closing the launch/control session.

### Instrumentation

Only when debugger/observer work is required: use a benign target to prove syntax, attach/start, a real emitted event, and harvestable raw output.

Configuration text or command echo does not count as an observed event.

### Interactive desktop

Only when GUI behavior matters: prove the target runs in the intended interactive session and the GUI observation/input path works. Session 0 process existence is not proof of user-desktop behavior.

Reuse a prior capability proof until a relevant condition changes, such as Guest image/baseline, identity/session, backend/transport, runner, debugger version/configuration, or GUI execution context.

---

## WGE-03 — Execute through the backend

Use the backend's native task/run identity when one exists.

If no native task identity exists, create one unique local RUN_ID.

Do not reuse a failed run as though it were the same causal experiment.

Before an intervention, record what is being changed. Examples:

```text
debugger attach
branch reversal
injected response
temporary memory patch
GUI input sequence
```

Execution platform/harness names are provenance, not evidence meaning.

For a state-changing action whose result could become ambiguous after disconnect, define a concrete way to determine whether it happened. Create special operation bookkeeping only when that ambiguity actually exists.

---

## WGE-04 — Observe facts, not plans

During execution distinguish:

```text
configured / armed / requested
from
hit / applied / observed
```

A breakpoint being set does not prove it fired.
A runner field describing an intended action does not prove the action occurred.
An API call site being observed does not prove downstream business success.

Do not combine observations from different runs into one causal chain.

---

## WGE-05 — Retrieve evidence

Prefer the backend's native result/artifact store.

For direct-lab fallback, retrieve conclusion-critical artifacts to the Host before destructive cleanup or rollback.

A useful evidence progression is:

```text
observed in execution
→ acquired by backend/Host
→ verified when necessary
```

Hash/size verification is needed for irreplaceable, corruption-prone, or formal evidence; it is not mandatory bookkeeping for every temporary file.

---

## WGE-06 — Interpret against the goal

Ask:

1. Did this run observe the required subject?
2. Which interventions could affect the result?
3. Was the required event actually observed, rather than merely configured?
4. Are all facts used in the causal claim from this same run?
5. Is missing evidence explained by infrastructure or instrumentation failure?

When a normalized outcome is useful:

- `POSITIVE`: required behavior was validly observed;
- `NEGATIVE`: the defined observation window completed with valid and sufficient coverage and the behavior was absent;
- `INCONCLUSIVE`: evidence is insufficient or ambiguous;
- `INVALID_INSTRUMENT`: the observer/debugger/parser invalidated the run;
- `INFRA_FAILURE`: execution infrastructure failed before a business conclusion was possible.

Timeout, no breakpoint hit, missing stdout, or transport disconnect do not by themselves mean NEGATIVE.

---

## WGE-07 — Cleanup and learning

Use the backend's native reset/cleanup lifecycle where available.

Direct-lab fallback:

```text
stop new side effects
→ harvest
→ cleanup/restore
→ release exclusive control
```

Do not turn every incident into a Skill edit.

Record the incident as project/run fact first. Promote a lesson only after it is shown to be reusable and evidence-backed, then compare against mature existing workflows before adding a new abstraction.

---

## Minimal fallback state

Use only when the selected backend has no durable task state.

```text
runs/<RUN_ID>/
├── run.json
└── artifacts/
```

Add an event log only when there is a real consumer for an event history (for example recovery after disconnect). Do not create one by default.

The fallback record stores investigation intent and final conclusion. Runtime details such as VM, adapter, PID, timestamps and tool versions should be generated automatically when tooling can provide them rather than hand-maintained by the Agent.
