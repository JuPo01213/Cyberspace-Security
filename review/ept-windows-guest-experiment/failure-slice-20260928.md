# Failure slice: mature workbench used without a closed mature run

Date: 2026-09-28 (Asia/Shanghai)

## Bottom line

`WindowsAnalysisWorkbench` was real and usable. The error was not choosing an immature custom launcher instead of the workbench. The error was allowing a partially specified CAPEsolo run and a stale debugger session to stand in for a closed experiment.

Run `EPT-STAGE2-INJECTEDIO-20260928-13` is **not a completed target run**. It should be treated as an execution/instrumentation failure or, at minimum, inconclusive—not as natural authorization, successful I/O injection, successful decode, or observed post-decode behavior.

## What was actually observed

1. The target was provisioned into `WindowsAnalysisWorkbench` and its SHA-256 matched the EPT authority record: `CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7`.
2. Official CAPEsolo MCP and interactive debug were used. The final job record shows `package=exe`, `options=bp0=ep,idbg=1`, and a job that was later cancelled after the debug session became stale.
3. The target process reached real code and spawned a child process. Host-side acquisition successfully verified the analysis log, process dumps, raw CAPE dump, and uploaded child artifact by hash.
4. The analysis log did not provide a confirmed sample request to the intended listener or a confirmed response injection. It also did not provide `target_native_return==0x1`, `target_caller_diff_bytes>0`, or an untruncated RC06-after behavior record.
5. After target termination, CAPE reported failures clearing debug registers and the debug interface continued to expose stale state. That is an observer-lifecycle failure, not evidence that the sample naturally completed or naturally failed its business path.

## Where my execution went wrong

### Incomplete use of the mature entry point

The mature analysis machine was used, but the official job submission did not carry the established local-input argument path. A package name alone is not equivalent to a complete invocation. Because the sample was not demonstrably started through the same argument-bearing entry path that had been established earlier, the absence of network-stage evidence could not distinguish “sample never reached the local flow” from “sample reached the flow but did not contact the listener.”

### Debugger lifecycle was not fail-closed

Several historical probe addresses were armed before the run had a confirmed dynamic route. The observer then followed parent/child transitions after the target had already terminated. Breakpoint cleanup was not completed while the target was alive, and the later clear-register errors were discovered only after termination. A valid run must capture the required seam, delete its breakpoints, verify the debugger is clean, detach/continue, and only then rely on post-release behavior.

### Evidence and run state were not reconciled promptly

The run record remained at an early `PRECHECK`/`UNKNOWN` state while the real job had already ended and raw artifacts had been acquired. That made the local record look more ready than the evidence was. The correct action was to classify the run immediately and preserve the raw artifacts, rather than let setup artifacts read like target progress.

### Communication overstated setup as progress

The existence of a workbench, a listener task, a CAPE job, or a process dump was reported as meaningful progress without first proving the acceptance fields for the same run. That increased confidence without increasing target-level knowledge.

## First-principles conclusion

A “mature analysis machine” is only one layer of the experiment. Target-level validity is the conjunction of:

`mature VM + correct package/arguments + real target identity + valid observer lifecycle + confirmed I/O boundary + same-run evidence closure`.

The run verified the VM, target identity, and part of the acquisition path. It did not verify the complete package/argument semantics, response injection, seam fields, or clean release. Therefore the right conclusion is not “the mature workflow failed”; it is “the mature workflow was only partially instantiated, and the missing gates allowed an invalid run to proceed too far.”

## Corrective method for the next run

- Reuse `WindowsAnalysisWorkbench`, official CAPEsolo, and the shipped adapters. Do not create a new launcher or scheduler.
- Use one new run ID and complete the ordinary preflight, baseline, control, data, long-runner, and instrumentation canaries.
- Submit the official `exe` package with the established argument-bearing entry path. Verify the persisted CAPE job options before trusting the run; redact the credential from repository-facing records.
- Confirm the listener receives a real sample request before treating any response as injected I/O.
- Use the minimum dynamic debugger points. Capture the required target fields, delete breakpoints immediately, verify no breakpoints remain, detach/continue, and then observe RC06-after behavior without ongoing debugger intervention.
- Harvest before rollback or shutdown. Classify the run from evidence, and keep `target_native_return` and `target_caller_diff_bytes` as `NOT_OBSERVED` until the real target process proves them.

## Security and provenance boundary

This slice deliberately excludes the user-provided key, CAPE tokens, sample binaries, raw memory dumps, live hostnames, and Guest credentials. The public review packet contains only workflow facts, run identifiers, hashes, and a method-level conclusion.
