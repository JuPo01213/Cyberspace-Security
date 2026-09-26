p = 'host_prep.ps1'
lines = open(p, 'rb').read().split(b'\n')
good = b"  $sym='C:\\Program Files (x86)\\Windows Kits\\10\\Debuggers\\x64\\sym'\r"
fixed = 0
for i, l in enumerate(lines):
    if b'$sym=' in l and b'Debuggers' in l and b'cdb' not in l:
        lines[i] = good
        fixed += 1
open(p, 'wb').write(b'\n'.join(lines))
chk = open(p, 'rb').read()
print('fixed=', fixed)
print('backspace=', b'\x08' in chk)
print('lines:', [l for l in chk.split(b'\n') if b'$sym=' in l])
