# Host Authority harness run for EPT-C175-COREHARNESS-01
# Modes: self-test (benign smoke) -> --input (caller/injection main) -> --response (control)
# Captures PID/PPID, writes decode_report.json + done.json on Guest.
# Credential read at runtime from host-secrets; never persisted.
$ErrorActionPreference = "Stop"

$pwPath = "<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt"
$pw = (Get-Content $pwPath -Raw).Trim()
$sec = ConvertTo-SecureString $pw -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential("<VM_USER>", $sec)
$vm = "<VM_LABEL>"

$s = New-PSSession -VMName $vm -Credential $cred
try {
    $res = Invoke-Command -Session $s -ScriptBlock {
        $py = "C:\ept_obs\python\3.13.12\python.exe"
        $wd = "C:\ept_obs"
        $txt = "C:\ept_obs\captures\stream_text.bin"
        $rdf = "C:\ept_obs\captures\stream_rdatafront.bin"
        $reg = "C:\ept_obs\captures\RG2_region_0x140e00000.bin"
        $rda = "C:\ept_obs\captures\stream_rdata.bin"
        $fin = "C:\ept_obs\forge\forge_caller_input_268.bin"
        $fres = "C:\ept_obs\forge\forge_license_response_284.bin"
        $common = @("--text",$txt,"--rdatafront",$rdf,"--data-region",$reg,"--rdata",$rda)
        function Run-Harness($label, $outDir, $extraArgs) {
            New-Item -ItemType Directory -Force -Path $outDir | Out-Null
            $so = "$outDir\stdout.txt"; $se = "$outDir\stderr.txt"
            $allArgs = @("core_local_decode_harness.py") + $extraArgs + $common
            $p = Start-Process -FilePath $py -ArgumentList $allArgs -WorkingDirectory $wd -PassThru `
                  -RedirectStandardOutput $so -RedirectStandardError $se -NoNewWindow -Wait
            # Parent of the python child is the PowerShell Direct session process running this scriptblock.
            $ppid = $PID
            # best-effort live capture of the real parent (process may have exited by now)
            try { $liveParent = (Get-CimInstance Win32_Process -Filter "ProcessId=$($p.Id)" -ErrorAction SilentlyContinue).ParentProcessId } catch { $liveParent = $null }
            $stdout = (Get-Content $so -Raw)
            $stderr = (Get-Content $se -Raw)
            @{ label=$label; exit_code=$p.ExitCode; pid=$p.Id; ppid=$ppid; ppid_live=$liveParent; stdout=$stdout; stderr=$stderr }
        }
        $out = @{}
        # 1) benign smoke: self-test
        $out.self_test = Run-Harness "self_test" "C:\ept_obs\out_selftest" @("--self-test")
        # 2) main: --input synthetic response mode
        $out.input_mode = Run-Harness "input_268" "C:\ept_obs\out" @("--input",$fin,"--out-dir","C:\ept_obs\out")
        # 3) control: --response mode
        $out.response_mode = Run-Harness "response_284" "C:\ept_obs\out_response" @("--response",$fres,"--out-dir","C:\ept_obs\out_response")

        # structured meta (clean PID/PPID + parsed report) for Host harvest
        function Parse-Report($dir){
            $f = Join-Path $dir "decode_report.json"
            if (Test-Path $f){ return (Get-Content $f -Raw | ConvertFrom-Json) }
            return $null
        }
        $meta = @{
            run_id = "EPT-C175-COREHARNESS-01"
            guest_host = $env:COMPUTERNAME
            guest_user = $env:USERNAME
            completed_utc = (Get-Date).ToUniversalTime().ToString("o")
            modes = @{
                self_test = @{ exit_code=$out.self_test.exit_code; pid=$out.self_test.pid; ppid=$out.self_test.ppid; stdout=($out.self_test.stdout -replace "`r`n","`n").Trim() }
                input_268 = @{ exit_code=$out.input_mode.exit_code; pid=$out.input_mode.pid; ppid=$out.input_mode.ppid; report=(Parse-Report "C:\ept_obs\out") }
                response_284 = @{ exit_code=$out.response_mode.exit_code; pid=$out.response_mode.pid; ppid=$out.response_mode.ppid; report=(Parse-Report "C:\ept_obs\out_response") }
            }
            notes = "caller/injection-level harness run; no Hardware.exe, no device, no network"
        }
        $meta | ConvertTo-Json -Depth 8 | Set-Content -Path "C:\ept_obs\spool\run_meta.json" -Encoding ASCII
        # completion marker
        $done = @{
            run_id = "EPT-C175-COREHARNESS-01"
            guest_host = $env:COMPUTERNAME
            completed_utc = (Get-Date).ToUniversalTime().ToString("o")
            modes = @("self_test","input_268","response_284")
            self_test_exit = $out.self_test.exit_code
            input_exit = $out.input_mode.exit_code
            response_exit = $out.response_mode.exit_code
            notes = "caller/injection-level harness run; no Hardware.exe, no device, no network"
        }
        $done | ConvertTo-Json -Depth 4 | Set-Content -Path "C:\ept_obs\spool\done.json" -Encoding ASCII
        $meta
    }
    $res | ConvertTo-Json -Depth 8 -Compress | Out-File -FilePath "<HOST_PATH>/EPT/runs/EPT-C175-COREHARNESS-01/run_result.json" -Encoding utf8
    Write-Output ($res | ConvertTo-Json -Depth 8 -Compress)
} finally {
    Remove-PSSession $s -ErrorAction SilentlyContinue
}
