$ErrorActionPreference='Continue'
$log='C:\ept_obs\spool\clickonce.log'
function L([hashtable]$x){$x.utc=[DateTime]::UtcNow.ToString('o');Add-Content -LiteralPath $log -Value ($x|ConvertTo-Json -Compress -Depth 4) -Encoding UTF8}
Add-Type -Namespace W6 -Name U -MemberDefinition @'
[DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, System.Text.StringBuilder t, int n);
[DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, System.Text.StringBuilder t, int n);
[DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lp);
[DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr p, EnumProc cb, IntPtr lp);
[DllImport("user32.dll")] public static extern bool PostMessageW(IntPtr h, uint m, IntPtr w, IntPtr l);
public delegate bool EnumProc(IntPtr h, IntPtr lp);
'@
$agree=[string][char]0x540C+[char]0x610F+[char]0x5E76+[char]0x7EE7+[char]0x7EED
$appstart=[string][char]0x5E94+[char]0x7528+[char]0x5E76+[char]0x542F+[char]0x52A8
$g=@{agree=0;agreeAt=[DateTime]::MaxValue;app=0}
$ccb=[W6.U+EnumProc]{param($h,$lp)
  $t=New-Object System.Text.StringBuilder 256;[void][W6.U]::GetWindowTextW($h,$t,256)
  $c=New-Object System.Text.StringBuilder 256;[void][W6.U]::GetClassNameW($h,$c,256)
  $cls=$c.ToString();$txt=$t.ToString()
  if($cls -match 'Button'){
    if(($txt -eq $agree) -and ($g.agree -eq 0)){
      $ok=[W6.U]::PostMessageW($h,0xF5,[IntPtr]::Zero,[IntPtr]::Zero)
      $g.agree=1;$g.agreeAt=[DateTime]::UtcNow
      L @{type='CLICK_AGREE';hwnd=$h.ToString();result=[bool]$ok}
    } elseif(($txt -eq $appstart) -and ($g.agree -eq 1) -and ($g.app -eq 0) -and ((([DateTime]::UtcNow)-$g.agreeAt).TotalSeconds -gt 25)){
      $ok=[W6.U]::PostMessageW($h,0xF5,[IntPtr]::Zero,[IntPtr]::Zero)
      $g.app=1
      L @{type='CLICK_APPSTART';hwnd=$h.ToString();result=[bool]$ok}
    } else {
      L @{type='BTN_SEEN';hwnd=$h.ToString();title=$txt}
    }
  }
  return $true
}
$cb=[W6.U+EnumProc]{param($h,$lp)
  $c=New-Object System.Text.StringBuilder 256;[void][W6.U]::GetClassNameW($h,$c,256)
  if($c.ToString() -eq 'NspFirstRunDisclaimerWindow'){L @{type='FOUND_DISCLAIMER';hwnd=$h.ToString()};[void][W6.U]::EnumChildWindows($h,$ccb,$h)}
  else{
    $t=New-Object System.Text.StringBuilder 256;[void][W6.U]::GetWindowTextW($h,$t,256)
    if($t.ToString().Length -gt 0){[void][W6.U]::EnumChildWindows($h,$ccb,$h)}
  }
  return $true
}
for($i=0;$i -lt 60;$i++){
  [void][W6.U]::EnumWindows($cb,[IntPtr]::Zero)
  if(($g.agree -eq 1) -and ($g.app -eq 1)){break}
  Start-Sleep -Seconds 3
}
Start-Sleep -Seconds 10
L @{type='CLICKONCE_EXIT';agree=$g.agree;app=$g.app}
