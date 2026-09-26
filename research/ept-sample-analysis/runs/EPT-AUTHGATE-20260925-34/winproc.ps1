param([Parameter(Mandatory=$true)][int]$TargetPid,[Parameter(Mandatory=$true)][string]$RunId)
$ErrorActionPreference='Continue'
$root=Join-Path 'C:\ept_obs\spool' $RunId
$log=Join-Path $root 'winproc.ndjson'
function L([hashtable]$x){$x.utc=[DateTime]::UtcNow.ToString('o');Add-Content -LiteralPath $log -Value ($x|ConvertTo-Json -Compress -Depth 4) -Encoding UTF8}
Add-Type -Namespace W5 -Name U -MemberDefinition @'
[DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, System.Text.StringBuilder t, int n);
[DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, System.Text.StringBuilder t, int n);
[DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lp);
[DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr p, EnumProc cb, IntPtr lp);
[DllImport("user32.dll")] public static extern bool PostMessageW(IntPtr h, uint m, IntPtr w, IntPtr l);
public delegate bool EnumProc(IntPtr h, IntPtr lp);
'@
$agree=[string][char]0x540C+[char]0x610F+[char]0x5E76+[char]0x7EE7+[char]0x7EED
$appstart=[string][char]0x5E94+[char]0x7528+[char]0x5E76+[char]0x542F+[char]0x52A8
$g=@{agreeClicked=0;appClicked=0;agreeAt=[DateTime]::MaxValue}
$ccb=[W5.U+EnumProc]{param($h,$lp)
  $t=New-Object System.Text.StringBuilder 256;[void][W5.U]::GetWindowTextW($h,$t,256)
  $c=New-Object System.Text.StringBuilder 256;[void][W5.U]::GetClassNameW($h,$c,256)
  $cls=$c.ToString();$txt=$t.ToString()
  if($cls -match 'Button'){
    L @{type='BTN';parent=$lp.ToString();hwnd=$h.ToString();title=$txt}
    if(($txt -eq $agree) -and ($g.agreeClicked -eq 0)){
      $ok=[W5.U]::PostMessageW($h,0xF5,[IntPtr]::Zero,[IntPtr]::Zero)
      $g.agreeClicked=1;$g.agreeAt=[DateTime]::UtcNow
      L @{type='CLICK_AGREE';hwnd=$h.ToString();result=[bool]$ok}
    } elseif(($txt -eq $appstart) -and ($g.agreeClicked -eq 1) -and ($g.appClicked -eq 0) -and ((([DateTime]::UtcNow)-$g.agreeAt).TotalSeconds -gt 20)){
      $ok=[W5.U]::PostMessageW($h,0xF5,[IntPtr]::Zero,[IntPtr]::Zero)
      $g.appClicked=1
      L @{type='CLICK_APPSTART';hwnd=$h.ToString();result=[bool]$ok}
    }
  }
  return $true
}
$cb=[W5.U+EnumProc]{param($h,$lp)
  $pid2=0;[void][W5.U]::GetWindowThreadProcessId($h,[ref]$pid2)
  if($pid2 -eq $TargetPid){
    $c=New-Object System.Text.StringBuilder 256;[void][W5.U]::GetClassNameW($h,$c,256)
    $t=New-Object System.Text.StringBuilder 256;[void][W5.U]::GetWindowTextW($h,$t,256)
    L @{type='WIN';hwnd=$h.ToString();cls=$c.ToString();title=$t.ToString()}
    [void][W5.U]::EnumChildWindows($h,$ccb,$h)
  }
  return $true
}
for($i=0;$i -lt 150;$i++){
  [void][W5.U]::EnumWindows($cb,[IntPtr]::Zero)
  if(($g.agreeClicked -eq 1) -and ($g.appClicked -eq 1) -and ((([DateTime]::UtcNow)-$g.agreeAt).TotalSeconds -gt 90)){break}
  Start-Sleep -Seconds 3
}
L @{type='WINPROC_EXIT';agreeClicked=$g.agreeClicked;appClicked=$g.appClicked}
