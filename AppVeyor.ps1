Param(
    [switch]$Install,
    [switch]$Build,
    [switch]$Test,
    [switch]$Deploy
)

If ($Install){
    Write-Host 'Running AppVeyor install script' -ForegroundColor Yellow

    Write-Host 'Installing NuGet PackageProvide'
    $pkg = Install-PackageProvider -Name NuGet -Force
    Write-Host "Installed NuGet version '$($pkg.version)'" 

    Write-Host 'Installing Pester'
    Install-Module -Name Pester -Repository PSGallery -Force

    Write-Host 'Installing PSScriptAnalyzer'
    Install-Module PSScriptAnalyzer -Repository PSGallery -force
}


If ($Build){
    Write-Host 'Running AppVeyor build script' -ForegroundColor Yellow
    Write-Host "ModuleName    : $env:ModuleName"
    Write-Host "Build version : $env:APPVEYOR_BUILD_VERSION"
    Write-Host "Author        : $env:APPVEYOR_REPO_COMMIT_AUTHOR"
    Write-Host "Branch        : $env:APPVEYOR_REPO_BRANCH"
}


If ($Test){
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


If ($Deploy){
    Write-Host 'Running AppVeyor deploy script' -ForegroundColor Yellow

    If ($env:APPVEYOR_REPO_BRANCH -notmatch 'master'){
        Write-Host "Finished testing of branch: $env:APPVEYOR_REPO_BRANCH - Exiting."
        exit;
    }
     
    Write-Host 'Checking module for differences with existing PS Gallery version'
    Save-Module -Name $env:ModuleName -Path .\

    $GitModuleContents = Get-ChildItem -Exclude *.psd1 ".\$env:ModuleName\" | Where-Object { -not $_.PsIsContainer } | Get-Content
    $PSGModuleContents = Get-ChildItem -Exclude *.psd1 ".\$env:ModuleName\*\*" | Where-Object { -not $_.PsIsContainer } | Get-Content

    $Differences = Compare-Object -ReferenceObject $GitModuleContents -DifferenceObject $PSGModuleContents

    If ($Differences){
        Write-Host 'Creating new module manifest'
        $ModuleManifestPath = Join-Path -path "$pwd\$env:ModuleName" -ChildPath ("$env:ModuleName"+'.psd1')
        $ModuleManifest     = Get-Content $ModuleManifestPath -Raw
        [regex]::replace($ModuleManifest,'(ModuleVersion = )(.*)',"`$1'$env:APPVEYOR_BUILD_VERSION'") | Out-File -LiteralPath $ModuleManifestPath

        $ModulePath = Split-Path "$pwd\$env:ModuleName"
        Write-Host "Adding $ModulePath to 'psmodulepath' PATH variable"
        $env:psmodulepath = $env:psmodulepath + ';' + $ModulePath

        Write-Host 'Publishing module to Powershell Gallery.'
        Publish-Module -Name $env:ModuleName -NuGetApiKey $env:NuGetApiKey
    } Else {
        Write-Host 'The module is unchanged, publishing skipped.'
    }
}