p = 'auth_stage_force.cdb'
t = open(p, encoding='utf-8').read()
t = t.replace('RUN57_', 'RUN58_')

# 1) WFW: conditional big-write probe via j (canary-validated form)
old = 'bu kernel32!WriteFile ".echo WFW; r rcx; r r8; !handle @rcx f; db @rdx L8; g"'
new = ('bu kernel32!WriteFile ".echo WFW; r rcx; r r8; !handle @rcx f; db @rdx L8; '
       "j (@r8 > 0x100000) 'db @rdx+@r8-8 L8; !address @rdx; !address @rdx+@r8-8; g' 'g'\"")
assert old in t
t = t.replace(old, new)

# 2) kernelbase!CreateFile2 observer (canary-verified resolvable)
anchor = 'bu kernelbase!CreateFileW ".echo KB_CFW; du rcx; g"'
add = 'bu kernelbase!CreateFile2 ".echo KB2_CFW; du rcx; g"\n' + anchor
assert anchor in t
t = t.replace(anchor, add, 1)

# 3) attach-time static dump of the fatal decision region (image mapped at initial bp)
anchor2 = '.echo RUN58_STAGE_FORCE_BEGIN'
dump = ('.echo STATIC_FATAL_REGION_BEGIN\n'
        'u 0x1407aa640 L16\n'
        'u 0x1407aa694 L10\n'
        'u 0x1407b1090 L6\n'
        '.echo STATIC_FATAL_REGION_END\n')
assert anchor2 in t
t = t.replace(anchor2, dump + anchor2)

open(p, 'w', encoding='utf-8', newline='\n').write(t)
print('cdb58 OK; j-probe:', "j (@r8 > 0x100000)" in t, '; KB2:', 'KB2_CFW' in t, '; static dump:', 'STATIC_FATAL_REGION_BEGIN' in t)
