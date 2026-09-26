p = 'auth_stage_force.cdb'
t = open(p, encoding='utf-8').read()
t = t.replace('C:/ept_obs/spool/EPT-AUTHGATE-20260925-70/fatal_region.bin',
              'C:/ept_obs/spool/EPT-AUTHGATE-20260925-80/fatal_region.bin')
t = t.replace('EPT-AUTHGATE-20260925-78/proto_tables', 'EPT-AUTHGATE-20260925-80/proto_tables')
t = t.replace('EPT-AUTHGATE-20260925-78/data_tables', 'EPT-AUTHGATE-20260925-80/data_tables')
old = '.writemem C:/ept_obs/spool/EPT-AUTHGATE-20260925-80/fatal_region.bin 1407aa000 L3000;'
assert old in t, 'fatal_region anchor missing'
add = old + ' .writemem C:/ept_obs/spool/EPT-AUTHGATE-20260925-80/recvbuf_at_fatal.bin @$t10 L67; db @$t10 L67;'
if 'recvbuf_at_fatal' not in t:
    t = t.replace(old, add, 1)
open(p, 'w', encoding='utf-8', newline='\n').write(t)
t2 = open(p, encoding='utf-8').read()
print('recvbuf_at_fatal in file:', 'recvbuf_at_fatal' in t2)
print('stale -79 refs:', 'EPT-AUTHGATE-20260925-79' in t2)
print('stale -70 fatal ref:', 'EPT-AUTHGATE-20260925-70/fatal' in t2)
