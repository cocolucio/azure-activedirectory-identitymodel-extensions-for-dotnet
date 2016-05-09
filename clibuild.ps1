$ErrorActionPreference = "Stop"

echo ""
echo "============================"
echo "clibuild.ps1"
echo "PSScriptRoot = $PSScriptRoot"
cd $PSScriptRoot

$repoFolder = $PSScriptRoot
$env:REPO_FOLDER = $repoFolder
$buildFolder = ".build"
$buildFile="$buildFolder\WilsonBuild.ps1"
&"$buildFile" $args