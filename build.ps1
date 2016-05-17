$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================"
Write-Host "clibuild.ps1"
Write-Host "PSScriptRoot = $PSScriptRoot"

& ".build\Build.ps1" $PSScriptRoot
