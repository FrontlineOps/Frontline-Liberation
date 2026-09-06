#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$FileBankPath,
    [switch]$OpenOutput
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repoRoot = Split-Path -Parent $PSScriptRoot
$cacheRoot = Join-Path $repoRoot '.build'
$outputRoot = Join-Path $repoRoot 'build'
$stageRoot = Join-Path $cacheRoot ('staging-' + [Guid]::NewGuid().ToString('N'))
$previousRoot = Join-Path $cacheRoot 'previous'
$buildLock = $null

function Get-Sha256 {
    param([string]$Path)

    $stream = [IO.File]::OpenRead($Path)
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        return [BitConverter]::ToString($algorithm.ComputeHash($stream)).Replace('-', '')
    } finally {
        $stream.Dispose()
        $algorithm.Dispose()
    }
}

function Assert-LocalTree {
    param([string]$Path)

    $fullPath = [IO.Path]::GetFullPath($Path)
    if (!$fullPath.StartsWith($repoRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw "Path is outside this repository: $fullPath"
    }
    $cursor = $fullPath
    while ($cursor -ne $repoRoot) {
        if (Test-Path -LiteralPath $cursor) {
            $item = Get-Item -LiteralPath $cursor -Force
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "Build paths must not be links or junctions: $cursor"
            }
        }
        $cursor = Split-Path -Parent $cursor
    }
    if (Test-Path -LiteralPath $fullPath -PathType Container) {
        $links = @(Get-ChildItem -LiteralPath $fullPath -Force -Recurse |
            Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint })
        if ($links.Count) { throw "Build tree contains a link or junction: $fullPath" }
    }
}

function Find-FileBank {
    if ($FileBankPath) {
        if (!(Test-Path -LiteralPath $FileBankPath -PathType Leaf)) {
            throw "FileBank was not found at $FileBankPath"
        }
        return (Resolve-Path -LiteralPath $FileBankPath).Path
    }
    $command = Get-Command 'FileBank.exe' -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }

    $libraries = [Collections.Generic.List[string]]::new()
    foreach ($registryPath in @('HKCU:\Software\Valve\Steam', 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam', 'HKLM:\SOFTWARE\Valve\Steam')) {
        $settings = Get-ItemProperty -LiteralPath $registryPath -ErrorAction SilentlyContinue
        if (!$settings) { continue }
        foreach ($property in @('SteamPath', 'InstallPath')) {
            if ($settings.PSObject.Properties[$property] -and $settings.$property) {
                $libraries.Add($settings.$property)
            }
        }
    }
    if (${env:ProgramFiles(x86)}) { $libraries.Add((Join-Path ${env:ProgramFiles(x86)} 'Steam')) }
    foreach ($steamRoot in @($libraries.ToArray() | Select-Object -Unique)) {
        $libraryFile = Join-Path $steamRoot 'steamapps\libraryfolders.vdf'
        if (!(Test-Path -LiteralPath $libraryFile -PathType Leaf)) { continue }
        $matches = [regex]::Matches([IO.File]::ReadAllText($libraryFile), '"(?:path|[0-9]+)"\s+"([^"]+)"')
        foreach ($match in $matches) {
            $libraryPath = $match.Groups[1].Value.Replace('\\', '\')
            if ([IO.Path]::IsPathRooted($libraryPath)) { $libraries.Add($libraryPath) }
        }
    }
    foreach ($library in @($libraries.ToArray() | Select-Object -Unique)) {
        $candidate = Join-Path $library 'steamapps\common\Arma 3 Tools\FileBank\FileBank.exe'
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    }
    throw 'Install Arma 3 Tools from Steam > Library > Tools, then run this build again. FileBank.exe is required.'
}

function Copy-MissionFiles {
    param([string]$Source, [string]$Destination)

    Assert-LocalTree $Source
    foreach ($file in Get-ChildItem -LiteralPath $Source -File -Recurse -Force) {
        $relative = $file.FullName.Substring($Source.Length + 1)
        if ($relative -match '(^|\\)\.' -or $relative -match '(?i)\.(pbo|bisign|bikey|biprivatekey|rpt|log|bak|tmp|swp)$' -or $file.Name -eq 'Thumbs.db') {
            continue
        }
        $target = Join-Path $Destination $relative
        [IO.Directory]::CreateDirectory((Split-Path -Parent $target)) | Out-Null
        if (Test-Path -LiteralPath $target) { (Get-Item -LiteralPath $target).IsReadOnly = $false }
        [IO.File]::Copy($file.FullName, $target, $true)
        (Get-Item -LiteralPath $target).IsReadOnly = $false
    }
}

try {
    Assert-LocalTree $cacheRoot
    Assert-LocalTree $outputRoot
    [IO.Directory]::CreateDirectory($cacheRoot) | Out-Null
    try {
        $buildLock = [IO.File]::Open((Join-Path $cacheRoot 'build.lock'), 'OpenOrCreate', 'ReadWrite', 'None')
    } catch {
        throw 'Another mission build is running, or the build cache is not writable.'
    }

    $packer = Find-FileBank
    $frameworkRoot = Join-Path $repoRoot 'MissionFramework'
    $basesRoot = Join-Path $repoRoot 'Missionbasefiles'
    Assert-LocalTree $basesRoot
    $bases = @(Get-ChildItem -LiteralPath $basesRoot -Directory | Sort-Object Name)
    if (!$bases.Count) { throw 'Missionbasefiles contains no terrain folders.' }
    [IO.Directory]::CreateDirectory($stageRoot) | Out-Null
    $manifest = [ordered]@{ format = 1; builtAt = [DateTime]::UtcNow.ToString('o'); missions = @() }
    Write-Host "Using $packer"

    foreach ($base in $bases) {
        if ($base.Name -notmatch '^[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+$') {
            throw "Terrain folder must be named mission.world: $($base.Name)"
        }
        if (!(Test-Path -LiteralPath (Join-Path $base.FullName 'mission.sqm') -PathType Leaf)) {
            throw "Missing mission.sqm in $($base.FullName)"
        }
        $missionRoot = Join-Path $stageRoot $base.Name
        Copy-MissionFiles $frameworkRoot $missionRoot
        Copy-MissionFiles $base.FullName $missionRoot
        Copy-Item -LiteralPath (Join-Path $repoRoot 'LICENSE') -Destination $missionRoot
        foreach ($required in @('mission.sqm', 'init.sqf', 'description.ext', 'CfgFunctions.hpp', 'kp_liberation_config.sqf', 'stringtable.xml')) {
            if (!(Test-Path -LiteralPath (Join-Path $missionRoot $required) -PathType Leaf)) {
                throw "Missing required mission file: $required"
            }
        }

        Write-Host "Packing $($base.Name)..."
        # FileBank otherwise embeds the absolute source path as an addon prefix.
        $packLog = & $packer '-property' 'prefix=' '-dst' $stageRoot $missionRoot 2>&1
        $packExitCode = $LASTEXITCODE
        $pbo = Join-Path $stageRoot ($base.Name + '.pbo')
        if ($packExitCode -ne 0 -or !(Test-Path -LiteralPath $pbo) -or (Get-Item -LiteralPath $pbo).Length -eq 0) {
            throw "FileBank failed for $($base.Name) (exit $packExitCode).`n$($packLog -join "`n")"
        }
        $manifest.missions += [ordered]@{
            name = $base.Name
            missionSha256 = Get-Sha256 (Join-Path $missionRoot 'mission.sqm')
            pboSha256 = Get-Sha256 $pbo
            fileCount = @(Get-ChildItem -LiteralPath $missionRoot -File -Recurse).Count
        }
    }

    $marker = '.frontline-build.json'
    $manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $stageRoot $marker) -Encoding UTF8
    # Only replace folders previously created by this builder. Keep the last successful build.
    foreach ($managedRoot in @($outputRoot, $previousRoot)) {
        Assert-LocalTree $managedRoot
        if ((Test-Path -LiteralPath $managedRoot) -and !(Test-Path -LiteralPath (Join-Path $managedRoot $marker) -PathType Leaf)) {
            throw "Refusing to replace an unrecognized output folder: $managedRoot"
        }
    }
    if (Test-Path -LiteralPath $previousRoot) { Remove-Item -LiteralPath $previousRoot -Recurse -Force }
    if (Test-Path -LiteralPath $outputRoot) { Move-Item -LiteralPath $outputRoot -Destination $previousRoot }
    try {
        Move-Item -LiteralPath $stageRoot -Destination $outputRoot
    } catch {
        if (!(Test-Path -LiteralPath $outputRoot) -and (Test-Path -LiteralPath $previousRoot)) {
            Move-Item -LiteralPath $previousRoot -Destination $outputRoot
        }
        throw
    }
    Write-Host "Build complete: $outputRoot" -ForegroundColor Green
    if ($OpenOutput) { Start-Process explorer.exe -ArgumentList ('"' + $outputRoot + '"') }
} catch {
    Write-Host "BUILD FAILED: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    if (Test-Path -LiteralPath $stageRoot) {
        Assert-LocalTree $stageRoot
        Remove-Item -LiteralPath $stageRoot -Recurse -Force
    }
    if ($buildLock) { $buildLock.Dispose() }
}
