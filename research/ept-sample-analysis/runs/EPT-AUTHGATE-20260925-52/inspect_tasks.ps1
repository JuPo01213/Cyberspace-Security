[CmdletBinding()]
param([string]$VmName='<VM_LABEL>')
$ErrorActionPreference='Continue'
$pw=(Get-Content -LiteralPath '<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt' -Raw).Trim()
$sec=New-Object System.Security.SecureString
$pw.ToCharArray()|ForEach-Object {$sec.AppendChar($_)}
$sec.MakeReadOnly()
$cred=[pscredential]::new('<VM_USER>',$sec)
$s=New-PSSession -VMName $VmName -Credential $cred
try {
 Invoke-Command -Session $s -ScriptBlock {
  "=== TESTSIGNING (zh) ==="
  (bcdedit /enum '{current}') | Where-Object {$_ -match 'testsigning|测试签名'}
  "=== TASK DEFINITIONS ==="
  foreach($tn in @('DetectHardwareChange','RemediateHardwareChange','EPT-EPT-AUTHGATE-20260925-51')){
    $t=Get-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue
    if($t){
      "TASK $tn path=$($t.TaskPath) state=$($t.State) author=[$($t.Author)]"
      foreach($a in $t.Actions){ "  ACTION exe=[$($a.Execute)] args=[$($a.Arguments)] wd=[$($a.WorkingDirectory)]" }
      $t.Triggers|ForEach-Object {"  TRIGGER $($_.CimClass.CimClassName)"}
    } else { "TASK $tn NOT_FOUND" }
  }
  "=== CLEANUP ==="
  Unregister-ScheduledTask -TaskName 'EPT-EPT-AUTHGATE-20260925-51' -Confirm:$false -ErrorAction SilentlyContinue
  $hosts="$env:SystemRoot\System32\drivers\etc\hosts"
  $keep=@(Get-Content -LiteralPath $hosts -ErrorAction SilentlyContinue|Where-Object {$_ -ne '127.0.0.1 yz.hwid001.com'})
  Set-Content -LiteralPath $hosts -Value $keep -Encoding ASCII -Force
  & ipconfig.exe /flushdns | Out-Null
  "hosts_pin_removed="+(-not (@(Get-Content -LiteralPath $hosts) -contains '127.0.0.1 yz.hwid001.com'))
  "tasks_after="+(@(Get-ScheduledTask -ErrorAction SilentlyContinue|Where-Object {$_.TaskName -like 'EPT-*'}).Count)
  "INSPECT_DONE"
 }
} finally { Remove-PSSession $s -ErrorAction SilentlyContinue; $sec.Dispose() }
