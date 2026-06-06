# Headless verification for TristoTactics.
# Loads the project in headless mode and surfaces GDScript parse/load errors,
# so code changes can be checked without opening the editor.
# (Catches "does it compile/load," NOT "is it fun" — feel still needs a human.)
#
# Usage:   powershell -File scripts/tools/verify.ps1
#          powershell -File scripts/tools/verify.ps1 -Frames 4
#
# Auto-heals the one common false alarm: a brand-new `class_name` isn't in
# Godot's global class cache until the editor scans it, so a headless *game*
# run can't see it. If that's detected, this runs a one-shot editor scan to
# refresh the cache, then retries.
#
# Resolves Godot from PATH if available, else the local binary (update $Fallback).

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

function Invoke-Load { & $Godot --headless --path $Project --quit-after $Frames 2>&1 }
function Find-Errs($o) { $o | Select-String -Pattern 'SCRIPT ERROR', 'Parse Error', 'ERROR:', 'Failed to load', 'Cannot load', 'Invalid' }

Write-Output "Godot:   $(& $Godot --version)"
Write-Output "Project: $Project"
Write-Output "=== headless load ($Frames frames) ==="

$out = Invoke-Load
$errs = Find-Errs $out
if ($errs -and ($errs -match 'Could not find type|not declared in the current scope|Could not resolve external class|does not inherit from')) {
  Write-Output "New class_name detected - refreshing class cache via editor scan..."
  & $Godot --headless --editor --quit --path $Project 2>&1 | Out-Null
  $out = Invoke-Load
  $errs = Find-Errs $out
}

if ($errs) {
  Write-Output "PROBLEMS FOUND:"
  $errs | ForEach-Object { Write-Output ("  " + $_.Line) }
  exit 1
} else {
  Write-Output "CLEAN - project loads with no script/parse errors."
  exit 0
}
