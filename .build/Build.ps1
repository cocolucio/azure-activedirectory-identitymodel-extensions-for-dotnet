param([string]$build="YES", [string]$buildConfiguration="Debug", [string]$installdotnet="YES", [string]$restore="YES", [string]$root=$PSScriptRoot, [string]$runtests="YES")

function SetCoreFxVersion([string]$fileName, [string]$oldVersion, [string]$newVersion)
{
    Write-Host "fileName: " $fileName;
    Write-Host "oldVersion: " $oldVersion;
    Write-Host "newVersion: " $newVersion;
    $content = Get-Content -Path $fileName
    $newContent = $content -replace $oldVersion, $newVersion
    Set-Content $fileName $newContent
}

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

[xml]$buildConfiguration = Get-Content $PSScriptRoot\BuildConfiguration.xml

$author = $buildConfiguration.SelectSingleNode("root/author").InnerText;
$licenseUrl = $buildConfiguration.SelectSingleNode("root/licenseUrl").InnerText;
$cliChannel =  $buildConfiguration.SelectSingleNode("root/cliChannel").InnerText;
$cliVersionWin = $buildConfiguration.SelectSingleNode("root/cliVersionWin").InnerText;
$cliLocalInstallFolder = "$PSScriptRoot\dotnetcli\local\" + $cliVersionWin;
$copyright = $buildConfiguration.SelectSingleNode("root/copyright").InnerText;
$coreFxVersion = $buildConfiguration.SelectSingleNode("root/coreFxVersion").InnerText;
$nugetVersion = $buildConfiguration.SelectSingleNode("root/nugetVersion").InnerText;
$dotnetexe = "$cliLocalInstallFolder\dotnet.exe";

Write-Host ""
Write-Host "============================"
Write-Host "author: " $author;
Write-Host "copyright: " $copyright;
Write-Host "cliChannel: " $cliChannel;
Write-Host "cliLocalInstallFolder: " $cliLocalInstallFolder;
Write-Host "cliVersionWin: " $cliVersionWin;
Write-Host "coreFxVersion: " $coreFxVersion;
Write-Host "dotnetexe: " $dotnetexe;
Write-Host "licenseUrl: " $licenseUrl;
Write-Host "nugetVersion: " $nugetVersion;

if ($installdotnet -eq "YES")
{
    Write-Host ""
    Write-Host "============================"
    Write-Host "Install donetcli"
    Write-Host "cliVersionWin = $cliVersionWin"
    Write-Host "dotnetLocalInstallFolder = $cliLocalInstallFolder"
    Write-Host "dotnetexe = $dotnetexe"
    Write-Host ""
    &$PSScriptRoot\dotnetcli\install.ps1 -Channel $cliChannel -Version $cliVersionWin -Architecture x64 -InstallDir $cliLocalInstallFolder
}

if ($build -eq "YES")
{
    Write-Host ""
    Write-Host "============================"
    Write-Host "Update project.json"
    Write-Host ""
    $rootNode = $buildConfiguration.projects
    $projects = $buildConfiguration.SelectNodes("root/projects/src/project");
    foreach($project in $projects) {
        $name = $project.name;
        SetCoreFxVersion "$root\src\$name\project.json" "-*" $coreFxVersion;
    }
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
    $rootNode = $buildConfiguration.projects
    $projects = $buildConfiguration.SelectNodes("projects/src/project");
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
    $testProjects = $buildConfiguration.SelectNodes("projects/test/project")
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