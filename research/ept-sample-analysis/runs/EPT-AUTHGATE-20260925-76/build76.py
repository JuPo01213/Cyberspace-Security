import os, shutil
src = 'EPT-AUTHGATE-20260925-75'
dst = 'EPT-AUTHGATE-20260925-76'
os.makedirs(dst, exist_ok=True)
for f in ['auth_stage_force.cdb','canary_syntax.cdb','guest_launch.ps1','winproc.ps1','watcher.ps1','tcp1029.ps1','HpDrvPre.sys','host_prep.ps1','host_harvest.ps1','monitor_run.ps1']:
    shutil.copy(os.path.join(src, f), os.path.join(dst, f))
for f in ['host_prep.ps1','host_harvest.ps1','monitor_run.ps1','guest_launch.ps1']:
    p = os.path.join(dst, f)
    t = open(p, encoding='utf-8').read()
    t = t.replace('EPT-AUTHGATE-20260925-75', 'EPT-AUTHGATE-20260925-76')
    open(p, 'w', encoding='utf-8', newline='').write(t)

# cdb: recv-side observers with caller disassembly (decoder locator)
p = os.path.join(dst, 'auth_stage_force.cdb')
t = open(p, encoding='utf-8').read()
t = t.replace('RUN71_', 'RUN76_')
anchor = 'bu kernelbase!DeviceIoControl ".echo DIOC; r rcx; r rdx; r r8; r r9; dd @rsp+20 L4; g"'
add = ('bu ws2_32!recv ".echo RECV; r rcx; r r8; dd @rsp L1; u poi(@rsp) L14; g"\n'
       'bu ws2_32!WSARecv ".echo WSARECV; r rcx; dd @rsp L1; u poi(@rsp) L14; g"\n' + anchor)
assert anchor in t
t = t.replace(anchor, add, 1)
open(p, 'w', encoding='utf-8', newline='\n').write(t)

# tcp1029: probe table mode (Respond=3): cycle responses per connection
p = os.path.join(dst, 'tcp1029.ps1')
t = open(p, encoding='utf-8').read()
t = t.replace('[int]$Respond=1', '[int]$Respond=3')
old = """      if($Respond -eq 1){
        # Phase B: echo the frame back as a provisional protocol response (injected)
        $stream.Write($chunk,0,$n); $stream.Flush()
        L @{type='TX_ECHO';cid=$cid;bytes=$n}
      } elseif($Respond -eq 2){
        # respond with 4-byte prefix + zero body (generic ack)
        $resp=[byte[]]@(0x00,0x00,0x00,0x00)
        $stream.Write($resp,0,4); $stream.Flush()
        L @{type='TX_ACK0';cid=$cid}
      }"""
new = """      if($Respond -eq 1){
        # Phase B: echo the frame back as a provisional protocol response (injected)
        $stream.Write($chunk,0,$n); $stream.Flush()
        L @{type='TX_ECHO';cid=$cid;bytes=$n}
      } elseif($Respond -eq 2){
        # respond with 4-byte prefix + zero body (generic ack)
        $resp=[byte[]]@(0x00,0x00,0x00,0x00)
        $stream.Write($resp,0,4); $stream.Flush()
        L @{type='TX_ACK0';cid=$cid}
      } elseif($Respond -eq 3){
        # probe table: cycle response shapes per connection
        $k = ($cid - 1) % 4
        if($k -eq 0){
          $stream.Write($chunk,0,$n); $stream.Flush()
          L @{type='TX_PROBE';cid=$cid;probe='echo'}
        } elseif($k -eq 1){
          $resp=[byte[]]@(0x6B,0x00,0x00,0x00)+(New-Object byte[] 103)
          $stream.Write($resp,0,107); $stream.Flush()
          L @{type='TX_PROBE';cid=$cid;probe='len107_zeros'}
        } elseif($k -eq 2){
          $rnd=New-Object byte[] 107
          (New-Object Random($cid)).NextBytes($rnd)
          $stream.Write($rnd,0,107); $stream.Flush()
          L @{type='TX_PROBE';cid=$cid;probe='rand107_noprefix'}
        } else {
          $stream.Write($chunk,0,$n); $stream.Flush()
          $flip=[byte[]]@(0x00,0x00,0x00,0x00)
          $stream.Write($flip,0,4); $stream.Flush()
          L @{type='TX_PROBE';cid=$cid;probe='echo_plus_zero4'}
        }
      }"""
assert old in t
t = t.replace(old, new, 1)
open(p, 'w', encoding='utf-8', newline='\r\n').write(t)
print('run76 built (recv caller disasm + probe table)')
