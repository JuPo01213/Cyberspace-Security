#!/usr/bin/env python3
"""Generate injection child.cdb + dic_ret.cdb for EPT natural-decode experiment.

Strategy (no 0xCC written into sample code):
  - Anchor only on kernel32!DeviceIoControl (system DLL, never encrypted).
  - At the license DeviceIoControl call, capture:
        lpOutBuffer    = poi(@rsp+0x28)   (5th arg)
        lpBytesReturned= poi(@rsp+0x38)   (7th arg)
    into @$t0/@$t1, then set a one-shot hardware execution bp on @$ra.
  - On return, dic_ret.cdb writes the 284-byte forged response into @$t0,
    sets *@$t1 = 284, forces RAX=1 (success), and continues.
  - Hardware execution bps (ba e) at RC00/RC06 entry/after-copy for OBSERVATION
    only (no 0xCC). Anti-debug that keyed on entry 0xCC is avoided.

Usage: python gen_inject_cdb.py <LICENSE_IOCTL_HEX> <out_dir>
"""
import sys, os

LICENSE_CODE = sys.argv[1]          # e.g. 0x390008
OUT = sys.argv[2]

hex_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'response_eb_hex.txt')
with open(hex_path) as f:
    hexbytes = f.read().strip()
assert len(hexbytes.split()) == 284, "expected 284 bytes"

child_cdb = f""".echo [INJ_CHILD_ATTACHED]
.symfix
.reload
sxd ibp
sxd epr
sxe av
bu kernel32!DeviceIoControl ".echo [INJ_DIOC]; r rdx; r r8; r r9; dq @rsp L8; .if (rdx=={LICENSE_CODE}) {{ r @$t0 = poi(@rsp+0x28); r @$t1 = poi(@rsp+0x38); ba e 1 @$ra \\"$$><dic_ret.cdb\\" }} ; g"
ba e 1 14078ee73 ".echo [INJ_RC00]; r rcx; r rdx; r r8; r r9; dq @rsp L10; k; g"
ba e 1 14078ef42 ".echo [INJ_RC06_ENTRY]; r; dq @rsp L10; k; g"
ba e 1 14078efb3 ".echo [INJ_RC06_AFTER]; r; dq @rsp L10; k; g"
sxe -c ".echo [INJ_CHILD_AV]; .lastevent; r; k; g" av
.echo [INJ_CHILD_BPS_ARMED]
g
"""

dic_ret_cdb = f""".echo [INJ_DIOC_RET]
eb @$t0 {hexbytes}
r poi(@$t1)=284
r rax=1
.echo [INJ_DIOC_RET_DONE]
g
"""

with open(os.path.join(OUT, 'child.cdb'), 'w') as f:
    f.write(child_cdb)
with open(os.path.join(OUT, 'dic_ret.cdb'), 'w') as f:
    f.write(dic_ret_cdb)
print("wrote child.cdb and dic_ret.cdb to", OUT)
print("license code =", LICENSE_CODE)
