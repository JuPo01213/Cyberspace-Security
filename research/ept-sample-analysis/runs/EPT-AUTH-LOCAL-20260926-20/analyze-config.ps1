param([Parameter(Mandatory=$true)][string]$Root)
$ErrorActionPreference='Stop'
function HashBytes([byte[]]$bytes){$h=[Security.Cryptography.SHA256]::Create();try{return ([BitConverter]::ToString($h.ComputeHash($bytes))).Replace('-','')}finally{$h.Dispose()}}
$key=[IO.File]::ReadAllBytes((Join-Path $Root 'embedded-key.bin'))
$iv=[IO.File]::ReadAllBytes((Join-Path $Root 'embedded-iv.bin'))
$file=[IO.File]::ReadAllBytes((Join-Path $Root 'historical-config.bin'))
$memory=[IO.File]::ReadAllBytes((Join-Path $Root 'config-memory.bin'))
if($key.Length -ne 16 -or $iv.Length -ne 16 -or $memory.Length -ne 890){throw 'Captured material size mismatch'}
if($file.Length -lt 4){throw 'Configuration has no length prefix'}
$declared=[BitConverter]::ToInt32($file,0)
if($declared -le 0 -or $declared -ne $file.Length-4 -or $declared%16 -ne 0){throw 'Configuration length contract mismatch'}
$aes=[Security.Cryptography.Aes]::Create()
try{
 $aes.KeySize=128;$aes.BlockSize=128;$aes.Mode=[Security.Cryptography.CipherMode]::CBC;$aes.Padding=[Security.Cryptography.PaddingMode]::PKCS7
 $aes.Key=$key;$aes.IV=$iv
 $decoder=$aes.CreateDecryptor()
 try{$plain=$decoder.TransformFinalBlock($file,4,$declared)}finally{$decoder.Dispose()}
}finally{$aes.Dispose()}
if($plain.Length -ne 890){throw ('Unexpected plaintext length: '+$plain.Length)}
$fields=@(
 [pscustomobject]@{offset='0x167';width=1;value=[int]$plain[0x167];interpretation='first byte of input region; not proven Boolean'},
 [pscustomobject]@{offset='0x365';width=4;value=[BitConverter]::ToUInt32($plain,0x365);interpretation='mode-like field; not fully typed'},
 [pscustomobject]@{offset='0x369';width=4;value=[BitConverter]::ToUInt32($plain,0x369);interpretation='nonzero check input; semantics unresolved'},
 [pscustomobject]@{offset='0x36d';width=4;value=[BitConverter]::ToUInt32($plain,0x36d);interpretation='compared with 1'},
 [pscustomobject]@{offset='0x371';width=4;value=[BitConverter]::ToUInt32($plain,0x371);interpretation='compared with 1'},
 [pscustomobject]@{offset='0x376';width=4;value=[BitConverter]::ToUInt32($plain,0x376);interpretation='mode compared with 2'}
)
$segments=foreach($s in @(@(0,0x167),@(0x167,0xff),@(0x266,0xff))){
 $bytes=New-Object byte[] $s[1];[Array]::Copy($plain,$s[0],$bytes,0,$s[1])
 $nul=[Array]::IndexOf($bytes,[byte]0)
 $ascii=@($bytes|Where-Object{$_ -ge 32 -and $_ -le 126}).Count
 [pscustomobject]@{offset=('0x{0:x}' -f $s[0]);length=$s[1];first_nul=$nul;ascii_bytes=$ascii;sha256=(HashBytes $bytes)}
}
$diff=@(for($i=0;$i -lt $plain.Length;$i++){if($plain[$i] -ne $memory[$i]){$i}})
$control=[byte[]]$file.Clone();$control[0]=$control[0] -bxor 1
$reject=([BitConverter]::ToInt32($control,0) -ne $control.Length-4)
if(!$reject){throw 'Length-negative control failed'}
$report=[ordered]@{
 evidence_scope='offline_historical_configuration_decryption'
 historical_configuration_sha256=(HashBytes $file)
 embedded_key_sha256=(HashBytes $key)
 embedded_iv_sha256=(HashBytes $iv)
 dump_configuration_sha256=(HashBytes $memory)
 algorithm='AES-128-CBC with PKCS7 padding; offline .NET implementation, not target execution'
 file_bytes=$file.Length
 ciphertext_bytes=$declared
 plaintext_bytes=$plain.Length
 plaintext_sha256=(HashBytes $plain)
 plaintext_saved=$false
 length_negative_control_rejected=$reject
 fields=$fields
 string_region_metadata=@($segments)
 cross_capture_diff_bytes=$diff.Count
 cross_capture_diff_offsets=@($diff | ForEach-Object{'0x{0:x}' -f $_})
 provenance_boundary='run65 file and run82 memory are separate historical forced runs; not same-run authorization evidence'
 authorization_status='AUTH_GATE_UNRESOLVED'
 sample_executed=$false
 validation_result_modified=$false
}
$report|ConvertTo-Json -Depth 7|Set-Content -LiteralPath (Join-Path $Root 'config-analysis.json') -Encoding UTF8
[Array]::Clear($key,0,$key.Length);[Array]::Clear($plain,0,$plain.Length)
'OFFLINE_CONFIG_DECRYPTED_AND_LENGTH_VALIDATED'
