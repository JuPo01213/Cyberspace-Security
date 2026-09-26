import re
p = r'<HOST_PATH>\EPT\runs\EPT-AUTHGATE-20260925-54\host_prep.ps1'
raw = open(p, 'rb').read()
lines = raw.split(b'\n')
good = b"  $sym='C:\\Program Files (x86)\\Windows Kits\\10\\Debuggers\\x64\\sym'\r"
fixed = 0
for i, l in enumerate(lines):
    if b'Debuggers' in l and b'sym' in l and (b'\x08' in l or b'\\=' in l):
        lines[i] = good
        fixed += 1
open(p, 'wb').write(b'\n'.join(lines))
chk = open(p, 'rb').read()
print('fixed=', fixed)
print('backspace_remaining=', b'\x08' in chk)
print('good_line_present=', good in chk)
print('symvar_line=', [l for l in chk.split(b'\n') if b'$sym=' in l])
