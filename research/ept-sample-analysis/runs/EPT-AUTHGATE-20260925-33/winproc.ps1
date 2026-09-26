param([Parameter(Mandatory=$true)][int]$TargetPid,[Parameter(Mandatory=$true)][string]$RunId)
$ErrorActionPreference='Continue'
$root=Join-Path 'C:\ept_obs\spool' $RunId
$log=Join-Path $root 'winproc.ndjson'
function L([hashtable]$x){$x.utc=[DateTime]::UtcNow.ToString('o');Add-Content -LiteralPath $log -Value ($x|ConvertTo-Json -Compress -Depth 4) -Encoding UTF8}
Add-Type -Namespace W -Name U -MemberDefinition @'
[DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern IntPtr FindWindowW(string cls, string title);
[DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern IntPtr FindWindowExW(IntPtr parent, IntPtr after, string cls, string title);
[DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, System.Text.StringBuilder t, int n);
[DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, System.Text.StringBuilder t, int n);
[DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lp);
[DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr p, EnumProc cb, IntPtr lp);
[DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
[DllImport("user32.dll")] public static extern bool PostMessageW(IntPtr h, uint m, IntPtr w, IntPtr l);
public delegate bool EnumProc(IntPtr h, IntPtr lp);
'@
$agree=[string][char]0x540C+[char]0x610F+[char]0x5E76+[char]0x7EE7+[char]0x7EED
$disagree=[string][char]0x4E0D+[char]0x540C+[char]0x610F+[char]0x5E76+[char]0x9000+[char]0x51FA
$found=@{}
$cb=[W.U+EnumProc]{param($h,$lp)
  $pid2=0;[void][W.U]::GetWindowThreadProcessId($h,[ref]$pid2)
  if($pid2 -eq $TargetPid){
    $t=New-Object System.Text.StringBuilder 256;[void][W.U]::GetWindowTextW($h,$t,256)
    $c=New-Object System.Text.StringBuilder 256;[void][W.U]::GetClassNameW($h,$c,256)
    L @{type='WIN';hwnd=$h.ToString();cls=$c.ToString();title=$t.ToString()}
  }
  return $true
}
$ccb=[W.U+EnumProc]{param($h,$lp)
  $t=New-Object System.Text.StringBuilder 256;[void][W.U]::GetWindowTextW($h,$t,256)
  $c=New-Object System.Text.StringBuilder 256;[void][W.U]::GetClassNameW($h,$c,256)
  L @{type='CHILD';parent=$lp.ToString();hwnd=$h.ToString();cls=$c.ToString();title=$t.ToString()}
  return $true
}
for($i=0;$i -lt 110;$i++){
  $dw=[W.U]::FindWindowW('NspFirstRunDisclaimerWindow',$null)
  if($dw -ne [IntPtr]::Zero){
    if(-not $found.ContainsKey($dw.ToString())){
      $found[$dw.ToString()]=$i
      L @{type='DISCLAIMER_FOUND';hwnd=$dw.ToString();iter=$i}
      [void][W.U]::EnumChildWindows($dw,$ccb,$dw)
      $btn=[IntPtr]::Zero
      $cur=[IntPtr]::Zero
      while($true){
        $cur=[W.U]::FindWindowExW($dw,$cur,'BUTTON',$null)
        if($cur -eq [IntPtr]::Zero){break}
        $t=New-Object System.Text.StringBuilder 256;[void][W.U]::GetWindowTextW($cur,$t,256)
        L @{type='BUTTON';hwnd=$cur.ToString();title=$t.ToString()}
        if($t.ToString() -eq $agree){$btn=$cur}
      }
      if($btn -ne [IntPtr]::Zero){
        L @{type='CLICK_AGREE';hwnd=$btn.ToString()}
        [void][W.U]::PostMessageW($btn,0xF5,[IntPtr]::Zero,[IntPtr]::Zero)
        L @{type='CLICK_POSTED'}
      } else {
        L @{type='AGREE_BUTTON_NOT_FOUND';disagree_title=$disagree}
      }
    }
  }
  if($i % 10 -eq 0){[void][W.U]::EnumWindows($cb,[IntPtr]::Zero)}
  Start-Sleep -Seconds 3
}
L @{type='WINPROC_EXIT'}
