# C87 — packed sample embedded-driver scan

## Scope

This is a host-side, read-only byte scan of the packed candidate. It does not execute the sample, inspect the VM, decode the standing authorization token, or contact the network.

Input: `<HOST_PATH>\vmctl\out\Hardware.genB.exe`, 32,671,232 bytes, SHA-256 `cfa6998ecc2fba92b027985c5283b09cd9c04c636158fd6961a10560afb28bd7`.

## Results

- Literal `MZ` occurrences: 441. They are not sufficient to identify embedded PE files because they are scattered decoy/data bytes.
- Literal `PE\0\0` occurrences: 2, at file offsets `0x80` and `0x19f0a12`.
- Valid `MZ` headers whose `e_lfanew` points to a local `PE\0\0`: 1, the outer image at offset `0x0` with signature at `0x80`.
- Literal `HP_WKS_SWTOOLS_DRIVER`, `SWTOOLS`, and `\\.\\` occurrences in the packed file: 0.

The second raw `PE\0\0` occurrence at `0x19f0a12` is not pointed to by a valid local `MZ` header and is not an independently extractable PE image under this scan.

## Bounded conclusion

The packed file does not contain a directly extractable plaintext PE driver or the recovered driver-name strings. Together with C86 (the clean guest has no target `.sys` file or matching service), this makes “the driver was simply overlooked as a static companion file” unlikely.

This does **not** prove that no compressed/encrypted driver payload exists, nor that runtime code cannot generate or map one. The evidence only narrows the missing component to a runtime/opaque-payload boundary.

Status: `INCOMPLETE / NO_PLAINTEXT_EMBEDDED_DRIVER_FOUND`.
