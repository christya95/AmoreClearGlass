# Generates all Amore glass pane textures (32x32).
#
# Clear: transparent center + neutral dark rim (production) / diagnostic.
# Stained: NEUTRAL rim bands match clear production (frame/lead not recolored). Interior (d>=3) adds only a
# faint wash on top of clear-like transparency — low alpha + low blend (dense interior = opaque sheet in-game).
#
# Usage (from repo root):
#   powershell -ExecutionPolicy Bypass -File scripts\generate-all-glass-pane-textures.ps1
# Tune green only:  ... -Scope Stained -GreenOnly
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

function Clamp-Byte([int]$v) {
  if ($v -lt 0) { return 0 }
  if ($v -gt 255) { return 255 }
  return $v
}

# Interior tint: low alpha + muted stain RGB (see-through, not milky). Tune $InteriorAlpha / blend.
function Get-InteriorTintRgb([int]$baseR, [int]$baseG, [int]$baseB, [double]$blend) {
  $nr, $ng, $nb = 34, 34, 36
  $r = Clamp-Byte ([int][Math]::Round($nr + ($baseR - $nr) * $blend))
  $g = Clamp-Byte ([int][Math]::Round($ng + ($baseG - $ng) * $blend))
  $b = Clamp-Byte ([int][Math]::Round($nb + ($baseB - $nb) * $blend))
  return @( $r, $g, $b )
}

# Stained: frame bands d=0..2 identical to clear production (neutral). d>=3 = uniform light tint (not alpha 0).
function New-StainedGlassBitmap([int]$w, [int]$h, [int]$baseR, [int]$baseG, [int]$baseB, [int]$InteriorAlpha, [double]$TintBlend) {
  $fmt = [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
  $bmp = New-Object System.Drawing.Bitmap -ArgumentList @($w, $h, $fmt)
  $tr, $tg, $tb = Get-InteriorTintRgb $baseR $baseG $baseB $TintBlend
  for ($y = 0; $y -lt $h; $y++) {
    for ($x = 0; $x -lt $w; $x++) {
      $dEdge = [int]([Math]::Min([Math]::Min($x, $y), [Math]::Min(($w - 1) - $x, ($h - 1) - $y)))
      if ($dEdge -ge 3) {
        $c = [System.Drawing.Color]::FromArgb($InteriorAlpha, $tr, $tg, $tb)
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

# Diagnostic: neutral frame + faint green interior (swap into a stained item JSON to test flicker/tint).
function New-StainedDiagnosticGreenBitmap([int]$w, [int]$h, [int]$InteriorAlpha, [double]$TintBlend) {
  $fmt = [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
  $bmp = New-Object System.Drawing.Bitmap -ArgumentList @($w, $h, $fmt)
  $gr, $gg, $gb = 48, 120, 72
  $tr, $tg, $tb = Get-InteriorTintRgb $gr $gg $gb $TintBlend
  for ($y = 0; $y -lt $h; $y++) {
    for ($x = 0; $x -lt $w; $x++) {
      $dEdge = [int]([Math]::Min([Math]::Min($x, $y), [Math]::Min(($w - 1) - $x, ($h - 1) - $y)))
      if ($dEdge -ge 3) {
        $c = [System.Drawing.Color]::FromArgb($InteriorAlpha, $tr, $tg, $tb)
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

# Stain base RGB (rim identity; avoid bright milky whites — keep slightly muted)
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

# Interior: match clear (A=0) in spirit — use very low alpha (~3–4) + modest blend so tint is a wash, not a sheet.
$interiorAlpha = 4
$tintBlend = 0.18

if ($Scope -eq "All" -or $Scope -eq "Stained") {
  foreach ($entry in $stainMap.GetEnumerator()) {
    $name = $entry.Key
    if ($GreenOnly -and $name -ne "Amore_Glass_Green") { continue }
    $rgb = $entry.Value
    $ia = $interiorAlpha
    $tb = $tintBlend
    if ($name -eq "Amore_Glass_White") { $ia = 3; $tb = 0.10 }
    if ($name -eq "Amore_Glass_Black") { $ia = 3; $tb = 0.11 }
    $b = New-StainedGlassBitmap $w $h $rgb[0] $rgb[1] $rgb[2] $ia $tb
    try {
      $fn = "$name.png"
      Write-Png32 $b (Join-Path $bt $fn)
    }
    finally { $b.Dispose() }
  }
  if (-not $GreenOnly) {
    $dbg = New-StainedDiagnosticGreenBitmap $w $h $interiorAlpha $tintBlend
    try {
      Write-Png32 $dbg (Join-Path $bt "Amore_Glass_Diagnostic_GreenTint.png")
    }
    finally { $dbg.Dispose() }
  }
}

Write-Host "Done (Scope=$Scope)."
