# Adapter Reference

Use only the section that matches the backend selected in WGE-01.

This file contains verified command families and conservative templates. Local versions may differ. When a command rejects a documented option, query the local tool help before changing syntax.

Never put passwords, tokens, private addresses, local usernames, or unsanitized absolute paths into repository files.

## Hyper-V: PowerShell Direct

Use when the Host runs Hyper-V and the Guest supports PowerShell Direct.

Microsoft documents PowerShell Direct for Windows 10 / Windows Server 2016 or later Hosts and Guests. It does not depend on Guest network configuration.

### Control canary

~~~powershell
$cred = Get-Credential
$nonce = [guid]::NewGuid().ToString("N")
Invoke-Command -VMName "<VM_LABEL>" -Credential $cred -ArgumentList $nonce -ScriptBlock {
    param($n)
    [pscustomobject]@{
        Marker = "WGE_$n"
        ComputerName = $env:COMPUTERNAME
        User = [Security.Principal.WindowsIdentity]::GetCurrent().Name
        Pwd = (Get-Location).Path
        PSVersion = $PSVersionTable.PSVersion.ToString()
    }
}
~~~

Pass only when Marker equals the fresh Host nonce and the context is expected.

### Persistent data session

~~~powershell
$cred = Get-Credential
$s = New-PSSession -VMName "<VM_LABEL>" -Credential $cred
Copy-Item -ToSession $s -Path "<HOST_CANARY_FILE>" -Destination "<GUEST_CANARY_DIR>"
Copy-Item -FromSession $s -Path "<GUEST_RESULT_FILE>" -Destination "<HOST_HARVEST_DIR>"
Remove-PSSession $s
~~~

Treat each new PSSession as a new scope. Re-run path/data canaries when mappings or identity context matter.

### Important boundary

PowerShell Direct proves command/data reachability inside the Guest. It does not prove an interactive desktop session exists. Do not use it as evidence that GUI behavior launched in session 0 is equivalent to a user desktop run.

Official reference:
https://learn.microsoft.com/windows-server/virtualization/hyper-v/powershell-direct

## Oracle VirtualBox: Guest Control

Use only when VBoxManage is present and Guest Additions Guest Control is functioning.

Oracle documents guestcontrol run/start and copyfrom/copyto. Guest credentials are required by these subcommands.

Before use:

~~~powershell
VBoxManage --version
VBoxManage guestcontrol "<VM_LABEL>" --help
~~~

### Control canary

Prefer run when stdout/stderr is needed for the canary:

~~~text
VBoxManage guestcontrol "<VM_LABEL>" run --username "<GUEST_USER>" --passwordfile "<SECRET_FILE>" --exe "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -- powershell.exe -NoProfile -Command "<BENIGN_NONCE_COMMAND>"
~~~

Use a password file or another secure credential mechanism rather than embedding a password in repository content or logs.

### Detached launch

Oracle distinguishes run from start. In current VirtualBox documentation, start returns after the guest program is successfully started and does not wait for all stdout/stderr.

Use start only after a long-runner canary proves the process survives the control call and after defining an external completion marker.

### Data canary

Host to Guest:

~~~text
VBoxManage guestcontrol "<VM_LABEL>" copyto --username "<GUEST_USER>" --passwordfile "<SECRET_FILE>" --target-directory="<GUEST_DIR>" "<HOST_FILE>"
~~~

Guest to Host:

~~~text
VBoxManage guestcontrol "<VM_LABEL>" copyfrom --username "<GUEST_USER>" --passwordfile "<SECRET_FILE>" --target-directory="<HOST_DIR>" "<GUEST_FILE>"
~~~

Do not infer success from a Guest path string alone. Verify the Host copy.

Official reference:
https://docs.oracle.com/en/virtualization/virtualbox/7.1/user/vboxmanage.html

## SSH / SCP

Use when the Guest has an explicitly provisioned SSH service and the network path is part of the intended lab design.

Control canary requirements:

- TCP reachability is not enough;
- SSH banner is not enough;
- authentication success is not enough;
- a command must execute and return a fresh nonce.

Generic pattern:

~~~text
ssh <HOST_ALIAS> "<BENIGN_NONCE_COMMAND>"
scp <HOST_FILE> <HOST_ALIAS>:<GUEST_PATH>
scp <HOST_ALIAS>:<GUEST_FILE> <HOST_PATH>
~~~

Prefer an SSH config Host alias or secret store. Do not commit private IPs, usernames, keys, or passwords.

A disconnect after dispatch is not proof the Guest process stopped. Reconcile the OP before retry.

## SMB / UNC

Treat SMB as a data adapter unless it is explicitly proven as part of control.

Rules:

- use UNC paths when possible instead of assuming mapped-drive letters survive across sessions;
- a mapping created in one logon/PSSession does not prove visibility in another;
- perform a nonce write/read/hash canary from the same execution context that will use the share;
- distinguish PATH_SCOPE_MISMATCH from FILE_NOT_READY.

Do not store credentials in scripts committed to the repository.

## CDB

Use CDB only in an instrumentation run. Natural-run conclusions remain separate.

Microsoft documents:

- -p PID: attach to an existing process;
- -pv: noninvasive attach;
- -pvr: noninvasive attach without suspending the target;
- -pb: suppress the initial break-in request when attaching;
- -pd: do not terminate the target when the debugging session ends;
- -c "command": run initial debugger commands;
- -cf "filename": run commands from a script file.

### Benign smoke

First select a benign process specifically created for the smoke test. Then choose the least intrusive attach mode that can answer the instrumentation question.

Examples of documented command families:

~~~text
cdb.exe -p <PID>
cdb.exe -pv -p <PID>
cdb.exe -pvr -p <PID>
cdb.exe -p <PID> -pd -cf "<DEBUGGER_SCRIPT>"
~~~

Do not combine flags mechanically. For example, -pb changes initial attach behavior and must be validated on the benign target before use on the real run.

For long command sequences, prefer a debugger script file through -cf rather than deeply nested shell quoting.

Pass the instrumentation canary only when the expected debugger event is observed in raw harvested output and the parser does not merely match echoed configuration text.

Official reference:
https://learn.microsoft.com/windows-hardware/drivers/debugger/cdb-command-line-options
