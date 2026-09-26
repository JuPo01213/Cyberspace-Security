# C89 — native startup local-helper boundary

## Scope and time contract

This was one new dynamic discriminator, not a repeat of the earlier main/RC00 wait. The guest NIC was `null`; `auto_decode.pyc`, TCP, and the outer GUI were not used. From clean snapshot `qoder-clean-20260920`, the guest ran the updated `<HOST_PATH>\vmctl\debug_core_call.ps1` in `-NativeStartup` mode with a `10000 ms` wall-clock limit.

At the first loader breakpoint the observer successfully restored the captured `.text`, patched only the authorization prerequisite, and armed four observations: `main=0x1407a4b90`, the RC00 callsite `0x14078ee73`, local transform `0x14078ce60`, and local state builder `0x14078d900`. The two local observations recorded the entry `RCX` and, when entered, would capture the `0x10c`/16-byte in-place output.

## Observed phase log

The copied log is `artifacts/captures/core_native_local_helpers_20260921A/debug_core_call.log` (1706 bytes, SHA-256 `c749561d9bfcf94ea20ade15bdf1da4cdc7cf7d9ab256de0eb58bb10f343ca09`). The current run contains:

```text
phase=restore_plaintext bytes=8257536 sha256=5ae354e2983a5bf407601b3629d114b8faa1ddd731d074e8d2092c338abdf757 written=8257536 ok=True
phase=bypass_auth_gate address=0x1407a3080 ok=True written=6
phase=arm_main_entry address=0x1407a4b90 ok=True original=48 error=0
phase=arm_callsite address=0x14078ee73 ok=True original=e8 error=0
phase=arm_local_transform address=0x14078ce60 ok=True original=48 error=0
phase=arm_local_state_builder address=0x14078d900 ok=True original=48 error=0
phase=native_progress_probe rip=0x143a49c3d rsp=0x14f3a0 rax=0x36 rcx=0x658
phase=native_progress_handle value=0x658 duplicate_ok=false error=6
phase=timeout no_native_main_entry
phase=timeout no_local_transform_entry
phase=timeout no_local_state_builder_entry
phase=timeout no_rc00_callsite_hit
```

The progress stack was also copied (`native_progress_stack.bin`, 512 bytes, SHA-256 `5b37968934f68386f4e2fee411529240dc0c0a9578852aec41847a6c1ec83468`). No local-helper input/output files were produced because neither helper entry was reached.

## Bounded conclusion

- **Observed:** all four new breakpoint writes succeeded after the `.text` restore and authorization-prerequisite patch; the 10-second native-startup window reached an unstable progress site outside the image, but not `main`, RC00, `0x14078ce60`, or `0x14078d900`.
- **Not proved:** that the local transform or state builder is dead, irrelevant, or a negative decoder path. This run stopped before their call boundary.
- **Decision:** the ordinary native-startup route is still blocked before the local helpers. Repeating that route or extending its wait has low information value.
- **Status:** `INCOMPLETE / STARTUP_BOUNDARY_STILL_BEFORE_LOCAL_HELPERS`.

The next dynamic seam must invoke the already identified local caller with a valid caller context, or obtain an earlier runtime/module state. It must not be another unbounded startup wait.

The VM was powered off, restored to `qoder-clean-20260920`, and the host NIC setting was restored to `nat` after collection.
