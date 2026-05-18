# Run TravelPick Java backend JUnit E2E tests.
$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$lib = Join-Path $root "lib"
$classes = Join-Path $root "target\classes"
$testClasses = Join-Path $root "target\test-classes"

New-Item -ItemType Directory -Force -Path $lib, $classes, $testClasses | Out-Null

# Download JUnit jars if they do not exist
$junitJars = @(
    @{ Uri = "https://repo1.maven.org/maven2/org/junit/jupiter/junit-jupiter-api/5.10.2/junit-jupiter-api-5.10.2.jar"; Name = "junit-jupiter-api-5.10.2.jar" },
    @{ Uri = "https://repo1.maven.org/maven2/org/apiguardian/apiguardian-api/1.1.2/apiguardian-api-1.1.2.jar"; Name = "apiguardian-api-1.1.2.jar" },
    @{ Uri = "https://repo1.maven.org/maven2/org/opentest4j/opentest4j/1.3.0/opentest4j-1.3.0.jar"; Name = "opentest4j-1.3.0.jar" },
    @{ Uri = "https://repo1.maven.org/maven2/org/junit/platform/junit-platform-commons/1.10.2/junit-platform-commons-1.10.2.jar"; Name = "junit-platform-commons-1.10.2.jar" }
)

foreach ($jar in $junitJars) {
    $out = Join-Path $lib $jar.Name
    if (-not (Test-Path $out)) {
        Write-Host "Downloading $($jar.Name)..."
        Invoke-WebRequest -Uri $jar.Uri -OutFile $out
    }
}

# Compile main sources
if (-not (Test-Path $classes)) {
    Write-Host "Classes not found. Running build.ps1 first..."
    & (Join-Path $root "build.ps1")
}

# Collect classpath
$cp = (Get-ChildItem $lib *.jar | ForEach-Object { $_.FullName }) -join ';'
$testCp = "$testClasses;$classes;$cp"

# Compile test sources
Write-Host "Compiling tests..."
$testSources = Get-ChildItem -Path (Join-Path $root "src/test/java") -Filter *.java -Recurse | ForEach-Object { $_.FullName }
javac -encoding UTF-8 -d $testClasses -cp $testCp $testSources

# Run TestRunner
Write-Host "Running E2E ENE-TO-END JUnit Tests..."
java -cp $testCp com.travelpick.TestRunner
