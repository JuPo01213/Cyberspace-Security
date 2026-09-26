p = 'host_prep.ps1'
lines = open(p, encoding='utf-8').read().splitlines(keepends=True)
out = []
removed_invoke = 0
removed_extra_brace = 0
seen_temp = False
for i, l in enumerate(lines):
    if 'Invoke-Command -Session $s -ScriptBlock {' in l and i > 0 and 'Windows\\Temp' not in l and '$left' not in l:
        nxt = lines[i+1] if i+1 < len(lines) else ''
        if 'Windows\\Temp' in nxt or '$left' in nxt:
            removed_invoke += 1
            continue
    out.append(l)
t = ''.join(out)
# remove the first stray lone ' }' line after TEMP_CLEANED line
lines2 = t.splitlines(keepends=True)
out2 = []
skipped = False
for i, l in enumerate(lines2):
    if not skipped and 'TEMP_CLEANED' in l:
        out2.append(l)
        # skip next line if it is a lone brace line
        if i+1 < len(lines2) and lines2[i+1].strip() == '}':
            skipped = True
            removed_extra_brace += 1
            continue
    out2.append(l)
open(p, 'w', encoding='utf-8', newline='').write(''.join(out2))
print('removed_nested_invoke=', removed_invoke, 'removed_extra_brace=', removed_extra_brace)
