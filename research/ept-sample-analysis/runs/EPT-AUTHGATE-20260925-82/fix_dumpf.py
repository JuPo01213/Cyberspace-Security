p = '<HOST_PATH>/EPT/runs/EPT-AUTHGATE-20260925-82/auth_stage_force.cdb'
t = open(p, encoding='utf-8').read()
anchor = 'logstrings.bin 141030000 L4000;'
assert anchor in t, 'anchor missing'
assert '.dump /f' not in t
t = t.replace(anchor, anchor + ' .dump /f C:\\ept_obs\\spool\\EPT-AUTHGATE-20260925-82\\child_full.dmp', 1)
open(p, 'w', encoding='utf-8', newline='\n').write(t)
t2 = open(p, encoding='utf-8').read()
print('.dump /f wired:', '.dump /f' in t2)
