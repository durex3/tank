$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$toolchain = Get-Content -LiteralPath (Join-Path $projectRoot 'toolchain.lock') -Raw | ConvertFrom-Json
$godotPath = [IO.Path]::GetFullPath((Join-Path $projectRoot $toolchain.local_executable))
& $godotPath --path $projectRoot --rendering-method gl_compatibility 'res://presentation/previews/modular_sample_preview.tscn'
