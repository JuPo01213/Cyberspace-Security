$ErrorActionPreference='Continue'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
try {
 $s=New-PSSession -VMName <VM_LABEL> -Credential $cred -ErrorAction Stop
 Invoke-Command -Session $s -ScriptBlock {
  Get-PSDrive C | ForEach-Object {"C_free_GB=" + [math]::Round($_.Free/1GB,2) + " used_GB=" + [math]::Round($_.Used/1GB,2)}
  $t=Get-ChildItem 'C:\Windows\Temp' -File -Force -ErrorAction SilentlyContinue
  "temp_files=" + $t.Count + " temp_total_MB=" + [math]::Round(($t | Measure-Object Length -Sum).Sum/1MB,1)
  "ept_children=" + @($t | Where-Object {$_.Name -match '^EPT_'}).Count + " ept_MB=" + [math]::Round((($t | Where-Object {$_.Name -match '^EPT_'} | Measure-Object Length -Sum).Sum)/1MB,1)
  $vh=@(Get-ChildItem 'C:\Windows\Temp' -File -Force -ErrorAction SilentlyContinue | Where-Object {$_.Name -notmatch '^(EPT_|TS_)'} | Sort-Object Length -Descending | Select-Object -First 6)
  $vh | ForEach-Object {$_.Name+' '+$_.Length}
 }
 Remove-PSSession $s
} catch { "PSD_FAIL: $_" }
