#!/usr/bin/env python3
"""PARTIAL transcription of the EPT target's card-key -> session-key deriver.

Source: runtime code at 0x14078ac40, dumped from a live process image
(SHA-256 cfa6998e...), disassembled with capstone.  Static alphabet tables:

    0x140f8cdc0 (52 B) = b"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    0x140f8ce50 (62 B) = b"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

STATUS -- READ THIS BEFORE USING THE OUTPUT
-------------------------------------------
VERIFIED here (direct instruction-by-instruction correspondence, no assumptions):
  * input preconditions enforced by the caller 0x14078e640..0x14078e6a7
      - 10 <= len(key) <= 29
      - every character in [0-9A-Fa-f]
  * the two rolling hashes (seeds 0x7da49f05 / 0xd3050ee9, multiplier 0x01000193,
    post-step ``x ^= x >> 13``), finalised as ``mix_full((len*0x9e3779b9) ^ hash)``
    -> the pair referred to below as ``bp`` and ``bx``
  * the 28-byte token derivation written to 0x14115c3f0
  * g344 (0x14115c344), g358, g35c, g360, g364, g368, g36c

NOT YET TRANSCRIBED (raises ``UnfinishedTranscription`` if requested):
  * g348 (0x14115c348), g34c (0x14115c34c), g350 (0x14115c350), g354 (0x14115c354)
    -- the instructions live at 0x14078b035..0x14078b0f6 and interleave the
       ``edx``/``r8d``/``r10d`` chains in a way that needs bit-exact register
       lifetime tracking before it may be called a keygen.  Shipping a
       plausible-looking version of these four words would be worse than
       shipping none: they are the exact inputs of the 268-byte transform and
       any error would silently produce wrong keystream.

So this module currently CANNOT derive the six-word key set and must not be used
to claim an offline protocol keygen.  It records the verified half plus the
address range of the remaining half.
"""

from __future__ import annotations

import argparse
import json
import sys

M = 0xFFFFFFFF
MIX_A = 0x7FEB352D
MIX_B = 0x846CA68B
FNV = 0x01000193

TBL52 = b"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
TBL62 = b"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
HEXCHARS = set(b"0123456789abcdefABCDEF")

UNFINISHED_ADDR_RANGE = "0x14078b035..0x14078b0f6"


class UnfinishedTranscription(NotImplementedError):
    pass


def u32(x: int) -> int:
    return x & M


def mix_full(x: int) -> int:
    """mix_full in the sample: x^=x>>16; x*=0x7feb352d; x^=x>>15; x*=0x846ca68b; x^=x>>16."""
    x = u32(x)
    x = u32(x ^ (x >> 16))
    x = u32(x * MIX_A)
    x = u32(x ^ (x >> 15))
    x = u32(x * MIX_B)
    return u32(x ^ (x >> 16))


def mix_no_final_xor(x: int) -> int:
    x = u32(x)
    x = u32(x ^ (x >> 16))
    x = u32(x * MIX_A)
    x = u32(x ^ (x >> 15))
    return u32(x * MIX_B)


def fnv_round(acc: int, byte: int) -> int:
    """0x14078ad10..0x14078ad24: acc = ((acc ^ c) * 0x1000193) then acc ^= acc >> 13."""
    acc = u32((acc ^ byte) * FNV)
    return u32(acc ^ (acc >> 13))


def key_format_ok(key: bytes) -> bool:
    return 10 <= len(key) <= 29 and all(c in HEXCHARS for c in key)


def rolling_hash(key: bytes, seed: int) -> int:
    acc = seed
    for c in key:
        acc = fnv_round(acc, c)
    return mix_full(u32(len(key) * 0x9E3779B9) ^ acc)


def derive_partial(key: bytes) -> dict:
    if not key_format_ok(key):
        raise ValueError("card key must be 10..29 hex characters")

    bp = rolling_hash(key, 0x7DA49F05)   # ebp at 0x14078ad52..0x14078ad57
    bx = rolling_hash(key, 0xD3050EE9)   # ebx at 0x14078add5..0x14078adda

    # 28-byte token at 0x14115c3f0 (0x14078addc..0x14078ae7d)
    token = bytearray(28)
    token[0] = TBL52[bp % 52]
    r11 = u32(bx ^ 0x96B1E4A7)
    running = r11
    for i in range(1, 0x1C):
        acc = u32(bp - 0x694E1B59)
        acc = u32(acc + u32(i * 0x3C6EF372))
        acc = u32(acc + running)
        running = mix_full(acc)
        token[i] = TBL62[running % 62]

    # window values + g368/g36c (0x14078ae84..0x14078af23)
    a = u32(0x800 + (mix_no_final_xor(u32(bp ^ 0x3314BEFD)) & 0x7FF))
    b = u32(0x800 + (mix_full(u32(r11 ^ (r11 >> 16))) & 0x7FF))
    if a == b:
        b = u32(b + 1)
        if b > 0xFFF:
            b = 0x800
    g368 = u32(u32(b | 0x88000) << 2)
    g36c = u32(u32(a | 0x88000) << 2)

    # g344 (0x14078af29..0x14078af5c)
    g344 = mix_full(u32(u32(bx ^ bp) ^ 0x40591A1F))
    if g344 == 0:
        g344 = 0x8CD812FD

    return {
        "bp": bp,
        "bx": bx,
        "token": bytes(token),
        "g344": g344,
        "g368": g368,
        "g36c": g36c,
        "unfinished": UNFINISHED_ADDR_RANGE,
        "missing": ["g348", "g34c", "g350", "g354"],
    }


def derive(key: bytes) -> dict:
    out = derive_partial(key)
    if out["missing"]:
        raise UnfinishedTranscription(
            "g348/g34c/g350/g354 are not transcribed yet "
            f"({UNFINISHED_ADDR_RANGE}); the transform keystream cannot be built"
        )
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("key", nargs="?", help="card key, 10..29 hex chars")
    ap.add_argument("--check", action="store_true",
                    help="run the caller's format gate on a few vectors and exit")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    if args.check:
        vectors = ["1234567890", "CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", "abc", "0123456789abcdef0123456789ab"]
        for v in vectors:
            k = v.encode()
            print(f"  len={len(k):<3} format_ok={key_format_ok(k)}  {v}")
        return 0

    if not args.key:
        ap.error("provide a card key or --check")
    out = derive_partial(args.key.encode())
    if args.json:
        print(json.dumps({k: (v.hex() if isinstance(v, bytes) else v) for k, v in out.items()}, indent=2))
    else:
        for k, v in out.items():
            print(f"{k:11} {v.hex() if isinstance(v, bytes) else v}")
    print(f"\nNOTE: {out['missing']} not transcribed ({out['unfinished']}) -> no keygen, no keystream.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
