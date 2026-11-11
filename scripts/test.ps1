[CmdletBinding()]
param([string]$Godot = $(if ($env:GODOT_BIN) { $env:GODOT_BIN } else { 'godot' }), [string]$Python = 'python',
      [Parameter(ValueFromRemainingArguments = $true)][string[]]$Words)
# The checks live in test/manifest.json and run through scripts/run_tests.py, the same runner as scripts/test.sh:
#   scripts/test.ps1            quick tier       scripts/test.ps1 flow      + the game scene
#   scripts/test.ps1 full       everything       scripts/test.ps1 smoke     boot and load every room
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$previousRuntime = $env:ROOTWARD_SANDBOX_RUNTIME
$previousGodot = $env:GODOT_BIN
$Godot = (Get-Command $Godot -ErrorAction Stop).Source
if ($Godot.EndsWith('.exe') -and !$Godot.EndsWith('_console.exe')) {
    $console = $Godot.Substring(0,$Godot.Length-4) + '_console.exe'
    if (Test-Path $console) { $Godot = $console }
}
try {
    if (!$env:ROOTWARD_SANDBOX_RUNTIME) { $env:ROOTWARD_SANDBOX_RUNTIME = Join-Path $projectRoot 'sandbox/runtime-windows' }
    $env:GODOT_BIN = $Godot
    & $Python (Join-Path $projectRoot 'scripts/run_tests.py') @Words
    if ($LASTEXITCODE -ne 0) { throw 'One or more checks failed.' }
} finally {
    $env:ROOTWARD_SANDBOX_RUNTIME = $previousRuntime
    $env:GODOT_BIN = $previousGodot
}
