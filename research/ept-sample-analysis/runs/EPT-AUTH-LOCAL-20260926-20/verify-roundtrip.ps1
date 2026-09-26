param([Parameter(Mandatory=$true)][string]$Root)
$ErrorActionPreference='Stop'
$key=[IO.File]::ReadAllBytes(($Root+'\embedded-key.bin'))
$iv=[IO.File]::ReadAllBytes(($Root+'\embedded-iv.bin'))
$f=[IO.File]::ReadAllBytes(($Root+'\historical-config.bin'))
$a=[Security.Cryptography.Aes]::Create()
try{
 $a.Key=$key;$a.IV=$iv;$a.Mode='CBC';$a.Padding='PKCS7'
 $d=$a.CreateDecryptor();try{$p=$d.TransformFinalBlock($f,4,$f.Length-4)}finally{$d.Dispose()}
 $e=$a.CreateEncryptor();try{$c=$e.TransformFinalBlock($p,0,$p.Length)}finally{$e.Dispose()}
 $equal=$c.Length -eq $f.Length-4
 for($i=0;$i -lt $c.Length -and $equal;$i++){if($c[$i] -ne $f[$i+4]){$equal=$false}}
 if(!$equal){throw 'Configuration roundtrip mismatch'}
 $m=[IO.File]::ReadAllBytes(($Root+'\config-memory.bin'))
 $firstNul=[Array]::IndexOf($p,[byte]0,0x167,255)-0x167
 $known=[Text.Encoding]::ASCII.GetBytes('1234567890')
 $matchesKnown=$firstNul -eq $known.Length
 for($i=0;$i -lt $known.Length -and $matchesKnown;$i++){if($p[0x167+$i] -ne $known[$i]){$matchesKnown=$false}}
 $soft=($p[0x167] -ne 0 -and [BitConverter]::ToUInt32($p,0x369) -ne 0 -and [BitConverter]::ToUInt32($p,0x36d) -eq 1 -and [BitConverter]::ToUInt32($p,0x371) -eq 1)
 [ordered]@{evidence_scope='offline_configuration_reference';roundtrip_ciphertext_equal=$equal;placeholder_input_exact_match=$matchesKnown;input_length=$firstNul;static_four_field_predicate=$soft;historical_dump_first_input_byte=[int]$m[0x167];file_first_input_byte=[int]$p[0x167];source_runs_distinct=$true;authorization_proven=$false;sample_executed=$false}|ConvertTo-Json|Set-Content -LiteralPath ($Root+'\config-roundtrip.json') -Encoding UTF8
}finally{if($p){[Array]::Clear($p,0,$p.Length)};[Array]::Clear($key,0,$key.Length);$a.Dispose()}
'CONFIG_ROUNDTRIP_PASS'
