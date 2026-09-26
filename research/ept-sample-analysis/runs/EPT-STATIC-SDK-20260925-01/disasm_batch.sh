#!/usr/bin/env bash
OUT="<HOST_PATH>/EPT/runs/EPT-STATIC-SDK-20260925-01"
BIN="<HOST_PATH>/EPT/artifacts/captures/stream_C6/stream_text.bin"
mkdir -p "$OUT/raw"
run() {
  name="$1"; va="$2"; size="$3"
  rizin -n -q -b 64 -a x86 -m 0x140000000 -c "pD $size @ $va" "$BIN" > "$OUT/raw/$name.txt" 2>&1
  echo "$name bytes=$(wc -c < "$OUT/raw/$name.txt")"
}
run set_host 0x1403b3280 176
run init 0x1403b34d0 1750
run cardlogin_head 0x1403b3d30 8192
run get_server_option 0x1403c47e0 493
run is_login 0x1403c49d0 151
run aux_2f90 0x1403b2f90 336
run aux_30e0 0x1403b30e0 336
run aux_3320 0x1403b3320 336
echo "=== sample of set_host ==="
head -n 12 "$OUT/raw/set_host.txt"
