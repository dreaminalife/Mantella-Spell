# Compiles every script in Scripts/Source into a temporary folder, to find compile errors without building the add-on.
# Nothing is written to the game, the build folder or Scripts. Uses the same compiler and imports as build-addon.ps1.
# Usage: powershell -ExecutionPolicy Bypass -File .\check-scripts.ps1
param(
    [string]$GamePath = "D:\SteamLibrary\steamapps\common\Skyrim Special Edition",
    [string]$DepsPath = "D:\Modding\PapyrusDeps"
)
$ErrorActionPreference = "Stop"

$Source = Join-Path $PSScriptRoot "Scripts\Source"
$Compiler = Join-Path $GamePath "Papyrus Compiler\PapyrusCompiler.exe"
$Imports = @(
    $Source,
    "$DepsPath\SkyUI\Scripts\Source",
    "$DepsPath\UIExtensions\scripts\source",
    "$DepsPath\PapyrusUtil\Scripts\Source",
    "$GamePath\Data\Scripts\Source", # SKSE, must come before vanilla
    "$GamePath\Data\Source\Scripts"  # vanilla
) -join ";"
$Output = Join-Path ([IO.Path]::GetTempPath()) "mantella-check-scripts"
if (Test-Path $Output) { Remove-Item $Output -Recurse -Force }
New-Item -ItemType Directory -Force $Output | Out-Null

Push-Location $Source
try {
    # A script that uses a broken one fails too, so one error can be listed several times
    & $Compiler $Source -all -f="TESV_Papyrus_Flags.flg" -i="$Imports" -o="$Output" -q
    $failed = $LASTEXITCODE -ne 0
}
finally {
    Pop-Location
    Remove-Item $Output -Recurse -Force -ErrorAction SilentlyContinue
}
if ($failed) {
    Write-Host "Some scripts don't compile. See the errors above."
    exit 1
}
Write-Host "All scripts compile."
