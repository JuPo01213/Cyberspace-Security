p = 'auth_stage_force.cdb'
t = open(p, encoding='utf-8').read()
old = 'bu kernel32!ExitProcessImplementation ".echo EXIT_PROCESS_SKIPPED; k 10; dd @rsp L8; r rip=poi(rsp); r rsp=rsp+8; g"'
new = ('bu kernel32!ExitProcessImplementation ".echo EXIT_PROCESS_SKIPPED; k 10; dd @rsp L8; '
       '.dump /f C:\\ept_obs\\spool\\EPT-AUTHGATE-20260925-82\\early_death.dmp; '
       'r rip=poi(rsp); r rsp=rsp+8; g"')
assert old in t
t = t.replace(old, new, 1)
open(p, 'w', encoding='utf-8', newline='\n').write(t)
print('early_death dump wired:', 'early_death.dmp' in t)
