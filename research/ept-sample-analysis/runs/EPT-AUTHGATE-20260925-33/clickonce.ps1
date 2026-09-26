$ErrorActionPreference='Continue'
$log='C:\ept_obs\spool\clickonce.log'
function L([hashtable]$x){$x.utc=[DateTime]::UtcNow.ToString('o');Add-Content -LiteralPath $log -Value ($x|ConvertTo-Json -Compress -Depth 4) -Encoding UTF8}
Add-Type -Namespace W4 -Name U -MemberDefinition @'
[DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, System.Text.StringBuilder t, int n);
[DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, System.Text.StringBuilder t, int n);
[DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lp);
[DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr p, EnumProc cb, IntPtr lp);
[DllImport("user32.dll")] public static extern bool PostMessageW(IntPtr h, uint m, IntPtr w, IntPtr l);
public delegate bool EnumProc(IntPtr h, IntPtr lp);
'@
$agree=[string][char]0x540C+[char]0x610F+[char]0x5E76+[char]0x7EE7+[char]0x7EED
$g=@{clicked=0}
$ccb=[W4.U+EnumProc]{param($h,$lp)
  $t=New-Object System.Text.StringBuilder 256;[void][W4.U]::GetWindowTextW($h,$t,256)
  $c=New-Object System.Text.StringBuilder 256;[void][W4.U]::GetClassNameW($h,$c,256)
  L @{type='CHILD';parent=$lp.ToString();hwnd=$h.ToString();cls=$c.ToString();title=$t.ToString()}
  if(($c.ToString() -match 'BUTTON') -and ($t.ToString() -eq $agree) -and ($g.clicked -eq 0)){
    $ok=[W4.U]::PostMessageW($h,0xF5,[IntPtr]::Zero,[IntPtr]::Zero)
    $g.clicked=1
    L @{type='CLICK_POSTED';hwnd=$h.ToString();result=[bool]$ok}
  }
  return $true
}
$cb=[W4.U+EnumProc]{param($h,$lp)
  $c=New-Object System.Text.StringBuilder 256;[void][W4.U]::GetClassNameW($h,$c,256)
  if($c.ToString() -eq 'NspFirstRunDisclaimerWindow'){
    L @{type='FOUND';hwnd=$h.ToString()}
    [void][W4.U]::EnumChildWindows($h,$ccb,$h)
  }
  return $true
}
for($i=0;$i -lt 12;$i++){
  [void][W4.U]::EnumWindows($cb,[IntPtr]::Zero)
  if($g.clicked -eq 1){break}
  Start-Sleep -Seconds 3
}
L @{type='CLICKONCE_EXIT';clicked=$g.clicked}
