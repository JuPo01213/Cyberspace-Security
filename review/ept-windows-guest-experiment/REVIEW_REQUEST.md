# External review request: EPT Windows Guest experiment

This packet asks an independent reviewer to audit one failed/inconclusive EPT dynamic-analysis run and the reusable `windows-guest-experiment` skill that was supposed to govern it.

The central question is not whether a mature analysis VM existed. It did. The question is whether the complete mature workflow was used with the correct sample-entry semantics, observation lifecycle, and evidence gates.

## Review scope

- Project: EPT isolated Windows sample analysis.
- Run under review: `EPT-STAGE2-INJECTEDIO-20260928-13`.
- VM: `WindowsAnalysisWorkbench`.
- Intended evidence scope: `real_sample_guest_run_injected_io`.
- Required target fields: `target_native_return==0x1`, `target_caller_diff_bytes>0`, and untruncated RC06-after behavior in the same run.
- Credential material, sample binaries, raw dumps, tokens, and runtime secrets are intentionally excluded.

## Provisional finding

The run must not be treated as a completed analysis or as natural authorization. The evidence supports that the mature workbench and official CAPEsolo path were available and that the real target and a child process executed. It does not support confirmed request/response injection, the target seam fields, or post-release behavior.

The most important failure was integration-level: the run used the mature machine, but the submitted CAPE job carried `package=exe` with only `bp0=ep,idbg=1`; the established local-input argument path was not present in the submitted options. The platform was mature, but the sample was not launched with the complete intended entry semantics.

## Questions for the independent reviewer

1. Does the skill make the distinction between “mature infrastructure exists” and “the selected launcher/package received the complete intended arguments” explicit enough?
2. Is the official CAPEsolo `exe` package argument encoding and verification step specified strongly enough to prevent a no-argument run from being mistaken for a meaningful local-authentication run?
3. Should the debugger gate require breakpoint deletion and an observed clean debugger state before allowing the sample to continue into child creation or termination handling?
4. Is `INVALID_INSTRUMENT` the correct execution classification when the target ran and artifacts were harvested, but the observer became stale and the required target fields were never observed?
5. Are the evidence fields and reviewer questions sufficient to prevent a future report from turning a real process/dump artifact into a claim of successful authorization, response injection, or post-decode behavior?

Please review the attached failure slice, the evidence manifest, and the skill snapshot as separate objects. Do not infer missing runtime facts from labels, job completion, process survival, or dump existence.
