# Regenerates clear-glass face PNGs only. Full pack: scripts\generate-all-glass-pane-textures.ps1
$ErrorActionPreference = "Stop"
& (Join-Path $PSScriptRoot "generate-all-glass-pane-textures.ps1") -Scope Clear
