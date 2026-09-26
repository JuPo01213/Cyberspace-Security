# C122: PYZ/main.pyc UI card-format boundary (2026-09-21)

## Scope

This is a read-only static report. It does not execute the sample, modify
`ept_clean.exe`, alter bytecode, generate keys, or inspect the external
authorization result.

## PE, CArchive, and PYZ provenance

### Reconstructed `ept_clean.exe`

- Path: `<HOST_PATH>\EPT\unpack\ept_clean.exe`
- Size: `377,344` bytes
- SHA-256: `5d3e30e28162276a99af87f9b625e2763354c2598bbb97ebf94f2ba980d77cb3`
- Rebuilt by `unpack/build_clean_pe.py` from the unpacked memory image.
- One `.text` section, entry RVA `0x4c30`, `SizeOfImage=0x5d000`.
- It contains PyInstaller bootloader strings such as `_MEIPASS` and
  `base_library.zip`, but it does not contain the original sample's intact
  CArchive cookie or the full `PYZ.pyz` payload. Therefore `ept_clean.exe`
  alone is not a complete archive extraction source.

### Original sample CArchive used for byte provenance

The original sample is the source corresponding to the reconstructed PE:

- CArchive start: file offset `0x24000` (`147,456`)
- Cookie: file offset `0x33dcf5b` (`54,382,427`)
- Cookie magic: `MEI 0c 0b 0a 0b 0e`
- Archive length: `54,235,059` bytes
- TOC absolute offset: `54,310,491`
- TOC length: `71,936` bytes
- Python version field: `313`
- Python DLL: `python313.dll`
- TOC entries: `1,268`

The `PYZ.pyz` TOC entry is:

| Field | Value |
|---|---:|
| relative archive offset | `47,525,257` (`0x2d74809`) |
| absolute file offset | `47,672,713` (`0x2d76d89`) |
| compressed length | `6,637,778` |
| uncompressed length | `6,637,778` |
| compression flag | `0` |
| type code | `z` |
| SHA-256 | `14875591998f8c07b82f24c5c76f6eda8be40df720f925e88592fad0ab9dd89f` |

The extracted `PYZ.pyz` has the same size and SHA-256 as the CArchive slice.
The existing extracted `main.pyc` is `212,654` bytes with SHA-256
`de746c511178b8748a265a9c56e4c7a21e9703c1ce89dea2609b1ba6be33e274`.

## `SplashScreen._on_confirm` code object

Loaded with CPython `3.13.15` using `marshal.loads(pyc[16:])` and recursively
walked without executing any code.

| Field | Value |
|---|---|
| qualified name | `<module>.SplashScreen._on_confirm` |
| filename | `main.py` |
| first source line | `2961` |
| positional arguments | `1` (`cls`) |
| local variables | `cls`, `card_key`, `re` |
| bytecode length | `1,154` bytes |
| relevant names | `re`, `len`, `match`, `_GLOBAL_CARD_KEY`, `_confirm_callback` |

Relevant constants:

```text
const[8]  = 0
const[9]  = 31
const[10] = 36
const[11] = '^[a-zA-Z0-9]{31,36}$'
const[13] = '^(C|E(?!PT))'
```

UI error constants are:

```text
'⚠ 请输入卡密！'
'⚠ 卡密错误，验证失败！'
'⚠ 卡密输入有误！'
```

## Branch map

```text
0x00..       confirm button disabled check
0x00da       card_key truthiness check
0x01ae       len(card_key) < 31
0x01dc       len(card_key) > 36
0x0206       re.match('^[a-zA-Z0-9]{31,36}$', card_key)
0x021a       invalid length/charset branch
0x02fa       re.match('^(C|E(?!PT))', card_key)
0x030e       invalid prefix branch
0x03d6       STORE_GLOBAL _GLOBAL_CARD_KEY
0x03fc       LOAD_ATTR _confirm_callback (callback setup)
0x0414       CALL 1 with card_key
```

Exact bytecode observations from CPython 3.13 disassembly:

```text
0x01c6  LOAD_CONST 31
0x01e6  LOAD_CONST 36
0x0206  LOAD_CONST '^[a-zA-Z0-9]{31,36}$'
0x021a  POP_JUMP_IF_TRUE 0x02ea
0x02fa  LOAD_CONST '^(C|E(?!PT))'
0x030e  POP_JUMP_IF_TRUE 0x03d6
0x03d6  LOAD_FAST card_key
0x03d8  STORE_GLOBAL _GLOBAL_CARD_KEY
0x03f8  POP_JUMP_IF_FALSE 0x0420
0x03fc  LOAD_FAST cls
0x03fe  LOAD_ATTR _confirm_callback
0x0412  LOAD_FAST card_key
0x0414  CALL 1
0x041c  POP_TOP
0x041e  RETURN_CONST None
```

The first prefix branch is at bytecode offset `0x030e` (`782` decimal), and
the success path begins at `0x03d6` (`982` decimal). These are code-object
offsets inside `main.pyc`, not offsets in `ept_clean.exe`.

## UI-only accepted input constraints

After `.strip()`, a non-empty `card_key` passes this UI method only when all
conditions hold:

1. Length is between `31` and `36` characters inclusive.
2. Every character is ASCII alphanumeric: `[A-Za-z0-9]`.
3. The string begins with `C`, or begins with `E` followed by a character
   sequence that is not `PT` at positions 2-3. In practical terms, an `E`
   prefix is accepted except `EPT...`.
4. On success the exact stripped string is assigned to `_GLOBAL_CARD_KEY` and
   passed to `_confirm_callback`.

Examples for format testing only:

```text
Accepted shape: `C` + 30 to 35 alphanumeric characters
Accepted shape: `E` + 30 to 35 alphanumeric characters, unless positions 2-3 are `PT`
Rejected: 30 characters
Rejected: 37 characters
Rejected: punctuation or whitespace inside the value
Rejected: `EPT` followed by otherwise valid characters
```

These are format examples, not valid authorization keys.

## One-command verification

Run with the bundled CPython 3.13 interpreter:

```bash
/home/ept/.local/share/uv/python/cpython-3.13.15-linux-x86_64-gnu/bin/python3.13 \
  <HOST_PATH>
```

Expected output starts with:

```text
C122 read-only verification: PASS
ept_clean_sha256=5d3e30e28162276a99af87f9b625e2763354c2598bbb97ebf94f2ba980d77cb3
pyz_offset=0x2d76d89 pyz_length=6637778 pyz_sha256=14875591998f8c07b82f24c5c76f6eda8be40df720f925e88592fad0ab9dd89f
main_code=<module>.SplashScreen._on_confirm firstlineno=2961 code_len=1154
ui_format=31..36 ASCII alphanumeric; prefix=C or E except EPT
external_authorization=not tested
```


The `_on_confirm` constant/name table contains no `Hardware.exe`, `-k`, `-n`,
or `-m` marker. Its external-facing operation is only the callback call.
In the same `main.pyc`, `PyWebViewAPI.run_decode` is a separate code object
(first source line `2500`, bytecode length `482`) that calls
`self._get_decode_engine().run_decode(params)`, while the separate
`PyWebViewAPI.manual_swap_code` object (first source line `2456`) contains the
literal `Hardware.exe`. The extracted `auto_decode.pyc` contains the later
engine implementation. This is static evidence of separate code paths; it is
not a claim that the callback cannot eventually dispatch to the engine.


```text
UI format gate
  -> _GLOBAL_CARD_KEY
  -> _confirm_callback
  -> external DecodeEngine/core invocation
  -> Hardware.exe authorization and response path
```

Passing the UI format gate is not evidence of authorization success.
