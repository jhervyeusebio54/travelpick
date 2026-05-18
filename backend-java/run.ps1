# Run TravelPick Java backend with Jackson on the classpath.
$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$classes = Join-Path $root "target\classes"
$lib = Join-Path $root "lib"

if (-not (Test-Path $classes)) {
    Write-Host "Classes not found. Run build.ps1 first."
    & (Join-Path $root "build.ps1")
}

$jarCp = (Get-ChildItem $lib -Filter *.jar | ForEach-Object { $_.FullName }) -join ';'
$cp = "$classes;$jarCp"

Write-Host "Starting TravelPick backend on http://127.0.0.1:8000"
java -cp $cp com.travelpick.Main
