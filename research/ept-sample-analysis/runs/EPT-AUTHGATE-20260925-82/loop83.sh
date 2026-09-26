#!/bin/bash
cd <HOST_PATH>
for i in 1 2 3 4 5; do
  echo "=== CYCLE $i ==="
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File host_prep.ps1 2>&1 | grep -E "CHILD_FOUND|PREP_DONE" | head -2
  sleep 170
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File host_harvest.ps1 2>&1 | grep -E "HARVEST_DONE|miss child" | head -2
  python -c "
import os
if os.path.exists('child_full.dmp'): print('DMP_OK', os.path.getsize('child_full.dmp'))
else: print('still missing')
"
done
