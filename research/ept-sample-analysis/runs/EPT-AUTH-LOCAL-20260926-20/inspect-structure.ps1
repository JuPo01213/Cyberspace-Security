param([Parameter(Mandatory=$true)][string]$Root)
$ErrorActionPreference='Stop'
$key=[IO.File]::ReadAllBytes(($Root+'\embedded-key.bin'));$iv=[IO.File]::ReadAllBytes(($Root+'\embedded-iv.bin'));$f=[IO.File]::ReadAllBytes(($Root+'\historical-config.bin'))
$a=[Security.Cryptography.Aes]::Create()
try{
 $a.Key=$key;$a.IV=$iv;$a.Mode='CBC';$a.Padding='PKCS7';$d=$a.CreateDecryptor()
 try{$p=$d.TransformFinalBlock($f,4,$f.Length-4)}finally{$d.Dispose()}
 $ranges=New-Object 'Collections.Generic.List[object]'
 $start=0;$kind=''
 for($i=0;$i -le $p.Length;$i++){
  $next=if($i -eq $p.Length){'end'}elseif($p[$i] -eq 0){'zero'}elseif($p[$i] -ge 32 -and $p[$i] -le 126){'ascii'}else{'binary'}
  if($i -eq 0){$kind=$next}
  elseif($next -ne $kind){
   $label='not_printed'
   if($kind -eq 'ascii'){
    $v=[Text.Encoding]::ASCII.GetString($p,$start,$i-$start)
    if($v -eq '1234567890'){$label='known_test_placeholder'}
    elseif($v -match '^[A-Za-z]:\\'){$label='windows_path'}
    elseif($v -match '^[0-9A-Fa-f]+$'){$label='hex_characters'}
    elseif($v -match '^[A-Za-z0-9+/=]+$'){$label='base64_or_alphanumeric_characters'}
   }
   $ranges.Add([pscustomobject]@{offset=('0x{0:x}' -f $start);length=$i-$start;kind=$kind;label=$label})
   $start=$i;$kind=$next
  }
 }
 [ordered]@{scope='offline_configuration_structure_only';size=$p.Length;raw_strings_printed=$false;byte_class_ranges=@($ranges.ToArray());metadata_tail_hex=([BitConverter]::ToString($p[0x365..0x379]));authorization_proven=$false}|ConvertTo-Json -Depth 5|Set-Content -LiteralPath ($Root+'\config-structure.json') -Encoding UTF8
}finally{if($p){[Array]::Clear($p,0,$p.Length)};[Array]::Clear($key,0,$key.Length);$a.Dispose()}
'CONFIG_STRUCTURE_ONLY_COMPLETE'
