p = 'auth_stage_force.cdb'
t = open(p, encoding='utf-8').read()
t = t.replace('RUN58_', 'RUN61_')

# 1) WFW: for big writes only, capture return value via gu + bytesWritten via saved pointer
old = ('bu kernel32!WriteFile ".echo WFW; r rcx; r r8; !handle @rcx f; db @rdx L8; '
       "j (@r8 > 0x100000) 'db @rdx+@r8-8 L8; !address @rdx; !address @rdx+@r8-8; g' 'g'\"")
new = ('bu kernel32!WriteFile ".echo WFW; r rcx; r r8; db @rdx L8; '
       "j (@r8 > 0x100000) 'r $t9=@r9; gu; r eax; !gle; dd @$t9 L1; g' 'g'\"")
assert old in t, 'old WFW action not found'
t = t.replace(old, new)

# 2) truncation + direct-syscall observers
anchor = 'bu kernelbase!ReadFile ".echo RDF; r rcx; r r8; g"'
add = ('bu kernelbase!SetEndOfFile ".echo SETEOF; r rcx; g"\n'
       'bu ntdll!NtWriteFile ".echo NTWF; r rcx; dd @rsp+30 L1; g"\n'
       'bu ntdll!NtReadFile ".echo NTRD; r rcx; g"\n' + anchor)
assert anchor in t
t = t.replace(anchor, add, 1)

open(p, 'w', encoding='utf-8', newline='\n').write(t)
print('cdb61 OK; gu-probe:', 'gu; r eax' in t, '; SETEOF:', 'SETEOF' in t, '; NTWF:', 'NTWF' in t)
