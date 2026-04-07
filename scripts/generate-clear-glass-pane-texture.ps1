# Backward-compatible entry: regenerates clear glass textures (diagnostic + production).
# Full pipeline (clear + all stained): scripts\generate-all-glass-pane-textures.ps1
$ErrorActionPreference = "Stop"
& (Join-Path $PSScriptRoot "generate-all-glass-pane-textures.ps1") -Scope Clear
