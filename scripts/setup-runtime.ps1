[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT -or ![Environment]::Is64BitProcess -or $env:PROCESSOR_ARCHITECTURE -ne 'AMD64') {
    throw 'This bootstrap needs 64-bit Windows PowerShell. Linux uses scripts/setup-runtime.sh.'
}
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$runtimeRoot = if ($env:ROOTWARD_SANDBOX_RUNTIME) { $env:ROOTWARD_SANDBOX_RUNTIME } else { Join-Path $projectRoot 'sandbox/runtime-windows' }
$wasmtime = Join-Path $runtimeRoot 'bin/wasmtime.exe'
$compiled = Join-Path $runtimeRoot 'python/python.cwasm'
if ((Test-Path $wasmtime) -and (Test-Path $compiled) -and (Test-Path (Join-Path $runtimeRoot 'VERSIONS'))) {
    Write-Host "Windows runtime already present: $runtimeRoot"; exit 0
}
$downloads = Join-Path $projectRoot '.cache/runtime-downloads'
New-Item -ItemType Directory -Force -Path $downloads,(Join-Path $runtimeRoot 'bin'),(Join-Path $runtimeRoot 'python') | Out-Null
New-Item -ItemType File -Force -Path (Join-Path $runtimeRoot '.gdignore') | Out-Null
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
function Fetch-Checked([string]$Url,[string]$Sha,[string]$Path) {
    if ((Test-Path $Path) -and (Get-FileHash -Algorithm SHA256 $Path).Hash.ToLowerInvariant() -eq $Sha) { return }
    Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile "$Path.part"
    if ((Get-FileHash -Algorithm SHA256 "$Path.part").Hash.ToLowerInvariant() -ne $Sha) { throw "Archive checksum mismatch: $Url" }
    Move-Item -Force "$Path.part" $Path
}
$wasmtimeZip = Join-Path $downloads 'wasmtime-v49.0.0-x86_64-windows.zip'
$pythonZip = Join-Path $downloads 'python.zip'
# Digests are pinned to the official release assets, not downloaded dynamically at setup time.
Fetch-Checked 'https://github.com/bytecodealliance/wasmtime/releases/download/v49.0.0/wasmtime-v49.0.0-x86_64-windows.zip' '7f2a583694aac3dfeecc43ce51248155e72eaa695733d803c6923ef27103681a' $wasmtimeZip
Fetch-Checked 'https://github.com/brettcannon/cpython-wasi-build/releases/download/v3.14.7/python-3.14.7-wasi_sdk-24.zip' '2e064d3fb8172471d39d741348efa722349c40b96301f69968dff714999c584b' $pythonZip
$unpacked = Join-Path $downloads 'wasmtime-windows'
Expand-Archive -Force $wasmtimeZip $unpacked
$executable = Get-ChildItem $unpacked -Filter 'wasmtime.exe' -Recurse | Select-Object -First 1
if (!$executable) { throw 'The verified Wasmtime archive contains no Windows executable.' }
Copy-Item $executable.FullName $wasmtime
Expand-Archive -Force $pythonZip (Join-Path $runtimeRoot 'python')
& $wasmtime compile -W epoch-interruption=y (Join-Path $runtimeRoot 'python/python.wasm') -o $compiled
if ($LASTEXITCODE -ne 0) { throw 'Wasmtime could not compile the portable Python module for Windows.' }
# Keep the shared standard library read-only to guest programs, as on Linux.
$stdlib = Join-Path $runtimeRoot 'python/lib'
$identity = [Security.Principal.WindowsIdentity]::GetCurrent().Name
$acl = Get-Acl $stdlib
$acl.SetAccessRuleProtection($true,$false)
$inherit = [Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [Security.AccessControl.InheritanceFlags]::ObjectInherit
$rule = [Security.AccessControl.FileSystemAccessRule]::new($identity,[Security.AccessControl.FileSystemRights]::ReadAndExecute,$inherit,[Security.AccessControl.PropagationFlags]::None,[Security.AccessControl.AccessControlType]::Allow)
$acl.SetAccessRule($rule)
Set-Acl -Path $stdlib -AclObject $acl
Set-Content -Encoding Ascii -Path (Join-Path $runtimeRoot 'VERSIONS') -Value 'windows-x86_64; wasmtime v49.0.0; cpython 3.14.7'
Write-Host "Installed Windows Python/WASI runtime: $runtimeRoot"
