# Build TravelPick Java backend without requiring Maven on PATH.
$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$lib = Join-Path $root "lib"
$classes = Join-Path $root "target\classes"
$jarOut = Join-Path $root "target/travelpick-backend.jar"

New-Item -ItemType Directory -Force -Path $lib, $classes | Out-Null

$base = "https://repo1.maven.org/maven2/com/fasterxml/jackson/core"
$jars = @(
    "jackson-annotations/2.17.1/jackson-annotations-2.17.1.jar",
    "jackson-core/2.17.1/jackson-core-2.17.1.jar",
    "jackson-databind/2.17.1/jackson-databind-2.17.1.jar"
)
foreach ($relative in $jars) {
    $name = Split-Path $relative -Leaf
    $out = Join-Path $lib $name
    if (-not (Test-Path $out)) {
        Invoke-WebRequest -Uri "$base/$relative" -OutFile $out
    }
}

$cp = (Get-ChildItem $lib *.jar | ForEach-Object { $_.FullName }) -join ';'
$sources = Get-ChildItem -Path (Join-Path $root "src/main/java") -Filter *.java -Recurse | ForEach-Object { $_.FullName }
javac -encoding UTF-8 -d $classes -cp $cp $sources

$manifest = Join-Path $root "target/MANIFEST.MF"
$classpathEntries = Get-ChildItem $lib -Filter *.jar | ForEach-Object { "lib/$($_.Name)" }
$classpathLine = ($classpathEntries -join " ")
@"
Manifest-Version: 1.0
Main-Class: com.travelpick.Main
Class-Path: $classpathLine

"@ | Set-Content -Path $manifest -Encoding ASCII

Copy-Item $jarOut "$jarOut.bak" -ErrorAction SilentlyContinue
jar cfm $jarOut $manifest -C $classes .
Write-Host "Built $jarOut"
Write-Host "Run: .\run.ps1   (recommended)"
Write-Host "Or:  java -jar $jarOut   (requires lib/*.jar next to the jar)"
