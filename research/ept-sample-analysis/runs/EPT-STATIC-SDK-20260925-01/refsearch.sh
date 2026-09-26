#!/usr/bin/env bash
OUT="<HOST_PATH>/EPT/runs/EPT-STATIC-SDK-20260925-01"
IMG="$OUT/image_140000000.bin"
for t in 0x14252c850 0x14234b0a2 0x14251699c 0x140f9e010; do
  echo "=== /r $t ==="
  timeout 240 rizin -n -q -e scr.color=0 -e scr.utf8=false -b 64 -a x86 -m 0x140000000 -c "/r $t" "$IMG" 2>&1 | head -n 30
done
