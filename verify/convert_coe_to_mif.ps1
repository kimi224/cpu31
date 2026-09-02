param(
    [Parameter(Mandatory = $true)]
    [string]$CoePath,
    [Parameter(Mandatory = $true)]
    [string]$MifPath
)

$ErrorActionPreference = 'Stop'

$lines = Get-Content -LiteralPath $CoePath
$start = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match 'memory_initialization_vector') {
        $start = $i + 1
        break
    }
}

if ($start -lt 0) {
    throw "Could not find memory_initialization_vector in $CoePath"
}

$tokens = New-Object System.Collections.Generic.List[string]
for ($i = $start; $i -lt $lines.Count; $i++) {
    $line = $lines[$i].Trim()
    if (-not $line) {
        continue
    }

    $line = $line -replace ';', ''
    $line = $line -replace ',', ''
    $line = $line.Trim()

    if (-not $line) {
        continue
    }

    $tokens.Add($line)
}

$mifLines = foreach ($token in $tokens) {
    [Convert]::ToString([Convert]::ToUInt32($token, 16), 2).PadLeft(32, '0')
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $MifPath) | Out-Null
Set-Content -LiteralPath $MifPath -Value $mifLines -Encoding ascii

Write-Output "MIF=$MifPath"
Write-Output "COUNT=$($mifLines.Count)"
