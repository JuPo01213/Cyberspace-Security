param([Parameter(Mandatory=$true)][string]$Root)
$ErrorActionPreference='Stop'
function Hash([byte[]]$b){$h=[Security.Cryptography.SHA256]::Create();try{([BitConverter]::ToString($h.ComputeHash($b))).Replace('-','')}finally{$h.Dispose()}}
function Entropy([byte[]]$b){$counts=New-Object int[] 256;foreach($x in $b){$counts[$x]++};$e=0.0;foreach($n in $counts){if($n -gt 0){$p=$n/$b.Length;$e-1*$p*[Math]::Log($p,2)}};return [math]::Round($e,5)}
$key=[IO.File]::ReadAllBytes($Root+'\embedded-key.bin');$iv=[IO.File]::ReadAllBytes($Root+'\embedded-iv.bin');$f=[IO.File]::ReadAllBytes($Root+'\historical-config.bin')
$a=[Security.Cryptography.Aes]::Create();try{$a.Key=$key;$a.IV=$iv;$a.Mode='CBC';$a.Padding='PKCS7';$d=$a.CreateDecryptor();try{$p=$d.TransformFinalBlock($f,4,$f.Length-4)}finally{$d.Dispose()}}
finally{$a.Dispose()}
try{
 $r=@()
 foreach($o in @(0x3b,0x9f,0x103)){
  $s=[Text.Encoding]::ASCII.GetString($p,$o,99);$clean=$s -replace '\s','';$kind='other';$decoded=$null
  if($clean -match '^[A-Za-z0-9+/]+={0,2}$' -and ($clean.Length%4 -eq 0)){try{$decoded=[Convert]::FromBase64String($clean);$kind='base64'}catch{}}
  $hex=$false;if($clean -match '^[0-9A-Fa-f]+$' -and ($clean.Length%2 -eq 0)){try{$decoded=[Convert]::FromHexString($clean);$kind='hex'}catch{}}
  if($null -eq $decoded){$bytes=[Text.Encoding]::ASCII.GetBytes($s)}else{$bytes=$decoded}
  $r+=,[pscustomobject]@{offset=('0x{0:x}' -f $o);encoded_length=$s.Length;encoding=$kind;decoded_length=$bytes.Length;decoded_sha256=(Hash $bytes);decoded_entropy=(Entropy $bytes);encoded_sha256=(Hash ([Text.Encoding]::ASCII.GetBytes($s)));padding_zero_after=([Array]::IndexOf($p,[byte]0,$o+99,255-99) -ge 0)}
 }
 [ordered]@{scope='offline_configuration_field_metadata';plaintext_bytes=$p.Length;fields=$r;raw_text_emitted=$false;sample_executed=$false;authorization_proven=$false}|ConvertTo-Json -Depth 6|Set-Content -LiteralPath ($Root+'\field-metadata.json') -Encoding UTF8
}finally{[Array]::Clear($p,0,$p.Length);[Array]::Clear($key,0,$key.Length)}
'FIELD_METADATA_COMPLETE'
