param(
    [Parameter(Mandatory=$true)][string]$InputRoot,
    [Parameter(Mandatory=$true)][string]$OutputPath
)
$ErrorActionPreference = 'Stop'
function HashBytes([byte[]]$bytes) {
    $h = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($h.ComputeHash($bytes))).Replace('-', '') }
    finally { $h.Dispose() }
}
function Entropy([byte[]]$bytes) {
    $counts = New-Object int[] 256
    foreach($value in $bytes) { $counts[$value]++ }
    $result = 0.0
    foreach($count in $counts) {
        if($count -gt 0) {
            $probability = $count / $bytes.Length
            $result += -1.0 * $probability * [Math]::Log($probability, 2)
        }
    }
    return [Math]::Round($result, 5)
}
$key = [IO.File]::ReadAllBytes((Join-Path $InputRoot 'embedded-key.bin'))
$iv = [IO.File]::ReadAllBytes((Join-Path $InputRoot 'embedded-iv.bin'))
$file = [IO.File]::ReadAllBytes((Join-Path $InputRoot 'historical-config.bin'))
if($key.Length -ne 16 -or $iv.Length -ne 16 -or $file.Length -ne 900) { throw 'Captured material size mismatch' }
$declared = [BitConverter]::ToInt32($file, 0)
if($declared -ne 896 -or $file.Length - 4 -ne $declared) { throw 'Configuration length contract mismatch' }
$aes = [Security.Cryptography.Aes]::Create()
try {
    $aes.Key = $key
    $aes.IV = $iv
    $aes.Mode = [Security.Cryptography.CipherMode]::CBC
    $aes.Padding = [Security.Cryptography.PaddingMode]::PKCS7
    $decoder = $aes.CreateDecryptor()
    try { $plain = $decoder.TransformFinalBlock($file, 4, $declared) }
    finally { $decoder.Dispose() }
}
finally { $aes.Dispose() }
if($plain.Length -ne 890) { throw 'Unexpected plaintext length' }
$fields = @()
foreach($offset in @(0x3b, 0x9f, 0x103)) {
    $text = [Text.Encoding]::ASCII.GetString($plain, $offset, 99)
    $clean = $text -replace '\s', ''
    $encoding = 'other'
    $decoded = [Text.Encoding]::ASCII.GetBytes($text)
    if($clean -match '^[A-Za-z0-9+/]+={0,2}$') {
        if(($clean.Length % 4) -eq 0) {
            try { $decoded = [Convert]::FromBase64String($clean); $encoding = 'base64' } catch {}
        } else {
            $padding = 4 - ($clean.Length % 4)
            try { $decoded = [Convert]::FromBase64String($clean + ('=' * $padding)); $encoding = 'base64_unpadded_candidate' } catch {}
        }
    }
    if($encoding -eq 'other' -and $clean -match '^[0-9A-Fa-f]+$' -and ($clean.Length % 2) -eq 0) {
        try { $decoded = [Convert]::FromHexString($clean); $encoding = 'hex' } catch {}
    }
    $fields += [pscustomobject]@{
        offset = ('0x{0:x}' -f $offset)
        encoded_length = $text.Length
        encoding = $encoding
        decoded_length = $decoded.Length
        encoded_sha256 = HashBytes ([Text.Encoding]::ASCII.GetBytes($text))
        decoded_sha256 = HashBytes $decoded
        decoded_entropy = Entropy $decoded
        raw_text_emitted = $false
    }
}
$report = [ordered]@{
    evidence_scope = 'offline_configuration_field_metadata'
    plaintext_bytes = $plain.Length
    fields = $fields
    sample_executed = $false
    validation_result_modified = $false
    authorization_proven = $false
}
$report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
[Array]::Clear($plain, 0, $plain.Length)
[Array]::Clear($key, 0, $key.Length)
'FIELD_METADATA_COMPLETE'
