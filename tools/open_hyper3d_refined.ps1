$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$godotExe = Join-Path $projectRoot '../../Godot_v4.7.2-stable_win64_console.exe'
Start-Process -FilePath $godotExe -WorkingDirectory $projectRoot -WindowStyle Hidden -ArgumentList @('--path', '.', '--rendering-method', 'gl_compatibility', 'res://presentation/previews/hyper3d_refined_preview.tscn')
