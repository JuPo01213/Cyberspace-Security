p = 'auth_stage_force.cdb'
lines = open(p, encoding='utf-8').read().splitlines(keepends=True)
out = []
replaced = 0
for l in lines:
    if l.startswith('bu ws2_32!recv '):
        new = ('bu ws2_32!recv ".echo RECV; r rcx; r r8; '
               "j (r8 > 0x10) 'r $t10=@rdx; .writemem C:/ept_obs/spool/EPT-AUTHGATE-20260925-80/recvbuf_at_recv.bin @rdx L67; "
               "dd @rsp L1; u poi(@rsp) L14; g' 'g'; g\"\n")
        out.append(new)
        replaced += 1
    else:
        out.append(l)
open(p, 'w', encoding='utf-8', newline='\n').write(''.join(out))
t = open(p, encoding='utf-8').read()
print('recv lines replaced:', replaced)
print('recvbuf_at_recv present:', 'recvbuf_at_recv' in t)
print('stale -79:', 'EPT-AUTHGATE-20260925-79' in t)
