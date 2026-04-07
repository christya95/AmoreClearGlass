# Dev helper: alpha/RGB stats for a PNG (e.g. clear-glass face after regen). Not used by the mod at runtime.
param([Parameter(Mandatory=$true)][string]$Path)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
if (-not (Test-Path $Path)) { throw "Not found: $Path" }
$bmp = [System.Drawing.Bitmap]::FromFile($Path)
$w = $bmp.Width
$h = $bmp.Height
$sumA = 0L; $sumR = 0L; $sumG = 0L; $sumB = 0L
$n = $w * $h
$minA = 255; $maxA = 0
$cx0 = [int]($w * 0.25); $cx1 = [int]($w * 0.75)
$cy0 = [int]($h * 0.25); $cy1 = [int]($h * 0.75)
$rsA = 0L; $rsR = 0L; $rsG = 0L; $rsB = 0L; $rn = 0
$nonZero = 0
$bright = 0
$center = $bmp.GetPixel([int]($w / 2), [int]($h / 2))
for ($y = 0; $y -lt $h; $y++) {
  for ($x = 0; $x -lt $w; $x++) {
    $c = $bmp.GetPixel($x, $y)
    $a = $c.A
    $sumA += $a; $sumR += $c.R; $sumG += $c.G; $sumB += $c.B
    if ($a -lt $minA) { $minA = $a }
    if ($a -gt $maxA) { $maxA = $a }
    if ($a -gt 8) { $nonZero++ }
    $lum = 0.299 * $c.R + 0.587 * $c.G + 0.114 * $c.B
    if ($a -gt 12 -and $lum -gt 195) { $bright++ }
    if ($x -ge $cx0 -and $x -lt $cx1 -and $y -ge $cy0 -and $y -lt $cy1) {
      $rsA += $a; $rsR += $c.R; $rsG += $c.G; $rsB += $c.B; $rn++
    }
  }
}
$bmp.Dispose()
Write-Host "File: $Path"
Write-Host "minA=$minA maxA=$maxA meanA=$([math]::Round($sumA / [double]$n, 2))"
Write-Host "meanRGB=$([math]::Round($sumR / [double]$n, 1)),$([math]::Round($sumG / [double]$n, 1)),$([math]::Round($sumB / [double]$n, 1))"
Write-Host "centerPixel RGBA=$($center.R),$($center.G),$($center.B),$($center.A)"
Write-Host "inner50pct meanA=$([math]::Round($rsA / [double]$rn, 2)) meanRGB=$([math]::Round($rsR / [double]$rn, 1)),$([math]::Round($rsG / [double]$rn, 1)),$([math]::Round($rsB / [double]$rn, 1))"
$pctNZ = [math]::Round(100.0 * $nonZero / $n, 2)
$pctBr = [math]::Round(100.0 * $bright / $n, 2)
Write-Host "pixels A>8: $nonZero ($pctNZ %)"
Write-Host "pixels A>12 and lum>195 (bright haze risk): $bright ($pctBr %)"
