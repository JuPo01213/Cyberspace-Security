param(
    [Parameter(Mandatory=$true)][string]$InputRoot,
    [Parameter(Mandatory=$true)][string]$OutputPath
)
$ErrorActionPreference='Stop'
function HashBytes([byte[]]$bytes){$sha=[Security.Cryptography.SHA256]::Create();try{([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','')}finally{$sha.Dispose()}}
function Entropy([byte[]]$bytes){$counts=New-Object int[] 256;foreach($v in $bytes){$counts[$v]++};$e=0.0;foreach($n in $counts){if($n -gt 0){$p=$n/$bytes.Length;$e += -1.0*$p*[Math]::Log($p,2)}};[Math]::Round($e,5)}
$key=[IO.File]::ReadAllBytes((Join-Path $InputRoot 'embedded-key.bin'))
$iv=[IO.File]::ReadAllBytes((Join-Path $InputRoot 'embedded-iv.bin'))
$file=[IO.File]::ReadAllBytes((Join-Path $InputRoot 'historical-config.bin'))
if($key.Length -ne 16 -or $iv.Length -ne 16 -or $file.Length -ne 900){throw 'Captured material size mismatch'}
$declared=[BitConverter]::ToInt32($file,0)
if($declared -ne 896){throw 'Configuration length mismatch'}
$aes=[Security.Cryptography.Aes]::Create()
try{$aes.Key=$key;$aes.IV=$iv;$aes.Mode=[Security.Cryptography.CipherMode]::CBC;$aes.Padding=[Security.Cryptography.PaddingMode]::PKCS7;$dec=$aes.CreateDecryptor();try{$plain=$dec.TransformFinalBlock($file,4,$declared)}finally{$dec.Dispose()}}finally{$aes.Dispose()}
if($plain.Length -ne 890){throw 'Plaintext length mismatch'}
$fields=@()
foreach($offset in @(0x3b,0x9f,0x103)){
 $text=[Text.Encoding]::ASCII.GetString($plain,$offset,99);$clean=$text.Trim()
 $kind='other';$decoded=[Text.Encoding]::ASCII.GetBytes($text)
 if($clean -match '^[A-Za-z0-9+/]+={0,2}$'){
  try{$padded=$clean;while(($padded.Length%4)-ne 0){$padded+='='};$decoded=[Convert]::FromBase64String($padded);$kind='base64_unpadded_candidate'}catch{}
 }
 if($kind -eq 'other' -and $clean -match '^[0-9A-Fa-f]+$' -and ($clean.Length%2)-eq 0){try{$decoded=[Convert]::FromHexString($clean);$kind='hex'}catch{}}
 $fields += [pscustomobject]@{offset=('0x{0:x}'-f $offset);encoded_length=$text.Length;encoding=$kind;decoded_length=$decoded.Length;encoded_sha256=(HashBytes ([Text.Encoding]::ASCII.GetBytes($text)));decoded_sha256=(HashBytes $decoded);decoded_entropy=(Entropy $decoded);raw_text_emitted=$false}
}
$report=[ordered]@{evidence_scope='offline_configuration_field_metadata';plaintext_bytes=$plain.Length;fields=$fields;encoded_fields_identical=($fields[0].encoded_sha256 -eq $fields[1].encoded_sha256 -and $fields[1].encoded_sha256 -eq $fields[2].encoded_sha256);sample_executed=$false;validation_result_modified=$false;authorization_proven=$false;external_dependencies=@()}
$report|ConvertTo-Json -Depth 6|Set-Content -LiteralPath $OutputPath -Encoding UTF8
[Array]::Clear($plain,0,$plain.Length);[Array]::Clear($key,0,$key.Length)
'FIELD_METADATA_COMPLETE'
