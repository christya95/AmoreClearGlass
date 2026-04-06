# Imports Clear Glass Pack (Minecraft) tiles without the gIass.png watermark, scales for Hytale.
# Set $env:MC_CLEAR_GLASS_PACK to your pack root, or edit $defaultMc below.
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root = Split-Path $PSScriptRoot -Parent
$defaultMc = "C:\Users\josua\Downloads\Clear Glass Pack 1.26\assets\minecraft\optifine\ctm\glass"
$mcGlass = if ($env:MC_CLEAR_GLASS_PACK) { $env:MC_CLEAR_GLASS_PACK } else { $defaultMc }

$btOut = Join-Path $root "jar-assets\Common\BlockTextures"
$icOut = Join-Path $root "jar-assets\Common\Icons\ItemsGenerated"

if (-not (Test-Path $mcGlass)) {
  throw "Minecraft Clear Glass Pack not found at: $mcGlass`nSet env MC_CLEAR_GLASS_PACK to the folder that contains aregular\, black\, red\, etc."
}

New-Item -ItemType Directory -Force -Path $btOut, $icOut | Out-Null

function Save-ScaledPng([string]$sourcePath, [string]$destPath, [int]$w, [int]$h) {
  $src = [System.Drawing.Image]::FromFile($sourcePath)
  try {
    $bmp = New-Object System.Drawing.Bitmap $w, $h
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    $g.DrawImage($src, 0, 0, $w, $h)
    $g.Dispose()
    $bmp.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
  }
  finally {
    $src.Dispose()
  }
}

# MC clear-glass tiles use A=0 + RGB black for "air" in the pane. That reads as black in Hytale unless RGB is tinted.
# Keep real alpha so Transparent + RequiresAlphaBlending can blend; use light icy RGB (not 0,0,0).
function Repair-ClearGlassTile([string]$pngPath) {
  $bytes = [System.IO.File]::ReadAllBytes($pngPath)
  $ms = New-Object System.IO.MemoryStream(,$bytes)
  $bmp = [System.Drawing.Bitmap]::FromStream($ms)
  $ms.Dispose()
  try {
    for ($y = 0; $y -lt $bmp.Height; $y++) {
      for ($x = 0; $x -lt $bmp.Width; $x++) {
        $c = $bmp.GetPixel($x, $y)
        if ($c.A -eq 0 -and $c.R -lt 48 -and $c.G -lt 48 -and $c.B -lt 48) {
          $glass = [System.Drawing.Color]::FromArgb(200, 210, 228, 248)
          $bmp.SetPixel($x, $y, $glass)
        }
      }
    }
    $bmp.Save($pngPath, [System.Drawing.Imaging.ImageFormat]::Png)
  }
  finally {
    $bmp.Dispose()
  }
}

$idMap = @{
  "Amore_Clear_Glass"   = @{ folder = "aregular"; file = "glass.png" }
  "Amore_Glass_Black"   = @{ folder = "black";    file = "20.png" }
  "Amore_Glass_Blue"    = @{ folder = "blue";     file = "20.png" }
  "Amore_Glass_Brown"   = @{ folder = "brown";    file = "20.png" }
  "Amore_Glass_Cyan"    = @{ folder = "cyan";     file = "20.png" }
  "Amore_Glass_Gray"    = @{ folder = "gray";     file = "20.png" }
  "Amore_Glass_Green"   = @{ folder = "green";    file = "20.png" }
  "Amore_Glass_Light_Blue"  = @{ folder = "lightblue"; file = "20.png" }
  "Amore_Glass_Lime"    = @{ folder = "lime";     file = "20.png" }
  "Amore_Glass_Magenta" = @{ folder = "magenta";  file = "20.png" }
  "Amore_Glass_Orange"  = @{ folder = "orange";   file = "20.png" }
  "Amore_Glass_Pink"    = @{ folder = "pink";     file = "20.png" }
  "Amore_Glass_Purple"  = @{ folder = "purple";   file = "20.png" }
  "Amore_Glass_Red"     = @{ folder = "red";      file = "20.png" }
  "Amore_Glass_Light_Gray" = @{ folder = "silver"; file = "20.png" }
  "Amore_Glass_White"   = @{ folder = "white";    file = "20.png" }
  "Amore_Glass_Yellow"  = @{ folder = "yellow";   file = "20.png" }
  "Amore_Glass_Tinted"  = @{ folder = "ztinted";  file = "20.png" }
}

Get-ChildItem (Join-Path $root "jar-assets\Server\Item\Items\AmoreClearGlass") -Filter "*.json" | ForEach-Object {
  $id = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
  if (-not $idMap.ContainsKey($id)) { throw "No MC texture mapping for item id: $id" }
  $m = $idMap[$id]
  $srcPath = Join-Path (Join-Path $mcGlass $m.folder) $m.file
  if (-not (Test-Path $srcPath)) { throw "Missing source file: $srcPath" }

  $flat = "$id.png"
  Save-ScaledPng $srcPath (Join-Path $btOut $flat) 32 32
  Save-ScaledPng $srcPath (Join-Path $icOut $flat) 64 64
  if ($id -eq "Amore_Clear_Glass") {
    Repair-ClearGlassTile (Join-Path $btOut $flat)
    Repair-ClearGlassTile (Join-Path $icOut $flat)
  }
}

Write-Host "Imported clean CTM tiles from: $mcGlass"
Write-Host "Clear glass: repaired A=0 black holes in BlockTextures + Icons. Stained: unchanged alpha from pack."
