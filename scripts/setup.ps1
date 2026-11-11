# Everything a fresh clone needs on Windows x64 before play.ps1 and test.ps1:
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\setup.ps1          runtime + the game's media
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\setup.ps1 -Dev     also the art sources
# Needs Python 3.11 or later (py or python on the PATH). Safe to re-run.
[CmdletBinding()]
param([switch]$Dev)
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
& (Join-Path $PSScriptRoot 'setup-runtime.ps1')
$python = if (Get-Command py -ErrorAction SilentlyContinue) { 'py' } elseif (Get-Command python -ErrorAction SilentlyContinue) { 'python' } else { throw 'Python 3 is needed to fetch the media: install it from python.org.' }
$packs = if ($Dev) { 'all' } else { 'game' }
& $python (Join-Path $projectRoot 'scripts/media.py') fetch $packs
if ($LASTEXITCODE -ne 0) { throw 'Fetching the media failed.' }
Write-Host 'Ready: .\scripts\play.ps1 to play, .\scripts\test.ps1 to test.'
