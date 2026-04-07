# Generates clear-glass pane textures (32x32). NO smooth gradients across the face (those read as frosted haze).
#
# Modes:
#   Diagnostic — center alpha 0, neutral dark RGB; only the outer 1-2 px have opacity (proves engine vs texture).
#   Production — same sharp falloff, slightly softer 3px clear margin + faint rim for normal play.
#
# Usage (repo root):
#   powershell -ExecutionPolicy Bypass -File scripts\generate-clear-glass-pane-texture.ps1 -Mode Both
#
param(
  [ValidateSet("Diagnostic", "Production", "Both")]
  [string]$Mode = "Both"
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

function New-DiagnosticBitmap {
  param([int]$w, [int]$h)
  $fmt = [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
  $bmp = New-Object System.Drawing.Bitmap -ArgumentList @($w, $h, $fmt)
  for ($y = 0; $y -lt $h; $y++) {
    for ($x = 0; $x -lt $w; $x++) {
      $dEdge = [int]([Math]::Min([Math]::Min($x, $y), [Math]::Min(($w - 1) - $x, ($h - 1) - $y)))
      # Inner 28x28: fully transparent — no gradient, no cross, no highlight
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

function New-ProductionBitmap {
  param([int]$w, [int]$h)
  $fmt = [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
  $bmp = New-Object System.Drawing.Bitmap -ArgumentList @($w, $h, $fmt)
  for ($y = 0; $y -lt $h; $y++) {
    for ($x = 0; $x -lt $w; $x++) {
      $dEdge = [int]([Math]::Min([Math]::Min($x, $y), [Math]::Min(($w - 1) - $x, ($h - 1) - $y)))
      # Clear interior: d >= 3 (inner 26x26). Sharp bands only — no smoothstep haze.
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

$diagPathBlocks = Join-Path $repoRoot "jar-assets\Common\Blocks\AmoreClearGlass\Amore_Clear_Glass_Diagnostic.png"
$prodPathBlocks = Join-Path $repoRoot "jar-assets\Common\Blocks\AmoreClearGlass\Amore_Clear_Glass.png"
$prodPathBt = Join-Path $repoRoot "jar-assets\Common\BlockTextures\Amore_Clear_Glass.png"
$diagPathBt = Join-Path $repoRoot "jar-assets\Common\BlockTextures\Amore_Clear_Glass_Diagnostic.png"

if ($Mode -eq "Diagnostic" -or $Mode -eq "Both") {
  $b = New-DiagnosticBitmap $w $h
  try {
    Write-Png32 $b $diagPathBlocks
    Write-Png32 $b $diagPathBt
  }
  finally { $b.Dispose() }
}

if ($Mode -eq "Production" -or $Mode -eq "Both") {
  $b = New-ProductionBitmap $w $h
  try {
    Write-Png32 $b $prodPathBlocks
    Write-Png32 $b $prodPathBt
  }
  finally { $b.Dispose() }
}
