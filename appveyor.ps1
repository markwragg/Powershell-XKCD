Param(
    [string[]]$ModulesToPublish = '',
    [switch]$Install,
    [switch]$Build,
    [switch]$Test,
    [switch]$Deploy,
    [string]$NuGetApiKey = $env:NuGetApiKey
)

If ($Install) {
    Write-Host 'Running installation script' -ForegroundColor Yellow

    'Installing NuGet PackageProvide'
    $pkg = Install-PackageProvider -Name NuGet -Force
    "Installed NuGet version '$($pkg.version)'" 

    'Installing Pester'
    Install-Module -Name Pester -Repository PSGallery -Force

    'Installing PSScriptAnalyzer'
    Install-Module PSScriptAnalyzer -Repository PSGallery -force
}


If ($Build) {
    If ($env:ModulesToPublish) { $ModulesToPublish = $env:ModulesToPublish.Split(',') }
    
    Write-Host 'Running build script' -ForegroundColor Yellow
    "ModulesToPublish : $ModulesToPublish"

    If ($env:APPVEYOR){
        "Build version : $env:APPVEYOR_BUILD_VERSION"
        "Author        : $env:APPVEYOR_REPO_COMMIT_AUTHOR"
        "Branch        : $env:APPVEYOR_REPO_BRANCH"
    }
}


If ($Test) {
    Write-Host 'Running AppVeyor test script' -ForegroundColor Yellow
    Write-Host "Current working directory: $pwd"

    $testResultsFile = 'TestsResults.xml'
    $Results = Invoke-Pester -Script .\Tests\*.Tests.ps1 -OutputFormat NUnitXml -OutputFile $testResultsFile -PassThru

    If ($env:APPVEYOR){
        #--Workaround for https://github.com/appveyor/ci/issues/1271
        [xml]$Content = Get-Content $testResultsFile
        $Content.'test-results'.'test-suite'.type = "Powershell"
        $Content.Save("$(Join-Path $pwd $testResultsFile)")
        #--Remove workaround when issue 1271 fixed

        Write-Host 'Uploading results'
        (New-Object 'System.Net.WebClient').UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", (Resolve-Path $testResultsFile))
    }

    If (($Results.FailedCount -gt 0) -or ($Results.PassedCount -eq 0)) { 
        throw "$($Results.FailedCount) tests failed."
    } Else {
        Write-Host 'All tests passed' -ForegroundColor Green
    }
}


If ($Deploy) {
    Write-Host 'Running deploy script' -ForegroundColor Yellow

    If ($env:APPVEYOR -and $env:APPVEYOR_REPO_BRANCH -notmatch 'master') {
        "Finished testing of branch: $env:APPVEYOR_REPO_BRANCH - Exiting."
        Exit
    }
    
    $ModulePaths = $ModulesToPublish | ForEach-Object { Get-ChildItem -Include "$_.psd1" -Recurse }  
    
    $ModulePaths | ForEach-Object {
        
        $Module = $_.BaseName
        $ModulePath = $_.Directory
        $ManifestFullName = $_.FullName

        "$($Module) : Checking module for differences with existing PS Gallery version"
        $PSGModule = Save-Module -Name $Module -Path .\

        $ModuleContents    = Get-ChildItem -Exclude *.psd1 "$ModulePath\" | Where-Object { -not $_.PsIsContainer } | Get-Content
        $PSGModuleContents = Get-ChildItem -Exclude *.psd1 "$ModulePath\*\*" | Where-Object { -not $_.PsIsContainer } | Get-Content

        Remove-Item "$ModulePath\*\*"

        $Differences = Compare-Object -ReferenceObject $ModuleContents -DifferenceObject $PSGModuleContents

        If ($Differences){
            
            If (!$env:APPVEYOR_BUILD_VERSION) { 
                Import-Module $Module
                $CurrentVersion = Get-Module $Module | Select -ExpandProperty Version            
                $NewVersion = New-Object -TypeName System.Version -ArgumentList $CurrentVersion.Major, $CurrentVersion.Minor, ($CurrentVersion.Build + 1), 0
            } Else {
                $NewVersion = $env:APPVEYOR_BUILD_VERSION
            }

            "$Module : Incrementing module manifest to version $NewVersion"            
                        
            $ModuleManifest = Get-Content $ManifestFullName -Raw
            [regex]::replace($ModuleManifest,'(ModuleVersion = )(.*)',"`$1'$NewVersion'") | Out-File -LiteralPath $ManifestFullName

            "$Module : Adding $ModulePath to 'psmodulepath' PATH variable"
            $env:psmodulepath = $env:psmodulepath + ';' + $ModulePath

            "$Module : Publishing module to Powershell Gallery"
            Publish-Module -Name $Module -NuGetApiKey $NuGetApiKey

        } Else {
            "$Module : No changes to publish"
        }
    }
}
