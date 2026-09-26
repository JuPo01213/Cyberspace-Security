import re, os, json, collections

RAWDIR = r"<HOST_PATH>\EPT\runs\EPT-STATIC-SDK-20260925-01\raw"
OUTDIR = r"<HOST_PATH>\EPT\runs\EPT-STATIC-SDK-20260925-01"
ANSI = re.compile(r"\x1b\[[0-9;]*m")
LINE = re.compile(r"^\s*(?:[^\s0-9a-fx][\s]*)?(0x[0-9a-f]+)\s+(\S+)\s*(.*)$")

summary = []
allcalls = []
for fn in sorted(os.listdir(RAWDIR)):
    if not fn.endswith(".txt"):
        continue
    name = fn[:-4]
    txt = ANSI.sub("", open(os.path.join(RAWDIR, fn), 'r', errors='replace').read())
    insns = []
    for line in txt.splitlines():
        m = LINE.match(line)
        if not m:
            continue
        va = int(m.group(1), 16)
        mn = m.group(2)
        ops = m.group(3).strip()
        insns.append((va, mn, ops))
    if not insns:
        summary.append({"name": name, "instructions": 0, "note": "NO_PARSE"})
        continue
    vas = [i[0] for i in insns]
    lo, hi = min(vas), max(vas)
    bad = [i for i in insns if i[1] in ("invalid", "(bad)", "???")]
    first_bad = bad[0][0] if bad else None
    calls = [i for i in insns if i[1].startswith("call")]
    jmps = [i for i in insns if i[1].startswith("jmp")]
    leas = [i for i in insns if i[1] == "lea"]
    summary.append({
        "name": name,
        "instructions": len(insns),
        "span_lo": hex(lo),
        "span_hi": hex(hi),
        "span_bytes": hi - lo,
        "invalid_count": len(bad),
        "first_invalid_va": hex(first_bad) if first_bad else None,
        "call_count": len(calls),
        "jmp_count": len(jmps),
        "lea_count": len(leas),
    })
    for va, mn, ops in calls:
        t = re.search(r"(0x[0-9a-f]+)", ops)
        allcalls.append({"func": name, "va": hex(va), "target": t.group(1) if t else None, "text": ops})

with open(os.path.join(OUTDIR, "sdk_parse_summary.json"), "w") as f:
    json.dump(summary, f, indent=2)
with open(os.path.join(OUTDIR, "sdk_call_targets.json"), "w") as f:
    json.dump(allcalls, f, indent=2)

for s in summary:
    print(s)
print("---- direct call targets ----")
by = collections.OrderedDict()
for c in allcalls:
    by.setdefault(c["func"], []).append((c["va"], c["target"]))
for k, v in by.items():
    print(k, len(v))
    for va, t in v[:40]:
        print("   ", va, "->", t)
