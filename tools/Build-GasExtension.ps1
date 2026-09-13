[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceRoot = Join-Path $repoRoot 'extensions\frontline_gas'
$outputRoot = Join-Path $repoRoot '.build\gas-extension'
$vswherePath = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
if (-not (Test-Path -LiteralPath $vswherePath)) {
    throw 'Visual Studio C++ Build Tools are required (vswhere.exe not found).'
}
$installation = & $vswherePath -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if ($LASTEXITCODE -ne 0 -or -not $installation) {
    throw 'No Visual Studio installation with x64 C++ tools was found.'
}
$vcvarsPath = Join-Path $installation 'VC\Auxiliary\Build\vcvars64.bat'
if (-not (Test-Path -LiteralPath $vcvarsPath)) {
    throw 'vcvars64.bat was not found.'
}
New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null
$batchPath = Join-Path $outputRoot 'compile.cmd'
$lines = @(
    '@echo off'
    ('call "{0}" >nul' -f $vcvarsPath)
    'if errorlevel 1 exit /b 1'
    ('cd /d "{0}"' -f $outputRoot)
    ('cl /nologo /std:c++17 /EHsc /O2 /W4 /WX /MT /LD "{0}\gas.cpp" "{0}\extension.cpp" /Fe:frontline_gas_x64.dll /link /INCREMENTAL:NO' -f $sourceRoot)
    'if errorlevel 1 exit /b 1'
    ('cl /nologo /std:c++17 /EHsc /O2 /W4 /WX /MT "{0}\gas.cpp" "{0}\tests.cpp" /Fe:gas-tests.exe /link /INCREMENTAL:NO' -f $sourceRoot)
    'if errorlevel 1 exit /b 1'
    'gas-tests.exe > native-tests.txt'
    'exit /b %errorlevel%'
)
[IO.File]::WriteAllLines($batchPath, $lines, [Text.Encoding]::ASCII)
$process = Start-Process -FilePath $env:ComSpec -ArgumentList @('/d', '/c', ('"{0}"' -f $batchPath)) -WorkingDirectory $outputRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $outputRoot 'build.log') -RedirectStandardError (Join-Path $outputRoot 'build-errors.log')
# Wait for the compiler batch, not unrelated lifetime of VS telemetry children.
$process.WaitForExit()
Get-Content -LiteralPath (Join-Path $outputRoot 'build.log')
Get-Content -LiteralPath (Join-Path $outputRoot 'build-errors.log')
if ($process.ExitCode -ne 0) {
    throw "Native gas build/tests failed with exit code $($process.ExitCode)."
}
Get-Content -LiteralPath (Join-Path $outputRoot 'native-tests.txt')
$packageRoot = Join-Path $outputRoot '@FrontlineGas'
New-Item -ItemType Directory -Path $packageRoot -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $outputRoot 'frontline_gas_x64.dll') -Destination $packageRoot -Force
Copy-Item -LiteralPath (Join-Path $sourceRoot 'README.md') -Destination $packageRoot -Force
Compress-Archive -LiteralPath $packageRoot -DestinationPath (Join-Path $outputRoot 'FrontlineGas-windows-x64.zip') -Force
Get-FileHash -LiteralPath (Join-Path $outputRoot 'frontline_gas_x64.dll') -Algorithm SHA256
