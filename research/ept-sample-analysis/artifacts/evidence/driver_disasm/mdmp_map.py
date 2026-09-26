import struct

p = 'runs/EPT-AUTHGATE-20260925-82/child_full_recv2.dmp'
b = open(p, 'rb').read()
print('size:', len(b))
assert b[:4] == b'MDMP', 'not a minidump'
version, nstreams, dirrva, checksum, timestamp, flags = struct.unpack_from('<IIIIII', b, 4)
print('streams:', nstreams, 'flags: 0x%016x' % flags)

streams = {}
for i in range(nstreams):
    st, sz, rva = struct.unpack_from('<III', b, dirrva + i*12)
    streams.setdefault(st, []).append((sz, rva))
print('stream types:', sorted(streams.keys()))

# MemoryListStream = 5, Memory64ListStream = 9
ranges = []  # (start_va, size, data_rva)
if 5 in streams:
    sz, rva = streams[5][0]
    n = struct.unpack_from('<I', b, rva)[0]
    for i in range(n):
        start, dsize, drva = struct.unpack_from('<QII', b, rva + 4 + i*16)
        ranges.append((start, dsize, drva))
    print('MemoryList ranges:', n)
if 9 in streams:
    sz, rva = streams[9][0]
    nranges, base_rva = struct.unpack_from('<QQ', b, rva)
    off = base_rva
    for i in range(nranges):
        start, dsize = struct.unpack_from('<QQ', b, rva + 16 + i*16)
        ranges.append((start, dsize, off))
        off += dsize
    print('Memory64 ranges:', nranges)
print('total mapped bytes:', sum(r[1] for r in ranges))

# build sorted index
ranges.sort()
def read(va, n):
    out = bytearray()
    for start, dsize, drva in ranges:
        if start <= va < start + dsize:
            take = min(n - len(out), start + dsize - va)
            o = drva + (va - start)
            out += b[o:o+take]
            va += take
            if len(out) >= n: break
    return bytes(out[:n])

def find_range(va):
    for start, dsize, drva in ranges:
        if start <= va < start + dsize: return (start, dsize, drva)
    return None

# verify: read the dispatch table pointers
for name, va in [('table_ptr_1 @0x140FA18F0', 0x140FA18F0), ('table_ptr_2 @0x1402A18F0', 0x1402A18F0), ('table_ptr_3 @0x1402A4588', 0x1402A4588)]:
    d = read(va, 8)
    r = find_range(va)
    v = struct.unpack('<Q', d)[0] if d else None
    print('%s = 0x%016x  (range %s)' % (name, v if v else 0, 'yes' if r else 'NO'))

# thread contexts: ThreadListStream = 3, find RDX of each thread
if 3 in streams:
    sz, rva = streams[3][0]
    n = struct.unpack_from('<I', b, rva)[0]
    print('threads:', n)
    for i in range(n):
        o = rva + 4 + i*48  # MINIDUMP_THREAD = 48 bytes
        tid, suspend, stack_data, stack_start, stack_size, ctx_size, ctx_rva = struct.unpack_from('<IIIQQII', b, o)
        # x64 CONTEXT: Rdx at offset 0x128 in the CONTEXT structure
        ctx = b[ctx_rva:ctx_rva+ctx_size]
        if len(ctx) >= 0x130:
            rax, rcx, rdx, rbx = struct.unpack_from('<QQQQ', ctx, 0x78)
            rsp = struct.unpack_from('<Q', ctx, 0x98)[0]
            rip = struct.unpack_from('<Q', ctx, 0xF8)[0]
            print('  TID %d: RIP=0x%016x RSP=0x%016x RDX=0x%016x' % (tid, rip, rsp, rdx))
EOF