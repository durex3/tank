$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$godotExe = Join-Path $projectRoot '../../Godot_v4.7.2-stable_win64_console.exe'
Start-Process -FilePath $godotExe -WorkingDirectory $projectRoot -WindowStyle Hidden -ArgumentList @('--path', '.', '--rendering-method', 'gl_compatibility', '--script', 'tools/play_mechanical_sample_106.gd')
