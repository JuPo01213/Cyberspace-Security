#!/usr/bin/env python3
"""相邻副本差分：判定"追加块"是记录/填充还是密码链。

用法:  python diff-chain.py <目录或文件...> --base <原始体字节数>
产出:  1) 每对相邻副本的首个差异偏移
       2) 新增区域是否恰好等于一个定长块
       3) 原始体是否被就地改写（必须为"否"才支持"纯追加"模型）
       4) 块内明文字段探测（长度/序号/时间戳/指针/状态码/填充）
       5) 前块摘要是否参与后块的准入判据
"""
import sys, os, struct, collections, math, hashlib, argparse

def entropy(b):
    if not b: return 0.0
    c = collections.Counter(b); n = len(b)
    return -sum((v / n) * math.log2(v / n) for v in c.values())

def load(path, base):
    with open(path, 'rb') as f:
        f.seek(base)
        return f.read()

def probe_fields(blk, size):
    """Look for plaintext record structure inside one appended block."""
    hits = []
    for off in range(0, size - 4):
        v = struct.unpack_from('<I', blk, off)[0]
        # plausible little-endian length/serial
        if 0 < v <= 0x10000 and off < 32:
            hits.append(('u32@%d' % off, v))
        # FILETIME-ish: 1e17..1.4e17 ns since 1601
        if off + 8 <= size:
            q = struct.unpack_from('<Q', blk, off)[0]
            if 132000000000000000 < q < 136000000000000000:
                hits.append(('filetime@%d' % off, q))
        # unix epoch-ish seconds for 2020-2035
        if 1577836800 < v < 2145916800:
            hits.append(('epoch@%d' % off, v))
    return hits

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('paths', nargs='+')
    ap.add_argument('--base', type=int, required=True, help='原始体字节数')
    ap.add_argument('--block', type=int, default=256)
    a = ap.parse_args()

    files = []
    for p in a.paths:
        if os.path.isdir(p):
            files += [os.path.join(p, f) for f in sorted(os.listdir(p)) if os.path.isfile(os.path.join(p, f))]
        else:
            files.append(p)
    cands = []
    for f in files:
        s = os.path.getsize(f)
        if s > a.base and (s - a.base) % a.block == 0:
            cands.append(((s - a.base) // a.block, s, f))
    cands.sort()
    print("candidate copies:", len(cands))
    if not cands:
        print("no copy is larger than base by a multiple of block — the 'append-only' model is NOT supported")
        return

    print("\n1) growth ladder (hop, size, name)")
    prev = None
    strict_one_block = True
    for hop, s, f in cands:
        if prev is not None and hop != prev + 1:
            strict_one_block = False
        print("   hop=%-3d size=%-10d %s" % (hop, s, os.path.basename(f)))
        prev = hop
    print("   consecutive hops 1..N without gaps:", strict_one_block)

    print("\n2) is the original body untouched in every copy? (compare head/tail windows to smallest copy)")
    ref = cands[0][2]
    with open(ref, 'rb') as fh:
        head = fh.read(min(65536, a.base)); fh.seek(max(0, a.base - 65536)); tail = fh.read(65536)
    bad = 0
    for hop, s, f in cands:
        with open(f, 'rb') as fh:
            h2 = fh.read(len(head)); fh.seek(max(0, a.base - len(tail))); t2 = fh.read(len(tail))
        if h2 != head or t2 != tail:
            bad += 1
    print("   copies whose body differs:", bad, "=> pure-append model", "OK" if bad == 0 else "VIOLATED")

    print("\n3) prefix stability of the appended ledger (append-only?)")
    ok = True
    for i in range(1, len(cands)):
        k0, s0, f0 = cands[i - 1]; k1, s1, f1 = cands[i]
        if k1 <= k0: continue
        L0 = load(f0, a.base); L1 = load(f1, a.base)
        if L1[:len(L0)] != L0:
            ok = False; print("   prefix mismatch entering hop", k1)
    print("   ledger prefix stable across all adjacent pairs:", ok)

    print("\n4) new-block field probe on the newest block of each copy")
    field_seen = 0
    for hop, s, f in cands[-4:]:
        L = load(f, a.base)
        blk = L[(hop - 1) * a.block: hop * a.block]
        pr = probe_fields(blk, len(blk))
        printable = sum(1 for c in blk if 32 <= c < 127) / len(blk)
        distinct = len(set(blk))
        exp_distinct = 256 * (1 - (1 - 1 / 256) ** 256)
        print("   hop=%-3d ent=%.2f printable=%.3f distinct=%d (uniform-256 expects ~%.0f) fields=%s"
              % (hop, entropy(blk), printable, distinct, exp_distinct, pr[:6] or 'none'))
        field_seen += len(pr)
    print("   plaintext field candidates total:", field_seen)

    print("\n5) crypto-chain admission test (does a prior block's digest feed the next block?)")
    L = load(cands[-1][2], a.base)
    blocks = [L[i * a.block:(i + 1) * a.block] for i in range(len(L) // a.block)]
    linked = 0
    for i in range(len(blocks) - 1):
        for algo in (hashlib.sha256, hashlib.sha1, hashlib.md5):
            if algo(blocks[i]).digest()[:16] == blocks[i + 1][:16]:
                linked += 1
    print("   adjacent blocks where digest(prev) prefixes next:", linked)
    print("   CONCLUSION:", "crypto analysis permitted" if linked else
          "NO evidence of hashing/nonce chaining -> downgrade to record-format analysis; "
          "cross-run reproducibility of block #1 is the cheapest next gate "
          "(same snapshot, rerun: if R1 differs it is runtime-random and both crypto and local forgery are dead ends)")

main()
