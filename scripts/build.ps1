# Build AmoreClearGlass.jar: minimal JavaPlugin + asset pack (Server/, Common/, manifest.json).
# Requires: HytaleServer.jar next to PebbleHostServerRoot (or PEBBLE_SERVER_ROOT), JDK 25 (see tools/jdk25).
$ErrorActionPreference = "Stop"
$repoRoot = Split-Path $PSScriptRoot -Parent

function Get-ServerRoot([string]$root) {
  $custom = $env:PEBBLE_SERVER_ROOT
  if (-not [string]::IsNullOrWhiteSpace($custom) -and (Test-Path (Join-Path $custom "HytaleServer.jar"))) {
    return $custom
  }
  $parent = Split-Path $root -Parent
  $candidates = @(
    (Join-Path $parent "PebbleHostServerRoot"),
    (Join-Path $parent "PebbleHotServerRoot"),
    $parent,
    $root
  )
  foreach ($d in $candidates) {
    if ([string]::IsNullOrWhiteSpace($d)) { continue }
    if (Test-Path (Join-Path $d "HytaleServer.jar")) { return $d }
  }
  throw "Could not find HytaleServer.jar. Set PEBBLE_SERVER_ROOT to the folder that contains it."
}

$serverRoot = Get-ServerRoot $repoRoot
$sourcesDir = Join-Path $repoRoot "src\main\java"
$outClasses = Join-Path $repoRoot "build\classes"
$workDir = Join-Path $repoRoot "build\pack"
$assetsDir = Join-Path $repoRoot "jar-assets"
$jdkHome = Get-ChildItem (Join-Path $repoRoot "tools\jdk25") -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $jdkHome) {
  $jdkHome = Get-ChildItem (Join-Path (Split-Path $repoRoot -Parent) "Hytale_JossDoubleJump\tools\jdk25") -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
}
if (-not $jdkHome) { throw "Missing JDK 25. Add tools\jdk25\<jdk> (gitignored) or use Hytale_JossDoubleJump\tools\jdk25." }
$javac = Join-Path $jdkHome.FullName "bin\javac.exe"
$jar = Join-Path $jdkHome.FullName "bin\jar.exe"
$hy = Join-Path $serverRoot "HytaleServer.jar"

if (-not (Test-Path $hy)) { throw "Missing HytaleServer.jar at $hy" }
if (-not (Test-Path $sourcesDir)) { throw "Missing sources: $sourcesDir" }

Remove-Item -Recurse -Force $outClasses, $workDir -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $outClasses | Out-Null
New-Item -ItemType Directory -Force -Path $workDir | Out-Null

$javaFiles = @(Get-ChildItem -Path $sourcesDir -Recurse -Filter "*.java" | ForEach-Object { $_.FullName })
& $javac -encoding UTF-8 -cp $hy -d $outClasses @javaFiles
if ($LASTEXITCODE -ne 0) { throw "javac failed ($LASTEXITCODE)." }

Get-ChildItem -Path $outClasses -Recurse -File | ForEach-Object {
  $rel = $_.FullName.Substring($outClasses.Length + 1)
  $dest = Join-Path $workDir $rel
  $destParent = Split-Path $dest -Parent
  if (-not (Test-Path $destParent)) {
    New-Item -ItemType Directory -Force -Path $destParent | Out-Null
  }
  Copy-Item -Force $_.FullName $dest
}

Copy-Item -Force (Join-Path $assetsDir "manifest.json") $workDir
Copy-Item -Recurse -Force (Join-Path $assetsDir "Server") $workDir
Copy-Item -Recurse -Force (Join-Path $assetsDir "Common") $workDir
Copy-Item -Recurse -Force (Join-Path $assetsDir "META-INF") $workDir

$outJar = Join-Path $repoRoot "dist\AmoreClearGlass.jar"
New-Item -ItemType Directory -Force -Path (Split-Path $outJar -Parent) | Out-Null
if (Test-Path $outJar) { Remove-Item -Force $outJar }
Push-Location $workDir
& $jar cfm $outJar META-INF\MANIFEST.MF -C . .
Pop-Location
Write-Host "Built: $outJar"
