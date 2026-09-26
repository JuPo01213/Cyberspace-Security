#!/bin/bash
cd <HOST_PATH>
for i in 1 2 3; do
  echo "=== CYCLE $i ==="
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File host_prep.ps1 2>&1 | grep -E "CHILD_FOUND|PREP_DONE" | head -2
  sleep 170
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File host_harvest.ps1 2>&1 | grep -E "HARVEST_DONE|miss logstrings" | head -2
  python -c "
import os
if os.path.exists('logstrings.bin'):
    print('LOGSTRINGS_OK', os.path.getsize('logstrings.bin'))
else:
    print('still missing')
"
done
