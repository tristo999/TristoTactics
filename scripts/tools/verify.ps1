# Headless verification for TristoTactics.
# Loads the project in headless mode and surfaces GDScript parse/load errors,
# so code changes can be checked without opening the editor.
# (Catches "does it compile/load," NOT "is it fun" — feel still needs a human.)
#
# Usage:   powershell -File scripts/tools/verify.ps1
#          powershell -File scripts/tools/verify.ps1 -Frames 4
#
# Resolves Godot from PATH if available, else falls back to the local binary.
# Update $Fallback if you move the binary (or add it to PATH and delete this note).

param([int]$Frames = 2)
$ErrorActionPreference = 'Continue'

$Fallback = 'C:\Users\Tristan\Documents\Downloads\godot463\Godot_v4.6.3-stable_win64_console.exe'
$cmd = Get-Command godot -ErrorAction SilentlyContinue
$Godot = if ($cmd) { $cmd.Source } else { $Fallback }

if (-not (Test-Path -LiteralPath $Godot)) {
  Write-Output "Godot not found (PATH or '$Fallback'). Update scripts/tools/verify.ps1."
  exit 2
}

$Project = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)  # repo root, up from scripts/tools
Write-Output "Godot:   $(& $Godot --version)"
Write-Output "Project: $Project"
Write-Output "=== headless load ($Frames frames) ==="

$out = & $Godot --headless --path $Project --quit-after $Frames 2>&1
$errs = $out | Select-String -Pattern 'SCRIPT ERROR', 'Parse Error', 'ERROR:', 'Failed to load', 'Cannot load', 'Invalid'
if ($errs) {
  Write-Output "PROBLEMS FOUND:"
  $errs | ForEach-Object { Write-Output ("  " + $_.Line) }
  exit 1
} else {
  Write-Output "CLEAN - project loads with no script/parse errors."
  exit 0
}
