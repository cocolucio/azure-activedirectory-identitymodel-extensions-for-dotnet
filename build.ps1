param([string]$build="YES", [string]$buildConfiguration="Debug", [string]$installdotnet="YES", [string]$restore="YES", [string]$runtests="YES")

$ErrorActionPreference = "Stop"
& ".build\build.ps1" -build $build -buildConfiguration $buildConfiguration -installdotnet $installdotnet -restore $restore -root $PSScriptRoot -runtests $runtests

