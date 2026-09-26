p = 'auth_stage_force.cdb'
t = open(p, encoding='utf-8').read()
# rebuild the recv line cleanly for run 80: probe + save buffer + dump at recv
import re
lines = t.splitlines(keepends=True)
out = []
for l in lines:
    if l.startswith('bu ws2_32!recv '):
        new = ('bu ws2_32!recv ".echo RECV; r rcx; r r8; '
               "j (r8 > 0x10) 'r $t10=@rdx; .writemem C:/ept_obs/spool/EPT-AUTHGATE-20260925-80/recvbuf_at_recv.bin @rdx L67; "
               "dd @rsp L1; u poi(@rsp) L14; g' 'g'; g\"\n")
        out.append(new)
    elif l.startswith('.writemem') and 'text_runtime.bin' in l:
        new = l.replace('EPT-AUTHGATE-20260925-79', 'EPT-AUTHGATE-20260925-80').replace('L1B0000', 'L1B0000')
        out.append(new)
    elif l.startswith('.writemem') and ('proto_tables' in l or 'data_tables' in l):
        out.append(l.replace('EPT-AUTHGATE-20260925-78', 'EPT-AUTHGATE-20260925-80'))
    else:
        out.append(l)
t = ''.join(out)
# FATAL action: add recvbuf-at-fatal dump
old = '.writemem C:/ept_obs/spool/EPT-AUTHGATE-20260925-80/fatal_region.bin 1407aa000 L3000;'
assert old in t
t = t.replace(old, old + ' .writemem C:/ept_obs/spool/EPT-AUTHGATE-20260925-80/recvbuf_at_fatal.bin @$t10 L67; db @$t10 L67;', 1)
open(p, 'w', encoding='utf-8', newline='\n').write(t)
print('recv lifecycle + fatal dump wired')
