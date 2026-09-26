# Host Authority delivery for EPT-C175-COREHARNESS-01
# 1) Copy python313.tar.gz -> Guest, extract, verify ctypes works
# 2) Copy harnesses + captures + forge files, verify sha256 on Guest
# Credential read at runtime from host-secrets; never persisted.
$ErrorActionPreference = "Stop"

$pwPath = "<HOST_PATH>/VMs/<VM_LABEL>/host-secrets/<VM_USER>.password.txt"
$pw = (Get-Content $pwPath -Raw).Trim()
$sec = ConvertTo-SecureString $pw -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential("<VM_USER>", $sec)
$vm = "<VM_LABEL>"

$hostRun = "<HOST_PATH>/EPT/runs/EPT-C175-COREHARNESS-01"
$exp = @{
  stream_text = "5ae354e2983a5bf407601b3629d114b8faa1ddd731d074e8d2092c338abdf757"
  stream_rdatafront = "87bf94ecb38d5c0270e18af6f031359ead4a72e377c1068a8ef9705b182597bc"
  stream_rdata = "fb63581ccc65d4dc7adebf5f041f7a51bc4151589c22d9494be3437a933ac16f"
  RG2_region = "09d8d5de6059679957d3b49f17b9aed6b85c48756ff8d36b41e4ce6e93044c7a"
  forge_input = "7c9293e800192a21f09ffffd88c22ddeb9e83204fe221a128a8f4097cdcc5d6e"
  forge_response = "bfa525e78731beaaa2ebf1c64e993fcd933ac43d60b7a6e3d1f61576c78b0cc8"
}

$s = New-PSSession -VMName $vm -Credential $cred
try {
    # ---- Ensure Guest destination directories exist (Copy-Item -ToSession won't create them) ----
    Invoke-Command -Session $s -ScriptBlock {
        @("C:\ept_obs","C:\ept_obs\python","C:\ept_obs\captures","C:\ept_obs\forge","C:\ept_obs\out","C:\ept_obs\out_response","C:\ept_obs\spool") | ForEach-Object {
            New-Item -ItemType Directory -Force -Path $_ | Out-Null
        }
        "dirs_ready"
    }
    # ---- Data plane: python archive ----
    Copy-Item -ToSession $s -Path "$hostRun\python313.tar.gz" -Destination "C:\ept_obs\python313.tar.gz" -Force
    # ---- Data plane: harness + captures + forge ----
    Copy-Item -ToSession $s -Path "<HOST_PATH>/EPT/method/harnesses/core_local_decode_harness.py" -Destination "C:\ept_obs\core_local_decode_harness.py" -Force
    Copy-Item -ToSession $s -Path "<HOST_PATH>/EPT/method/harnesses/core_predevice_harness.py" -Destination "C:\ept_obs\core_predevice_harness.py" -Force
    Copy-Item -ToSession $s -Path "<HOST_PATH>/EPT/artifacts/captures/stream_C6/stream_text.bin" -Destination "C:\ept_obs\captures\stream_text.bin" -Force
    Copy-Item -ToSession $s -Path "<HOST_PATH>/EPT/artifacts/captures/stream_C6/stream_rdatafront.bin" -Destination "C:\ept_obs\captures\stream_rdatafront.bin" -Force
    Copy-Item -ToSession $s -Path "<HOST_PATH>/EPT/artifacts/captures/stream_C6/stream_rdata.bin" -Destination "C:\ept_obs\captures\stream_rdata.bin" -Force
    Copy-Item -ToSession $s -Path "<HOST_PATH>/EPT/artifacts/captures/RG2_region_0x140e00000.bin" -Destination "C:\ept_obs\captures\RG2_region_0x140e00000.bin" -Force
    Copy-Item -ToSession $s -Path "<HOST_PATH>/CTF/forge_caller_input_268.bin" -Destination "C:\ept_obs\forge\forge_caller_input_268.bin" -Force
    Copy-Item -ToSession $s -Path "<HOST_PATH>/CTF/forge_license_response_284.bin" -Destination "C:\ept_obs\forge\forge_license_response_284.bin" -Force

    # ---- Guest side: extract python, verify, hash-check delivered files ----
    $verify = Invoke-Command -Session $s -ArgumentList $exp -ScriptBlock {
        param($exp)
        $r = @{}
        # extract python
        New-Item -ItemType Directory -Force -Path "C:\ept_obs\python" | Out-Null
        & "C:\Windows\system32\tar.exe" -xzf "C:\ept_obs\python313.tar.gz" -C "C:\ept_obs\python" 2>&1 | Out-Null
        $py = "C:\ept_obs\python\3.13.12\python.exe"
        $r.python_present = Test-Path $py
        if ($r.python_present) {
            $ver = & $py --version 2>&1
            $r.python_version = $ver.ToString()
            # ctypes sanity
            $ct = & $py -c "import ctypes,hashlib,json,argparse,pathlib; print('CTYPES_OK', ctypes.sizeof(ctypes.c_void_p))" 2>&1
            $r.ctypes_check = $ct.ToString()
        }
        # hash check delivered captures/forge
        function sha256($f){ (certutil -hashfile $f SHA256 2>$null | Select-String -Pattern '^[0-9A-Fa-f]{64}$').Line.Trim().ToLower() }
        $r.hashes = @{}
        $m = @{
          "C:\ept_obs\captures\stream_text.bin"=$exp.stream_text;
          "C:\ept_obs\captures\stream_rdatafront.bin"=$exp.stream_rdatafront;
          "C:\ept_obs\captures\stream_rdata.bin"=$exp.stream_rdata;
          "C:\ept_obs\captures\RG2_region_0x140e00000.bin"=$exp.RG2_region;
          "C:\ept_obs\forge\forge_caller_input_268.bin"=$exp.forge_input;
          "C:\ept_obs\forge\forge_license_response_284.bin"=$exp.forge_response
        }
        foreach ($k in $m.Keys){
            $got = sha256 $k
            $r.hashes[$k] = @{ got=$got; exp=$m[$k]; ok=($got -eq $m[$k]) }
        }
        # harness file presence
        $r.harness_local = Test-Path "C:\ept_obs\core_local_decode_harness.py"
        $r.harness_predev = Test-Path "C:\ept_obs\core_predevice_harness.py"
        $r
    }
    $verify | ConvertTo-Json -Depth 6 -Compress | Out-File -FilePath "$hostRun/deliver_verify.json" -Encoding utf8
    Write-Output ($verify | ConvertTo-Json -Depth 6 -Compress)
} finally {
    Remove-PSSession $s -ErrorAction SilentlyContinue
}
