
param([string]$root)

Write-Host ""
Write-Host "============================"
Write-Host "Build.ps1"
Write-Host "root = $root"
Write-Host "PSScriptRoot = $PSScriptRoot"

[xml]$buildContent = Get-Content $PSScriptRoot\BuildConfiguration.xml

$dotnetVersion = Get-Content $PSScriptRoot\cli.version.win
$dotnetLocalInstallFolder = "$PSScriptRoot\dotnet\local\" + $dotnetVersion;
$dotnetexe = "$dotnetLocalInstallFolder\dotnet.exe";

Write-Host ""
Write-Host "============================"
Write-Host "Install donetcli"
Write-Host "dotnetVersion = $dotnetVersion"
Write-Host "dotnetLocalInstallFolder = $dotnetLocalInstallFolder"
Write-Host "dotnetexe = $dotnetexe"

& $PSScriptRoot\dotnet\install.ps1 -Channel "beta" -Version $dotnetVersion -Architecture x64 -InstallDir $dotnetLocalInstallFolder

Write-Host ""
Write-Host "============================"
Write-Host "RestoreAssemblies"
Write-Host "Start-Process -wait -NoNewWindow $dotnetexe restore -v Error"
Start-Process -wait -NoNewWindow $dotnetexe "restore -v Error"

$rootNode = $buildContent.projects
$projects = $buildContent.SelectNodes("projects/project");
Write-Host "rootNode =  $rootNode";
foreach($project in $projects) {
    $name = $project.name;
	Write-Host "Start-Process -wait -NoNewWindow $dotnetexe pack --no-build src\$name --configuration Debug"
    Start-Process -wait -NoNewWindow $dotnetexe "build src\$name --configuration Debug"
	Start-Process -wait -NoNewWindow $dotnetexe "pack --no-build src\$name --configuration Debug"
}

Write-Host ""
Write-Host "============================"
Write-Host "Run Tests"
Write-Host ""
$testProjects = $buildContent.SelectNodes("projects/testproject")
foreach ($testProject in $testProjects) {
    $name = $testProject.name;
    Write-Host ""
    Write-Host "name = $name";
    Write-Host "Set-Location $root\test\$name"
	Write-Host "Start-Process -wait -NoNewWindow $dotnetexe test --configuration Debug"
    Write-Host ""
    pushd
    Set-Location $root\test\$name
    Start-Process -wait -NoNewWindow $dotnetexe "test --configuration Debug"
    popd
}
