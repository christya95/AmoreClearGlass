# Generates all Amore glass pane textures (32x32).
#
# Clear: gradient rim + transparent center (production/diagnostic) — unchanged behavior.
# Stained: BINARY alpha only (Hytale block transparency behaves as a visibility mask):
#   - d >= 3: alpha 0 (see-through glass field)
#   - d = 0..2: alpha 255, stain-colored frame bands (color identity on lead/frame only)
#   No intermediate alpha in the pane — avoids frosted sheet / wrong blending.
#
# Usage (from repo root):
#   powershell -ExecutionPolicy Bypass -File scripts\generate-all-glass-pane-textures.ps1
#   powershell -ExecutionPolicy Bypass -File scripts\generate-all-glass-pane-textures.ps1 -Scope Stained -GreenOnly
#
param(
  [ValidateSet("All", "Clear", "Stained")]
  [string]$Scope = "All",
  [switch]$GreenOnly
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

function Write-Png32([System.Drawing.Bitmap]$bmp, [string]$dest) {
  $dir = Split-Path $dest -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $tmp = "$dest.tmp.png"
  $bmp.Save($tmp, [System.Drawing.Imaging.ImageFormat]::Png)
  if (Test-Path $dest) { Remove-Item -Force $dest }
  Move-Item -Force $tmp $dest
  Write-Host "Wrote $dest"
}

function Clamp-Byte([int]$v) {
  if ($v -lt 0) { return 0 }
  if ($v -gt 255) { return 255 }
  return $v
}

# Three frame bands (outer -> inner), opaque; t0 < t1 < t2 for depth read
function Get-StainedFrameRgb([int]$br, [int]$bg, [int]$bb, [int]$band) {
  # band 0 = outer edge, 1 = mid, 2 = inner (adjacent to glass)
  $t0 = 0.42; $t1 = 0.62; $t2 = 0.82
  $t = switch ($band) { 0 { $t0 } 1 { $t1 } 2 { $t2 } default { $t2 } }
  $r = Clamp-Byte ([int][Math]::Round(18 + ($br - 18) * $t))
  $g = Clamp-Byte ([int][Math]::Round(18 + ($bg - 18) * $t))
  $b = Clamp-Byte ([int][Math]::Round(20 + ($bb - 20) * $t))
  return @( $r, $g, $b )
}

function New-StainedGlassBitmapBinary([int]$w, [int]$h, [int]$baseR, [int]$baseG, [int]$baseB) {
  $fmt = [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
  $bmp = New-Object System.Drawing.Bitmap -ArgumentList @($w, $h, $fmt)
  $f0 = Get-StainedFrameRgb $baseR $baseG $baseB 0
  $f1 = Get-StainedFrameRgb $baseR $baseG $baseB 1
  $f2 = Get-StainedFrameRgb $baseR $baseG $baseB 2
  for ($y = 0; $y -lt $h; $y++) {
    for ($x = 0; $x -lt $w; $x++) {
      $dEdge = [int]([Math]::Min([Math]::Min($x, $y), [Math]::Min(($w - 1) - $x, ($h - 1) - $y)))
      if ($dEdge -ge 3) {
        $c = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)
      }
      elseif ($dEdge -eq 2) {
        $c = [System.Drawing.Color]::FromArgb(255, $f2[0], $f2[1], $f2[2])
      }
      elseif ($dEdge -eq 1) {
        $c = [System.Drawing.Color]::FromArgb(255, $f1[0], $f1[1], $f1[2])
      }
      else {
        $c = [System.Drawing.Color]::FromArgb(255, $f0[0], $f0[1], $f0[2])
      }
      $bmp.SetPixel($x, $y, $c)
    }
  }
  return $bmp
}

# Diagnostic: green-tinted binary frame (same mask as stained), for A/B tests
function New-StainedDiagnosticGreenBitmapBinary([int]$w, [int]$h) {
  return (New-StainedGlassBitmapBinary $w $h 48 120 72)
}

function New-ClearDiagnosticBitmap([int]$w, [int]$h) {
  $fmt = [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
  $bmp = New-Object System.Drawing.Bitmap -ArgumentList @($w, $h, $fmt)
  for ($y = 0; $y -lt $h; $y++) {
    for ($x = 0; $x -lt $w; $x++) {
      $dEdge = [int]([Math]::Min([Math]::Min($x, $y), [Math]::Min(($w - 1) - $x, ($h - 1) - $y)))
      if ($dEdge -ge 2) {
        $c = [System.Drawing.Color]::FromArgb(0, 12, 12, 12)
      }
      elseif ($dEdge -eq 1) {
        $c = [System.Drawing.Color]::FromArgb(245, 52, 52, 54)
      }
      else {
        $c = [System.Drawing.Color]::FromArgb(255, 42, 42, 44)
      }
      $bmp.SetPixel($x, $y, $c)
    }
  }
  return $bmp
}

function New-ClearProductionBitmap([int]$w, [int]$h) {
  $fmt = [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
  $bmp = New-Object System.Drawing.Bitmap -ArgumentList @($w, $h, $fmt)
  for ($y = 0; $y -lt $h; $y++) {
    for ($x = 0; $x -lt $w; $x++) {
      $dEdge = [int]([Math]::Min([Math]::Min($x, $y), [Math]::Min(($w - 1) - $x, ($h - 1) - $y)))
      if ($dEdge -ge 3) {
        $c = [System.Drawing.Color]::FromArgb(0, 10, 10, 11)
      }
      elseif ($dEdge -eq 2) {
        $c = [System.Drawing.Color]::FromArgb(28, 48, 48, 50)
      }
      elseif ($dEdge -eq 1) {
        $c = [System.Drawing.Color]::FromArgb(165, 44, 44, 46)
      }
      else {
        $c = [System.Drawing.Color]::FromArgb(235, 36, 36, 38)
      }
      $bmp.SetPixel($x, $y, $c)
    }
  }
  return $bmp
}

$repoRoot = Split-Path $PSScriptRoot -Parent
$w = 32
$h = 32
$bt = Join-Path $repoRoot "jar-assets\Common\BlockTextures"

$stainMap = [ordered]@{
  "Amore_Glass_Red"        = @(198, 58, 58)
  "Amore_Glass_Blue"       = @(52, 98, 218)
  "Amore_Glass_Black"      = @(42, 42, 48)
  "Amore_Glass_White"      = @(198, 198, 206)
  "Amore_Glass_Brown"      = @(132, 78, 48)
  "Amore_Glass_Green"      = @(48, 158, 68)
  "Amore_Glass_Lime"       = @(128, 208, 52)
  "Amore_Glass_Magenta"    = @(196, 58, 176)
  "Amore_Glass_Orange"     = @(232, 128, 48)
  "Amore_Glass_Purple"     = @(118, 58, 198)
  "Amore_Glass_Pink"       = @(222, 148, 188)
  "Amore_Glass_Cyan"       = @(48, 192, 208)
  "Amore_Glass_Gray"       = @(108, 112, 118)
  "Amore_Glass_Light_Gray" = @(178, 182, 186)
  "Amore_Glass_Light_Blue" = @(112, 168, 232)
  "Amore_Glass_Yellow"     = @(232, 216, 58)
  "Amore_Glass_Tinted"     = @(118, 98, 72)
}

if ($Scope -eq "All" -or $Scope -eq "Clear") {
  $b = New-ClearDiagnosticBitmap $w $h
  try {
    Write-Png32 $b (Join-Path $repoRoot "jar-assets\Common\Blocks\AmoreClearGlass\Amore_Clear_Glass_Diagnostic.png")
    Write-Png32 $b (Join-Path $bt "Amore_Clear_Glass_Diagnostic.png")
  }
  finally { $b.Dispose() }

  $b = New-ClearProductionBitmap $w $h
  try {
    Write-Png32 $b (Join-Path $repoRoot "jar-assets\Common\Blocks\AmoreClearGlass\Amore_Clear_Glass.png")
    Write-Png32 $b (Join-Path $bt "Amore_Clear_Glass.png")
  }
  finally { $b.Dispose() }
}

if ($Scope -eq "All" -or $Scope -eq "Stained") {
  foreach ($entry in $stainMap.GetEnumerator()) {
    $name = $entry.Key
    if ($GreenOnly -and $name -ne "Amore_Glass_Green") { continue }
    $rgb = $entry.Value
    $b = New-StainedGlassBitmapBinary $w $h $rgb[0] $rgb[1] $rgb[2]
    try {
      Write-Png32 $b (Join-Path $bt "$name.png")
    }
    finally { $b.Dispose() }
  }
  if (-not $GreenOnly) {
    $dbg = New-StainedDiagnosticGreenBitmapBinary $w $h
    try {
      Write-Png32 $dbg (Join-Path $bt "Amore_Glass_Diagnostic_GreenTint.png")
    }
    finally { $dbg.Dispose() }
  }
}

Write-Host "Done (Scope=$Scope)."
