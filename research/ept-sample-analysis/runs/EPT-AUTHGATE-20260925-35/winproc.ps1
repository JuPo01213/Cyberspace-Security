param([Parameter(Mandatory=$true)][int]$TargetPid,[Parameter(Mandatory=$true)][string]$RunId)
$ErrorActionPreference='Continue'
$root=Join-Path 'C:\ept_obs\spool' $RunId
$log=Join-Path $root 'winproc.ndjson'
function L([hashtable]$x){$x.utc=[DateTime]::UtcNow.ToString('o');Add-Content -LiteralPath $log -Value ($x|ConvertTo-Json -Compress -Depth 4) -Encoding UTF8}
Add-Type -Namespace W7 -Name U -MemberDefinition @'
[DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, System.Text.StringBuilder t, int n);
[DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, System.Text.StringBuilder t, int n);
[DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern IntPtr SendMessageW(IntPtr h, uint m, IntPtr w, string l);
[DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lp);
[DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr p, EnumProc cb, IntPtr lp);
[DllImport("user32.dll")] public static extern bool PostMessageW(IntPtr h, uint m, IntPtr w, IntPtr l);
public delegate bool EnumProc(IntPtr h, IntPtr lp);
'@
$agree=[string][char]0x540C+[char]0x610F+[char]0x5E76+[char]0x7EE7+[char]0x7EED
$appstart=[string][char]0x5E94+[char]0x7528+[char]0x5E76+[char]0x542F+[char]0x52A8
$maincls='EPT Hardware Console'
$keyval='1234567890'
$g=@{agree=0;agreeAt=[DateTime]::MaxValue;keyset=0;app=0}
$ccb=[W7.U+EnumProc]{param($h,$lp)
  $t=New-Object System.Text.StringBuilder 256;[void][W7.U]::GetWindowTextW($h,$t,256)
  $c=New-Object System.Text.StringBuilder 256;[void][W7.U]::GetClassNameW($h,$c,256)
  $cls=$c.ToString();$txt=$t.ToString()
  if($cls -match 'Button'){
    if(($txt -eq $agree) -and ($g.agree -eq 0)){
      $ok=[W7.U]::PostMessageW($h,0xF5,[IntPtr]::Zero,[IntPtr]::Zero)
      $g.agree=1;$g.agreeAt=[DateTime]::UtcNow
      L @{type='CLICK_AGREE';hwnd=$h.ToString();result=[bool]$ok}
    } elseif(($txt -eq $appstart) -and ($g.keyset -eq 1) -and ($g.app -eq 0) -and ((([DateTime]::UtcNow)-$g.agreeAt).TotalSeconds -gt 25)){
      $ok=[W7.U]::PostMessageW($h,0xF5,[IntPtr]::Zero,[IntPtr]::Zero)
      $g.app=1
      L @{type='CLICK_APPSTART';hwnd=$h.ToString();result=[bool]$ok}
    } else {
      L @{type='BTN_SEEN';hwnd=$h.ToString();title=$txt}
    }
  } elseif(($cls -match 'Edit') -and ($g.agree -eq 1) -and ($g.keyset -eq 0) -and ((([DateTime]::UtcNow)-$g.agreeAt).TotalSeconds -gt 20)){
    $ok=[W7.U]::SendMessageW($h,0x000C,[IntPtr]::Zero,$keyval)
    $g.keyset=1
    L @{type='KEY_SETTEXT';hwnd=$h.ToString();cls=$cls;value=$keyval;result=$ok.ToInt64()}
  }
  return $true
}
$cb=[W7.U+EnumProc]{param($h,$lp)
  $c=New-Object System.Text.StringBuilder 256;[void][W7.U]::GetClassNameW($h,$c,256)
  $cls=$c.ToString()
  $t=New-Object System.Text.StringBuilder 256;[void][W7.U]::GetWindowTextW($h,$t,256)
  if($cls -eq 'NspFirstRunDisclaimerWindow'){L @{type='FOUND_DISCLAIMER';hwnd=$h.ToString()};[void][W7.U]::EnumChildWindows($h,$ccb,$h)}
  elseif($cls -eq $maincls){L @{type='FOUND_MAIN';hwnd=$h.ToString();title=$t.ToString()};[void][W7.U]::EnumChildWindows($h,$ccb,$h)}
  return $true
}
for($i=0;$i -lt 90;$i++){
  [void][W7.U]::EnumWindows($cb,[IntPtr]::Zero)
  if(($g.agree -eq 1) -and ($g.app -eq 1) -and ((([DateTime]::UtcNow)-$g.agreeAt).TotalSeconds -gt 150)){break}
  Start-Sleep -Seconds 3
}
L @{type='WINPROC_EXIT';agree=$g.agree;keyset=$g.keyset;app=$g.app}
