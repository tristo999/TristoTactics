# Headless verification for TristoTactics.
# Loads a scene headless (default: the dev_sandbox battle, which exercises the
# combat + combo scripts with autoloads present) and surfaces GDScript
# parse/compile/type errors. Catches "does it compile/load," NOT "is it fun."
#
# Why a battle scene, not the splash: scripts only referenced by data resources
# (follow-ups, abilities, character .tres) are not compiled by a menu load, so
# their errors stay hidden until a unit using them is instantiated. dev_sandbox
# spawns the cast, so those scripts get compiled.
#
# Usage:  powershell -File scripts/tools/verify.ps1
#         powershell -File scripts/tools/verify.ps1 -Scene res://scenes/menus/SplashScreen.tscn
#
# NOTE: --check-only per-script is NOT used here: it runs scripts in isolation
# without autoloads, so it false-positives "Identifier not found: EventBus" etc.
# Loading a real scene keeps autoloads available.
#
# Auto-heals the new-class_name cache quirk (editor scan + retry). Resolves Godot
# from PATH, else the local binary (update $Fallback).

param(
  [string]$Scene = 'res://scenes/levels/dev_sandbox_scene.tscn',
  [int]$Frames = 3
)
$ErrorActionPreference = 'Continue'

$Fallback = 'C:\Users\Tristan\Documents\Downloads\godot463\Godot_v4.6.3-stable_win64_console.exe'
$cmd = Get-Command godot -ErrorAction SilentlyContinue
$Godot = if ($cmd) { $cmd.Source } else { $Fallback }
if (-not (Test-Path -LiteralPath $Godot)) { Write-Output "Godot not found (PATH or '$Fallback')."; exit 2 }
$Project = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$patterns = @('SCRIPT ERROR', 'Parse Error', 'Error at', 'Cannot infer', 'Identifier not found',
  'Could not find type', 'not declared in the current scope', 'Could not resolve', 'does not inherit from', 'Failed to load')

function Invoke-Load { & $Godot --headless --path $Project $Scene --quit-after $Frames 2>&1 }
function Find-Errs($o) { $o | Select-String -Pattern $patterns }

Write-Output "Godot:   $(& $Godot --version)"
Write-Output "Scene:   $Scene"
Write-Output "=== headless load ($Frames frames) ==="
$out = Invoke-Load
$errs = Find-Errs $out
if ($errs -and ($errs -match 'Could not find type|not declared in the current scope|Could not resolve|does not inherit from')) {
  Write-Output "New class_name detected - editor scan to refresh the class cache..."
  & $Godot --headless --editor --quit --path $Project 2>&1 | Out-Null
  $out = Invoke-Load
  $errs = Find-Errs $out
}

if ($errs) {
  Write-Output "PROBLEMS FOUND:"
  $errs | Select-Object -First 30 | ForEach-Object { Write-Output ("  " + $_.Line) }
  exit 1
} else {
  Write-Output "CLEAN - scene loads, scripts compile (autoloads present)."
  exit 0
}
