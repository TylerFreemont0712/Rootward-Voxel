[CmdletBinding()]
param(
    [string]$Godot = $(if ($env:GODOT_BIN) { $env:GODOT_BIN } else { 'godot' }),
    [ValidateSet('compatibility','mobile','forward_plus')][string]$Renderer = 'compatibility',
    [int]$GpuIndex = -1,
    [ValidateSet('auto','vulkan','d3d12','opengl3')][string]$Driver = 'auto',
    [string[]]$GodotArgs = @()
)
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$previousRuntime = $env:ROOTWARD_SANDBOX_RUNTIME
$runtimeRoot = if ($previousRuntime) { $previousRuntime } else { Join-Path $projectRoot 'sandbox/runtime-windows' }
if (!(Test-Path (Join-Path $runtimeRoot 'bin/wasmtime.exe')) -or !(Test-Path (Join-Path $runtimeRoot 'python/python.cwasm'))) {
    throw 'The Windows Python/WASI runtime is missing. Run .\scripts\setup.ps1 first.'
}
$python = if (Get-Command py -ErrorAction SilentlyContinue) { 'py' } else { 'python' }
if ((Test-Path (Join-Path $projectRoot 'media.lock')) -and (Get-Command $python -ErrorAction SilentlyContinue)) {
    & $python (Join-Path $projectRoot 'scripts/media.py') has game
    if ($LASTEXITCODE -ne 0) { throw "The game's pictures and models are not all here. Run .\scripts\setup.ps1 first." }
}
if ($Renderer -eq 'compatibility' -and $GpuIndex -ge 0) {
    throw 'Compatibility uses Windows Graphics preferences to select a GPU. Use -Renderer mobile -GpuIndex N for explicit adapter selection.'
}
if (($Renderer -eq 'compatibility' -and $Driver -notin @('auto','opengl3')) -or ($Renderer -ne 'compatibility' -and $Driver -eq 'opengl3')) {
    throw 'The selected renderer and graphics driver are incompatible.'
}
$engine = (Get-Command $Godot -ErrorAction Stop).Source
# Prefer the console companion so imports and errors are collected consistently.
if ($engine.EndsWith('.exe') -and !$engine.EndsWith('_console.exe')) {
    $console = $engine.Substring(0,$engine.Length-4) + '_console.exe'
    if (Test-Path $console) { $engine = $console }
}
$renderArgs = @('--rendering-method',$(if ($Renderer -eq 'compatibility') { 'gl_compatibility' } else { $Renderer }))
if ($Driver -ne 'auto') { $renderArgs += @('--rendering-driver',$Driver) }
elseif ($Renderer -eq 'compatibility') { $renderArgs += @('--rendering-driver','opengl3') }
if ($GpuIndex -ge 0) { $renderArgs += @('--gpu-index',[string]$GpuIndex) }
$cache = Join-Path $projectRoot '.cache'
New-Item -ItemType Directory -Force -Path $cache | Out-Null
try {
    $env:ROOTWARD_SANDBOX_RUNTIME = $runtimeRoot
    & $engine --headless --editor --path $projectRoot --import --quit *> (Join-Path $cache 'import-windows.log')
    if ($LASTEXITCODE -ne 0) { throw "Godot import failed; see $cache\import-windows.log" }
    Write-Host "Rootward: renderer=$Renderer. The engine prints the actual adapter below."
    & $engine --path $projectRoot @renderArgs @GodotArgs
    $gameExit = $LASTEXITCODE
} finally { $env:ROOTWARD_SANDBOX_RUNTIME = $previousRuntime }
exit $gameExit
