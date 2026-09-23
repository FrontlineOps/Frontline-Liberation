[CmdletBinding()]
param(
    # Zig cross-compiler for the Linux server library; skipped when absent.
    [string]$Zig
)

$ErrorActionPreference = 'Stop'
# $PSScriptRoot is empty in param() defaults under Windows PowerShell -File.
$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not $Zig) {
    $Zig = Join-Path $repoRoot '.agent-notes\linux-gas-2026-09-14\toolchain\zig-x86_64-windows-0.14.1\zig.exe'
}
$sourceRoot = Join-Path $repoRoot 'extensions\frontline_path'
$outputRoot = Join-Path $repoRoot '.build\path-extension'
$vswherePath = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
if (-not (Test-Path -LiteralPath $vswherePath)) {
    throw 'Visual Studio C++ Build Tools are required (vswhere.exe not found).'
}
$installation = & $vswherePath -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if ($LASTEXITCODE -ne 0 -or -not $installation) {
    throw 'No Visual Studio installation with x64 C++ tools was found.'
}
$vcvarsPath = Join-Path $installation 'VC\Auxiliary\Build\vcvars64.bat'
New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null
$batchPath = Join-Path $outputRoot 'compile.cmd'
$lines = @(
    '@echo off'
    # vcvars64.bat looks for vswhere.exe on PATH.
    ('set "PATH={0};%PATH%"' -f (Split-Path -Parent $vswherePath))
    ('call "{0}" >nul' -f $vcvarsPath)
    'if errorlevel 1 exit /b 1'
    ('cd /d "{0}"' -f $outputRoot)
    ('cl /nologo /std:c++17 /EHsc /O2 /W4 /WX /MT /LD "{0}\path.cpp" "{0}\extension.cpp" /Fe:frontline_path_v1_x64.dll /link /INCREMENTAL:NO' -f $sourceRoot)
    'if errorlevel 1 exit /b 1'
    ('cl /nologo /std:c++17 /EHsc /O2 /W4 /WX /MT "{0}\path.cpp" "{0}\extension.cpp" "{0}\tests.cpp" /Fe:path-tests.exe /link /INCREMENTAL:NO' -f $sourceRoot)
    'if errorlevel 1 exit /b 1'
    '.\path-tests.exe > native-tests.txt'
    'exit /b %errorlevel%'
)
[IO.File]::WriteAllLines($batchPath, $lines, [Text.Encoding]::ASCII)
$process = Start-Process -FilePath $env:ComSpec -ArgumentList @('/d', '/c', ('"{0}"' -f $batchPath)) -WorkingDirectory $outputRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $outputRoot 'build.log') -RedirectStandardError (Join-Path $outputRoot 'build-errors.log')
$null = $process.Handle # caches the handle so ExitCode is available after exit
$process.WaitForExit()
Get-Content -LiteralPath (Join-Path $outputRoot 'build.log')
Get-Content -LiteralPath (Join-Path $outputRoot 'build-errors.log')
Get-Content -LiteralPath (Join-Path $outputRoot 'native-tests.txt') -ErrorAction SilentlyContinue
if ($process.ExitCode -ne 0) {
    throw "Native path build/tests failed with exit code $($process.ExitCode)."
}

$packageRoot = Join-Path $outputRoot '@FrontlinePath'
New-Item -ItemType Directory -Path $packageRoot -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $outputRoot 'frontline_path_v1_x64.dll') -Destination $packageRoot -Force
Copy-Item -LiteralPath (Join-Path $repoRoot 'LICENSE') -Destination $packageRoot -Force

if (Test-Path -LiteralPath $Zig) {
    # Server-side Linux library: glibc 2.17 baseline, only the Arma entry points exported.
    $exports = Join-Path $outputRoot 'exports.map'
    [IO.File]::WriteAllText($exports, "{ global: RVExtension; RVExtensionArgs; RVExtensionVersion; local: *; };`n")
    & $Zig c++ -target x86_64-linux-gnu.2.17 -mcpu=baseline -std=c++17 -O2 -Wall -Wextra -Werror -pthread -shared -s -fPIC `
        -fvisibility=hidden -fvisibility-inlines-hidden "-Wl,--version-script=$exports" '-Wl,-z,defs' `
        (Join-Path $sourceRoot 'path.cpp') (Join-Path $sourceRoot 'extension.cpp') -o (Join-Path $packageRoot 'frontline_path_v1_x64.so')
    if ($LASTEXITCODE -ne 0) {
        throw 'Linux cross-compile failed.'
    }
    & $Zig c++ -target x86_64-linux-gnu.2.17 -mcpu=baseline -std=c++17 -O2 -Wall -Wextra -Werror -pthread `
        (Join-Path $sourceRoot 'path.cpp') (Join-Path $sourceRoot 'extension.cpp') (Join-Path $sourceRoot 'tests.cpp') -o (Join-Path $outputRoot 'path-tests-linux')
    if ($LASTEXITCODE -ne 0) {
        throw 'Linux test cross-compile failed.'
    }
} else {
    Write-Warning "Zig not found at $Zig; Linux library not built."
}

$packageFiles = Get-ChildItem -LiteralPath $packageRoot -File | ForEach-Object FullName
Compress-Archive -LiteralPath $packageFiles -DestinationPath (Join-Path $outputRoot 'FrontlinePath-x64.zip') -Force
Get-ChildItem -LiteralPath $packageRoot -File | Get-FileHash -Algorithm SHA256 | Format-Table -AutoSize Hash, Path
