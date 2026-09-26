$ErrorActionPreference='Continue'
$log='C:\ept_obs\spool\clickonce2.log'
function L([hashtable]$x){$x.utc=[DateTime]::UtcNow.ToString('o');Add-Content -LiteralPath $log -Value ($x|ConvertTo-Json -Compress -Depth 4) -Encoding UTF8}
Add-Type -Namespace W8 -Name U -MemberDefinition @'
[DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, System.Text.StringBuilder t, int n);
[DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, System.Text.StringBuilder t, int n);
[DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern IntPtr SendMessageW(IntPtr h, uint m, IntPtr w, string l);
[DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lp);
[DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr p, EnumProc cb, IntPtr lp);
[DllImport("user32.dll")] public static extern bool PostMessageW(IntPtr h, uint m, IntPtr w, IntPtr l);
public delegate bool EnumProc(IntPtr h, IntPtr lp);
'@
$appstart=[string][char]0x5E94+[char]0x7528+[char]0x5E76+[char]0x542F+[char]0x52A8
$g=@{keyset=0;app=0;edits=0}
$ccb=[W8.U+EnumProc]{param($h,$lp)
  $t=New-Object System.Text.StringBuilder 256;[void][W8.U]::GetWindowTextW($h,$t,256)
  $c=New-Object System.Text.StringBuilder 256;[void][W8.U]::GetClassNameW($h,$c,256)
  $cls=$c.ToString();$txt=$t.ToString()
  if($cls -match 'Edit'){
    $g.edits++
    L @{type='EDIT';hwnd=$h.ToString();title=$txt;index=$g.edits}
    if($g.keyset -eq 0){
      $ok=[W8.U]::SendMessageW($h,0x000C,[IntPtr]::Zero,'1234567890')
      $g.keyset=1
      L @{type='KEY_SETTEXT';hwnd=$h.ToString();result=$ok.ToInt64()}
    }
  } elseif(($cls -match 'Button') -and ($txt -eq $appstart) -and ($g.keyset -eq 1) -and ($g.app -eq 0)){
    $ok=[W8.U]::PostMessageW($h,0xF5,[IntPtr]::Zero,[IntPtr]::Zero)
    $g.app=1
    L @{type='CLICK_APPSTART';hwnd=$h.ToString();result=[bool]$ok}
  }
  return $true
}
$cb=[W8.U+EnumProc]{param($h,$lp)
  $c=New-Object System.Text.StringBuilder 256;[void][W8.U]::GetClassNameW($h,$c,256)
  if($c.ToString() -eq 'NspSetupWindow'){
    L @{type='FOUND_SETUPWINDOW';hwnd=$h.ToString()}
    [void][W8.U]::EnumChildWindows($h,$ccb,$h)
  }
  return $true
}
for($i=0;$i -lt 40;$i++){
  [void][W8.U]::EnumWindows($cb,[IntPtr]::Zero)
  if($g.app -eq 1){break}
  Start-Sleep -Seconds 3
}
Start-Sleep -Seconds 5
L @{type='EXIT';keyset=$g.keyset;app=$g.app;edits=$g.edits}
