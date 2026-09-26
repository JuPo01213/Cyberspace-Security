p = 'auth_stage_force.cdb'
t = open(p, encoding='utf-8').read()
t = t.replace('RUN56_', 'RUN57_')
anchor = 'bu kernelbase!ReadFile ".echo RDF; r rcx; r r8; g"'
add = 'bu kernelbase!CreateFileW ".echo KB_CFW; du rcx; g"\n' + anchor
assert anchor in t and 'KB_CFW' not in t
t = t.replace(anchor, add, 1)
open(p, 'w', encoding='utf-8', newline='\n').write(t)
print('KB_CFW added:', 'KB_CFW' in t)
