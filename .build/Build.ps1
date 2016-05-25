param([string]$build="YES", [string]$buildConfiguration="Debug", [string]$installdotnet="YES", [string]$restore="YES", [string]$root=$PSScriptRoot, [string]$runtests="YES")

Write-Host ""
Write-Host "============================"
Write-Host "build.ps1"
Write-Host "build: " $build;
Write-Host "buildConfiguration: " $buildConfiguration;
Write-Host "installdotnet: " $installdotnet;
Write-Host "restore: " $restore;
Write-Host "root: " $root;
Write-Host "runtests: " $runtests;
Write-Host "PSScriptRoot: " $PSScriptRoot;

[xml]$buildContent = Get-Content $PSScriptRoot\BuildConfiguration.xml

$dotnetVersion = Get-Content $PSScriptRoot\cli.version.win
$dotnetLocalInstallFolder = "$PSScriptRoot\dotnet\local\" + $dotnetVersion;
$dotnetexe = "$dotnetLocalInstallFolder\dotnet.exe";

if ($installdotnet -eq "YES")
{
    Write-Host ""
    Write-Host "============================"
    Write-Host "Install donetcli"
    Write-Host "dotnetVersion = $dotnetVersion"
    Write-Host "dotnetLocalInstallFolder = $dotnetLocalInstallFolder"
    Write-Host "dotnetexe = $dotnetexe"
    Write-Host ""
    &$PSScriptRoot\dotnet\install.ps1 -Channel "beta" -Version $dotnetVersion -Architecture x64 -InstallDir $dotnetLocalInstallFolder
}

if ($restore -eq "YES")
{
    Write-Host ""
    Write-Host "============================"
    Write-Host "RestoreAssemblies"
    Write-Host "Start-Process -wait -NoNewWindow $dotnetexe restore -v Error"
    Write-Host ""
    Start-Process -wait -NoNewWindow $dotnetexe "restore -v Error"
}

if ($build -eq "YES")
{
    Write-Host ""
    Write-Host "============================"
    Write-Host "Build and pack assemblies"
    Write-Host ""
    $rootNode = $buildContent.projects
    $projects = $buildContent.SelectNodes("projects/src/project");
    foreach($project in $projects) {
        $name = $project.name;
        Write-Host "Start-Process -wait -NoNewWindow $dotnetexe pack --no-build src\$name --configuration $buildConfiguration"
        Write-Host ""
        Start-Process -wait -NoNewWindow $dotnetexe "build src\$name --configuration $buildConfiguration"
        Start-Process -wait -NoNewWindow $dotnetexe "pack --no-build src\$name --configuration $buildConfiguration"
    }
}

if ($test -eq "YES")
{
    Write-Host ""
    Write-Host "============================"
    Write-Host "Run Tests"
    Write-Host ""
    $testProjects = $buildContent.SelectNodes("projects/test/project")
    foreach ($testProject in $testProjects) {
        $name = $testProject.name;
        Write-Host "name = $name";
        Write-Host "Set-Location $root\test\$name"
        Write-Host "Start-Process -wait -NoNewWindow $dotnetexe test --configuration $buildConfiguration"
        Write-Host ""
        pushd
        Set-Location $root\test\$name
        Start-Process -wait -NoNewWindow $dotnetexe "test --configuration $buildConfiguration"
        popd
    }
}
