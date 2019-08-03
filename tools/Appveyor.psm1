$ProgressPreference = "SilentlyContinue"
$ErrorActionPreference = "Stop"

function New-AppveyorPackage
{
    Write-Host -ForegroundColor Cyan "Creating Nuget Package"
    $repoLocation = "$env:TEMP\TempRepository"
    $projectRoot = "$env:APPVEYOR_BUILD_FOLDER"
    $outputDir = "$env:APPVEYOR_BUILD_FOLDER\PrtgXml"

    InstallProvider
    CreateRepo $repoLocation $outputDir
    
    CreatePowerShell $outputDir

    TestPackage

    if($env:APPVEYOR)
    {
        $pkg = Get-ChildItem $env:temp\TempRepository\*.nupkg
        
        if(!$pkg)
        {
            throw "Could not find a nupkg"
        }
        
        Write-Host "Moving package $($pkg.Name) to $env:APPVEYOR_BUILD_FOLDER\$($pkg.Name)"
        
        Move-Item $pkg.Fullname "$env:APPVEYOR_BUILD_FOLDER\$($pkg.BaseName)_PowerShell.nupkg"
    }

    Write-Host "Unregistering temp repository"
    Unregister-PSRepository TempRepository

    Write-Host "Removing temp repository folder"
    remove-item -Recurse $repoLocation -Force
}

function Set-AppveyorVersion
{
    $version = (Import-PowerShellDataFile .\PrtgXml\PrtgXml.psd1).ModuleVersion
    Write-Host "Attempting to set Appveyor build to version '$version'"
    Update-AppveyorBuild -Version $version
}

function Invoke-AppveyorTest
{
    $result = Invoke-Pester -Path $env:APPVEYOR_BUILD_FOLDER -PassThru

    if($result.FailedCount -gt 0)
    {
        throw "$($result.FailedCount) Pester tests failed"
    }
}

function Invoke-AppveyorInstall
{
    if(!(gcm Invoke-Pester -ErrorAction SilentlyContinue))
    {
        Install-Module Pester -Force -SkipPublisherCheck -Scope CurrentUser
    }
}

function Simulate-AppveyorPackage
{
    $env:APPVEYOR_BUILD_FOLDER = Join-Path $PSScriptRoot ".."

    New-AppveyorPackage
}

#region Setup

function InstallProvider
{
    if(!(get-packageprovider|where name -eq nuget))
    {
        Write-Host "Installing NuGet package provider"
        install-packageprovider nuget -force
    }
}

function CreateRepo($repoPath, $outputDir)
{
    Write-Host "Creating temporary repository"

    if(Test-Path $repoPath)
    {
        Write-Host -ForegroundColor Red "    Removing repository folder left over from previous run..."
        remove-item -Recurse $repoPath -Force
    }
    
    Write-Host "    Creating repo folder"
    New-Item -ItemType Directory $repoPath|Out-Null

    if(get-psrepository|where name -eq TempRepository)
    {
        Write-Host -ForegroundColor Red "    Removing repository left over from previous run..."
        Unregister-PSRepository TempRepository
    }

    Write-Host "    Registering repo"
    Register-PSRepository -Name TempRepository -SourceLocation $repoPath -PublishLocation $repoPath -InstallationPolicy Trusted
}

#endregion

function CreatePowerShell($outputDir)
{
    BackupOutputDir $outputDir

    gci $outputDir -Filter *.cmd | Remove-Item -Force

    Write-Host "Publishing module to TempRepository"

    Publish-Module -Path $outputDir -Repository TempRepository

    RestoreOutputDir $outputDir
}

function BackupOutputDir($outputDir)
{
    Write-Host "Backing up build output"

    if($outputDir.EndsWith("\"))
    {
        $outputDir = $outputDir.Substring(0, $outputDir.Length - 1)
    }

    Copy-Item -Recurse $outputDir "$($outputDir)_bak"
}

function RestoreOutputDir($outputDir)
{
    if($outputDir.EndsWith("\"))
    {
        $outputDir = $outputDir.Substring(0, $outputDir.Length - 1)
    }

    Write-Host "Restoring build output"
    gci "$($outputDir)_bak" | foreach { mv $_.FullName "$outputDir\$($_.Name)" -Force }
    
    Remove-Item -Recurse -Force "$($outputDir)_bak"
}

function TestPackage
{
    Write-Host "Testing package"

    Write-Host "    Installing Package"
    if(!(Install-Package PrtgXml -Source TempRepository))
    {
        throw "PrtgXml did not install properly"
    }

    Write-Host "    Validating function output"

    $result = try { Prtg { } } catch [exception] { $_.exception.message }

    Uninstall-Package PrtgXml | Out-Null

    $expected = "Prtg block requires an inner element."

    if($result -ne $expected)
    {
        throw "Expected '$expected' but got '$result'"
    }
}

$functions = @(
    "Invoke-AppveyorInstall"
    "Invoke-AppveyorTest"
    "New-AppveyorPackage"
    "Set-AppveyorVersion"
    "Simulate-AppveyorPackage"
)

Export-ModuleMember $functions