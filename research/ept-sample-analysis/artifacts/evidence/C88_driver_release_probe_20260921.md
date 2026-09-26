# C88 — bounded driver-release probe

## Scope and time contract

This was one direct-core probe from clean snapshot `qoder-clean-20260920`. The VM NIC was set to `null`; the outer `auto_decode.pyc` was not started and no TCP path was available. The guest ran:

```text
C:\ept_core\Hardware.exe -k CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA -n 2 -m 1
```

The observer started the process once, checked the target driver and the driver directory once per second for 20 ticks, then stopped `Hardware.exe` and restored the snapshot. This was a 20-second wall-clock experiment, not an open-ended wait.

## Observed phase log

```text
phase=launch sample=C:\ept_core\Hardware.exe nic=none
phase=created pid=4132
phase=tick tick=0..19 sample_exited=False hardware_pids=4132 new_sys=
phase=driver_absent_in_window
phase=stop
rc=0
```

The compact `tick=0..19` line represents twenty individual records; every tick reported the same sample PID, `sample_exited=False`, and an empty `new_sys` value. The target path `C:\Windows\System32\drivers\HP_WKS_SWTOOLS_DRIVER.sys` was absent on every check.

## Bounded conclusion

- **Observed:** the candidate core process stayed alive for the complete 20-second window with networking disabled; the target driver was not created at the expected path and no newly modified `.sys` appeared in the target driver directory.
- **Not proved:** that no driver is ever loaded. A driver could be mapped from an opaque runtime payload, created after this window, or use another path/mechanism.
- **Core consequence:** the current path gives no local driver bytes or user-mode return boundary to analyze after `0x141757acd`. The missing item is now a runtime mapping/opaque-payload observation, not a reason to rerun the same long startup wait.
- **Status:** `INCOMPLETE / NO_DRIVER_RELEASE_OBSERVED_IN_20S`.
