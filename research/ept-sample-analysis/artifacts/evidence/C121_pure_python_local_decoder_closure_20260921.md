# C121: pure-Python local decoder closure (2026-09-21)

## Status

`PARTIAL / OFFLINE_REFERENCE_SYNTHETIC_RESPONSE / NOT_TARGET_COMPLETION` with remaining boundaries:
`INCOMPLETE / REAL_RESPONSE_PRODUCER_AND_POST_DECODE_BEHAVIOR_UNOBSERVED`.

## Delivered entry point

`<HOST_PATH>\EPT\method\harnesses\core_local_decoder_reference.py`

The entry point composes the already verified reference stages:

```text
268-byte input
  -> 0x14078ce60 transform
  -> 0x14078d900 state builder
  -> 284-byte RC00 request-shaped buffer
  -> 0x14078db80 response validator
  -> marker == g340
  -> 0x14078ce60 second transform
  -> 268-byte decoded output
```

The implementation is pure Python and does not require Windows `ctypes`. It has
no device, process, authorization, registry, network, or embedded-token
access. The source modules remain separately testable:

- `core_predevice_reference.py`: transform, 67-round hash, and state builder;
- `core_response_validator_reference.py`: RC03 validator and marker logic;
- `core_local_decoder_reference.py`: one command-line pipeline and output
  semantics.

## Regression results

Command:

```bash
PYTHONPATH=<HOST_PATH>/EPT/method/harnesses \
python <HOST_PATH>/EPT/method/harnesses/core_local_decoder_reference.py --self-test
```

Observed:

```json
{
  "status": "self_test_passed",
  "positive_branches": ["RC06 success", "RC06 success"],
  "negative_control_branch": "RC03 decode_failed",
  "marker_mismatch_control_branch": "RC04 session_mismatch"
}
```

C120 normalized fixture:

```bash
PYTHONPATH=<HOST_PATH>/EPT/method/harnesses \
python <HOST_PATH>/EPT/method/harnesses/core_local_decoder_reference.py \
  --input <HOST_PATH>/EPT/artifacts/captures/continuous_core_decode_20260921/normalized_input.bin \
  --out-dir <HOST_PATH>/EPT/artifacts/captures/local_decoder_reference_C121
```

Observed values:

| Field | Value |
|---|---|
| input bytes | 268 |
| input SHA-256 | `4836808424621ee58d80b558898d8ed2eb1227eb51e14c7f0036c072dad93bdd` |
| request/response bytes | 284 |
| request SHA-256 | `46e0aeb0b174a1f42bfde397e6ad4a9ffad4211823c7a83e46ebbc187dcf554a` |
| validator | `0x00000001` |
| marker | `0x13579bdf` |
| expected `g340` | `0x13579bdf` |
| branch | `RC06 success` |
| output SHA-256 | `4836808424621ee58d80b558898d8ed2eb1227eb51e14c7f0036c072dad93bdd` |
| output/input comparison | byte-identical; `cmp` exit `0` |

The C120 native trace independently observed the same logical chain in the
recovered machine code: `F060 -> transform -> state -> controlled target ->
RC03 continuation -> validator -> RC06 transform`. C121 therefore closes only the offline reference algorithm and synthetic fixture pipeline; C120 supplies mapped-code runner evidence for the same controlled seam. Neither is evidence of natural target execution, natural driver response, or post-decode behavior.

## Branch controls

- all-zero 284-byte response: `RC03 decode_failed`;
- accepted response with stale `g340`: `RC04 session_mismatch`;
- valid synthetic echo response: `RC06 success`, second transform recovers the
  input byte-for-byte.

## Boundary retained

The `--input` path creates a synthetic echo response. It does not prove that a
real device or driver produced that response, and it does not derive a valid
card key. Natural `-n/-m` dispatch, a real `DeviceIoControl` response, and the
unobserved driver/auxiliary component remain outside this closure.
