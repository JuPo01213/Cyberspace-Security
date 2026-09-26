p = 'auth_stage_force.cdb'
t = open(p, encoding='utf-8').read()
import re
m = re.search(r'bu kernel32!WriteFile "([^"]*)"', t)
old = m.group(0)
new = ('bu kernel32!WriteFile ".echo WFW; r rcx; r r8; db @rdx L8; '
       "j (r8 > 0x100000) 'r $t9=@r9; gu; r eax; !gle; dd @$t9 L1; db @$t10 L67; da @$t10 L67; g' "
       "'db @$t10 L67; g'\"")
t = t.replace(old, new, 1)
open(p, 'w', encoding='utf-8', newline='\n').write(t)
print('WriteFile action rebuilt (snapshot in both branches)')
