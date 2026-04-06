# Imports Clear Glass Pack (Minecraft) tiles without the gIass.png watermark, scales for Hytale.
# Watermark lives on gIass.png; CTM tile 20.png is a clean stained-glass face per color.
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

# Composite every pixel onto a solid background and force A=255. World translucency comes from BlockType Opacity, not PNG alpha.
function Flatten-BlockTextureOnBackground([string]$pngPath, [int]$br, [int]$bg, [int]$bb) {
  $bytes = [System.IO.File]::ReadAllBytes($pngPath)
  $ms = New-Object System.IO.MemoryStream(,$bytes)
  $bmp = [System.Drawing.Bitmap]::FromStream($ms)
  $ms.Dispose()
  try {
    for ($y = 0; $y -lt $bmp.Height; $y++) {
      for ($x = 0; $x -lt $bmp.Width; $x++) {
        $c = $bmp.GetPixel($x, $y)
        $a = [int]$c.A
        $r = [int]$c.R; $g = [int]$c.G; $b = [int]$c.B
        $nr = [int][math]::Round(($r * $a + $br * (255 - $a)) / 255)
        $ng = [int][math]::Round(($g * $a + $bg * (255 - $a)) / 255)
        $nb = [int][math]::Round(($b * $a + $bb * (255 - $a)) / 255)
        $nr = [math]::Min(255, [math]::Max(0, $nr))
        $ng = [math]::Min(255, [math]::Max(0, $ng))
        $nb = [math]::Min(255, [math]::Max(0, $nb))
        $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $nr, $ng, $nb))
      }
    }
    $bmp.Save($pngPath, [System.Drawing.Imaging.ImageFormat]::Png)
  }
  finally {
    $bmp.Dispose()
  }
}

# Item Id -> { folder = MC subfolder; file = png name in that folder }
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
    Flatten-BlockTextureOnBackground (Join-Path $btOut $flat) 210 228 248
  } else {
    Flatten-BlockTextureOnBackground (Join-Path $btOut $flat) 255 255 255
  }
}

Write-Host "Imported clean CTM tiles from: $mcGlass"
Write-Host "BlockTextures flattened to opaque RGB (alpha from BlockType only). Icons unchanged."
