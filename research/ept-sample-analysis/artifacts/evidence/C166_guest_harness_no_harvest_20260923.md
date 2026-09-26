# C166: Guest harness result not harvested (2026-09-23)

## Classification

INSTRUMENT_FAILURE / CONTROL_NOT_READY. C166 has no usable Guest business result. This is a retrospective reconciliation from the existing handoff; the original Guest runner output was not recovered, so this note does not reconstruct missing runtime fields.

## Recorded execution

- method/HANDOFF.md records that C166 staged the C152 H17 caller/injection harness and seven input hashes matched the C152 record.
- The initial runner hash gate failed because PowerShell resolved H as the Get-History alias. After renaming the variable, the recorded Guest process PID 4152 started.
- The GuestControl wait then timed out after two minutes and entered current status is: starting. No native_probe.log, caller output, or result fields were harvested.
- A repository search found no dedicated C166 raw evidence file. The handoff is the source for the execution summary above; the absent raw Guest output limits independent verification.

## Objective fields

| Field | C166 status |
|---|---|
| native_return | Not collected; unknown, not zero |
| changed_bytes | Not collected; unknown, not zero |
| caller +0x80 before/after | Not collected |
| target code page before/after | Not collected |
| Guest target/sample lineage | Not closed by this harness run |

C152 H17 out16 is a separate host-harness result (native_return=0x1, c_struct_changed_bytes=34, changed_bytes=0). It is not C166 evidence and cannot be combined with C166 to satisfy the Guest target criterion.

## Conclusion

C166 is an unharvested harness attempt, not a success and not a negative business result. It does not satisfy native_return == 0x1 plus changed_bytes > 0 in one real Guest target run.
