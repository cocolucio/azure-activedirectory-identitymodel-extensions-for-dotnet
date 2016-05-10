
param([string]$buildConfigurationFilePath="..\.build\BuildConfiguration.xml")

echo ""
echo "============================"
echo "WilsonBuild.ps1"
echo "buildConfigurationFilePath = $buildConfigurationFilePath"

[xml]$buildContent = Get-Content $buildConfigurationFilePath
$projects = $buildConfigurationContent.SelectNodes("src/projects/project")
$dotnetVersionFile = 
$dotnetChannel = "beta"
$dotnetVersion = Get-Content ".build\cli.version.win"
    $dotnetLocalInstallFolder = ".build\Microsoft\dotnet"
    



for ($i = 0; ($i -lt $projects.Count) -and ($projects[$i].build -eq "Yes"); $i++)
{
    echo "=========================="
    $assemblyInfoPath = "$env:WORKSPACE\" + $projects[$i].assemblyInfoFilePath
    $projectJsonPath = "$env:WORKSPACE\" + $projects[$i].projectJsonFilePath
    UpdateAssemblyInfo $assemblyInfoPath $projects[$i].assemblyInfoVersion $date $rootNode.copyright

    $projectJsonUpdates = $projects[$i].SelectNodes("projectJson/package")
    for ($j = 0; $j -lt $projectJsonUpdates.Count; $j++)
    {
        $oldString = "`"" + $projectJsonUpdates[$j].name + "`": `"" + $projectJsonUpdates[$j].staticVersion
        $newString = "`"" + $projectJsonUpdates[$j].name + "`": `"" + $projectJsonUpdates[$j].currentVersion
        UpdateProjectJson $projectJsonPath $oldString $newString $date
    }        
}

function UpdateDotnetCli([string] $installDir, [string] $dotnetVersion, [string] $dotnetLocalInstallFolder )
{
    echo "$koreBuildFolder\dotnet\install.ps1 -Channel $dotnetChannel -Version $dotnetVersion -Architecture x64"
    & ".build\dotnet\install.ps1" -Channel $dotnetChannel -Version $dotnetVersion -Architecture x64 -InstallDir $dotnetLocalInstallFolder

    $dotnetexe = "$dotnetLocalInstallFolder\dotnet.exe";
    Write-Host ""
    Write-Host "Start-Process -wait -NoNewWindow $dotnetexe restore -v Error"
    Start-Process -wait -NoNewWindow $dotnetexe "restore -v Error"
}

$repoFolder = $env:REPO_FOLDER
echo ""
echo "============================"
echo "WilsonBuild.ps1"
echo "PSScriptRoot = $PSScriptRoot"
echo "repoFolder = $repoFolder"

cd $PSScriptRoot
if (!$repoFolder) {
    throw "REPO_FOLDER is not set"
}

Write-Host "Building $repoFolder"
cd $repoFolder


Write-Host ""
Write-Host "Start-Process -wait -NoNewWindow $dotnetexe build  src/*/project.json test/*/project.json --configuration Debug --no-incremental"
#Start-Process -wait -NoNewWindow $dotnetexe "build  src/*/project.json test/*/project.json --configuration Debug --no-incremental"

$srcFolder = $repoFolder + "\src";
$srcProjects = Get-Content $srcFile

echo ""
echo "============================"
echo "srcProjects = $srcProjects";

foreach ($project in $srcProjects) {
	Write-Host ""
	Write-Host "Start-Process -wait -NoNewWindow $dotnetexe pack --no-build src\$project --configuration Debug"
#	Start-Process -wait -NoNewWindow $dotnetexe "pack --no-build src\$project --configuration Debug"
}

$testFolder = $repoFolder + "\test";
$testProjects = Get-ChildItem $testFolder
echo ""
echo "============================"
echo "testProjects = $testProjects";

foreach ($project in $testProjects) {
    $projectFolder = $testFolder + "\" + $project;
    echo "testFolder = $testFolder";
    echo "project = $project";    
    echo "projectFolder = $projectFolder";
    if ($projectFolder + "\project.json")
    {
    	Write-Host ""
        Write-Host "Set-Location: $projectFolder"
        #Write-Host "Start-Process -wait -NoNewWindow $dotnetexe test test\$project -o $testFolder\project\bin\Debug\net451\win7-x64 --configuration Debug"
        Write-Host "Start-Process -wait -NoNewWindow $dotnetexe test --configuration Debug"

        Set-Location $projectFolder
        #Start-Process -wait -NoNewWindow $dotnetexe "test --no-build test\$project -o $testFolder\project\bin\Debug\net451\win7-x64 --configuration Debug"
        Start-Process -wait -NoNewWindow $dotnetexe "test --no-build --configuration Debug"        
    }
    else
    {
    	Write-Host ""
        Write-Host "No project.json found in: $projectFolder"        
    }
    
    Set-Location $PSScriptRoot
}
