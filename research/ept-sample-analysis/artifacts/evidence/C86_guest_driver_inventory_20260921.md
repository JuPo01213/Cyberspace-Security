# C86 — clean guest driver inventory

## Scope

This is a read-only inventory of the clean guest before launching the sample. It does not execute `Hardware.exe`, contact the network, load a driver, or alter guest files. The query was issued through VirtualBox Guest Additions after resuming snapshot `qoder-clean-20260920`; the host-side VM state before the query was `running`, `nic1=nat`.

The purpose is narrow: determine whether the driver named by the recovered strings is already available as a static guest file or registered service, so the boundary after `0x141757acd` is not silently described as a missing-analysis failure.

## Direct file results

| Path | Result | Size | SHA-256 |
|---|---|---:|---|
| `C:\ept_core\Hardware.exe` | present | 32,671,232 | `CFA6998ECC2FBA92B027985C5283B09CD9C04C636158FD6961A10560AFB28BD7` |
| `C:\Windows\System32\Hardware.exe` | present; different older copy | 32,198,144 | `0DDC82FC1EBE9C3D64C2D2B22424FC063080107C4AE10670F4449E227A4335C8` |
| `C:\Windows\System32\drivers\HP_WKS_SWTOOLS_DRIVER.sys` | absent | — | — |

The `C:\ept_core\Hardware.exe` hash matches the host candidate `<HOST_PATH>\vmctl\out\Hardware.genB.exe`. The absence result is therefore not caused by querying the wrong sample path.

## Targeted directory/service inventory

The targeted driver-directory listing found `HpSAMD.sys` (64,312 bytes), `bthport.sys`, `rhproxy.sys`, and other system files, but no `HP_WKS_SWTOOLS_DRIVER.sys`, `SWTOOLS`, or sample-named `.sys` file.

The matching service-registry query returned `HpSAMD`, `BTHPORT`, `rhproxy`, `RpcEptMapper`, `perceptionsimulation`, and `shpamsvc`; it returned no `SWTOOLS`, `HP_WKS`, `EPT`, or `Hardware` driver service. `HpSAMD.sys` is recorded only as an unrelated system driver candidate and is not substituted for the named sample driver.

## Bounded conclusion

- **Confirmed for this baseline:** the named driver bytes and service registration are absent before sample execution; only the candidate sample executable is present.
- **Not proved:** that the driver can never be created or loaded. It may be dropped, mapped, or supplied through a protected/runtime path during a genuine sample run.
- **Core-analysis consequence:** the call target after `0x141757acd` cannot currently be classified as purely user-mode, driver-backed, or network-backed from the clean guest. Its boundary remains a real missing-byte/runtime-state item, not evidence that the local `0x14078ce60` transform is the final decoder.
- **Status:** `INCOMPLETE / DRIVER_BYTES_UNAVAILABLE_IN_CLEAN_BASE`.

## Reproduction boundary

The query was limited to `Get-Item`/`Get-FileHash` for the three paths, a targeted listing of `C:\Windows\System32\drivers`, and a registry listing under `HKLM:\SYSTEM\CurrentControlSet\Services`. No recursive whole-disk search and no sample launch were used.
