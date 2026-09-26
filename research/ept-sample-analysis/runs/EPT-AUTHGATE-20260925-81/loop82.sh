#!/bin/bash
cd <HOST_PATH>
for i in 1 2 3; do
  echo "=== CYCLE $i ==="
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File host_prep.ps1 2>&1 | grep -E "CHILD_FOUND|PREP_DONE" | head -2
  sleep 170
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File host_harvest.ps1 2>&1 | grep -E "HARVEST_DONE|miss dispatch" | head -2
  python -c "
import os
if os.path.exists('dispatch_low.bin'): print('DISPATCH_LOW_OK', os.path.getsize('dispatch_low.bin'))
else: print('still missing')
"
done
