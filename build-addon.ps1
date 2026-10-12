# Builds the add-on zip: compiles every script that differs from Mantella 0.13.1 and packages it for Nexus / MO2.
# Usage: powershell -ExecutionPolicy Bypass -File .\build-addon.ps1 -Version 1.0.0
param(
    [Parameter(Mandatory = $true)][string]$Version,
    [string]$ModName = "Mantella-dreaminalife's addon",
    [string]$GamePath = "D:\SteamLibrary\steamapps\common\Skyrim Special Edition",
    [string]$DepsPath = "D:\Modding\PapyrusDeps"
)
$ErrorActionPreference = "Stop"

# Commit matching the scripts shipped in Mantella 0.13.1 on Nexus
$BaseCommit = "db034dd"

$Repo = $PSScriptRoot
$Compiler = Join-Path $GamePath "Papyrus Compiler\PapyrusCompiler.exe"
$Imports = @(
    "$Repo\Scripts\Source",
    "$DepsPath\SkyUI\Scripts\Source",
    "$DepsPath\UIExtensions\scripts\source",
    "$GamePath\Data\Scripts\Source", # SKSE, must come before vanilla
    "$GamePath\Data\Source\Scripts"  # vanilla
) -join ";"

Push-Location $Repo
try {
    if (git status --porcelain -- Scripts/Source) {
        Write-Warning "Scripts/Source has uncommitted changes. Commit before building a release."
    }

    # Changed or added since 0.13.1 (including uncommitted and untracked files)
    $changed = @(git diff --name-only --diff-filter=AMR $BaseCommit -- "Scripts/Source/*.psc") +
               @(git ls-files --others --exclude-standard -- "Scripts/Source/*.psc")
    $scripts = $changed | Where-Object { $_ } | ForEach-Object { [IO.Path]::GetFileNameWithoutExtension($_) } | Sort-Object -Unique
    if (-not $scripts) { throw "No scripts differ from $BaseCommit." }

    $Stage = Join-Path $Repo "build\$ModName-$Version"
    $Zip = Join-Path $Repo "build\$ModName-$Version.zip"
    if (Test-Path $Stage) { Remove-Item $Stage -Recurse -Force }
    if (Test-Path $Zip) { Remove-Item $Zip -Force }
    New-Item -ItemType Directory -Force "$Stage\Scripts\Source" | Out-Null

    foreach ($s in $scripts) {
        Write-Host "Compiling $s"
        & $Compiler "$s.psc" -f="TESV_Papyrus_Flags.flg" -i="$Imports" -o="$Stage\Scripts" -q
        if ($LASTEXITCODE -ne 0) { throw "Failed to compile $s" }
        Copy-Item "$Repo\Scripts\Source\$s.psc" "$Stage\Scripts\Source\"
    }
    Copy-Item "$Repo\LICENSE" "$Stage\$ModName - LICENSE.txt"

    # Add entries one by one: CreateFromDirectory writes backslash paths under Windows PowerShell, which some mod managers mishandle
    Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::Open($Zip, [IO.Compression.ZipArchiveMode]::Create)
    try {
        Get-ChildItem $Stage -Recurse -File | ForEach-Object {
            $entry = $_.FullName.Substring($Stage.Length + 1).Replace("\", "/")
            [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $_.FullName, $entry) | Out-Null
        }
    }
    finally {
        $archive.Dispose()
    }
    Write-Host "Built $Zip with $($scripts.Count) scripts: $($scripts -join ', ')"
}
finally {
    Pop-Location
}
