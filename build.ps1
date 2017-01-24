Param(
    [cmdletbinding()]
    [string[]]$ModulesToPublish = $env:ModulesToPublish,
    [switch]$Build,
    [switch]$Install,
    [switch]$Test,
    [Parameter(ParameterSetName='Deploy')][switch]$Deploy,
    [Parameter(ParameterSetName='Deploy')][string]$NuGetApiKey = $env:NuGetApiKey
)

If ($ModulesToPublish) { $ModulesToPublish = $ModulesToPublish.Split(',') }


If ($Build) {

    If ($env:APPVEYOR){
        "Build version    : $env:APPVEYOR_BUILD_VERSION"
        "Author           : $env:APPVEYOR_REPO_COMMIT_AUTHOR"
        "Branch           : $env:APPVEYOR_REPO_BRANCH"
    }
        "ModulesToPublish : $ModulesToPublish"
}


If ($Install) {
    Write-Host 'Installing NuGet Package Provider'
    Install-PackageProvider -Name NuGet -Force
    
    Write-Host 'Installing Pester'
    Install-Module -Name Pester -Repository PSGallery -Force

    Write-Host 'Installing PSScriptAnalyzer'
    Install-Module PSScriptAnalyzer -Repository PSGallery -force
}


If ($Test) {
    $testResultsFile = 'TestsResults.xml'
    $Results = Invoke-Pester -Script .\Tests\*.Tests.ps1 -OutputFormat NUnitXml -OutputFile $testResultsFile -PassThru

    If ($env:APPVEYOR){
        #----- Workaround for https://github.com/appveyor/ci/issues/1271 -----
        [xml]$Content = Get-Content $testResultsFile
        $Content.'test-results'.'test-suite'.type = "Powershell"
        $Content.Save("$(Join-Path $pwd $testResultsFile)")
        #---------------------------------------------------------------------
        Write-Host "Uploading results to AppVeyor"
        
        (New-Object 'System.Net.WebClient').UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", (Resolve-Path $testResultsFile))
    }

    If (($Results.FailedCount -gt 0) -or ($Results.PassedCount -eq 0)) { 
        Throw "$($Results.FailedCount) tests failed."
    } Else {
        Write-Host 'All tests passed' -ForegroundColor Green
    }
}


If ($Deploy) {
    
    If ($env:APPVEYOR -and $env:APPVEYOR_REPO_BRANCH -notmatch 'master') {
        Write-Host "Finished testing of branch: $env:APPVEYOR_REPO_BRANCH - Exiting." -ForegroundColor
        Exit
    }
    
    $ModulesToPublish | ForEach-Object {
        
        $ModuleManifest = Get-ChildItem "$pwd\$Module\*.psd1"
        
        If ($ModuleManifest) {

            $Module           = $ModuleManifest.BaseName
            $ModulePath       = $ModuleManifest.Directory
            $ManifestFullName = $ModuleManifest.FullName

            Write-Host "$($Module) : Checking module for differences with existing PowerShell Gallery version"
            Save-Module -Name $Module -Path .\

            $ModuleContents    = Get-ChildItem -Exclude *.psd1 "$ModulePath\" | Where-Object { -not $_.PsIsContainer } | Get-Content
            $PSGModuleContents = Get-ChildItem -Exclude *.psd1 "$ModulePath\*\*" | Where-Object { -not $_.PsIsContainer } | Get-Content

            Remove-Item "$ModulePath\*\*" -Recurse -Force

            $Differences = Compare-Object $ModuleContents $PSGModuleContents

            If ($Differences){
            
                If (!$env:APPVEYOR_BUILD_VERSION) { 

                    Import-Module $Module

                    $CurVersion = Get-Module $Module | Select-Object -ExpandProperty Version            
                    $NewVersion = New-Object -TypeName System.Version -ArgumentList $CurVersion.Major, $CurVersion.Minor, ($CurVersion.Build + 1), 0

                } Else {
                    $NewVersion = $env:APPVEYOR_BUILD_VERSION
                }

                Write-Host "$Module : Updating module manifest to version $NewVersion"            
                        
                $ModuleManifest = Get-Content $ManifestFullName -Raw
                [regex]::replace($ModuleManifest,'(ModuleVersion = )(.*)',"`$1'$NewVersion'") | Out-File -LiteralPath $ManifestFullName
               
                Write-Host "$Module : Publishing module to the PowerShell Gallery"

                $env:psmodulepath = $env:psmodulepath + ';' + $ModulePath
                Publish-Module -Name $Module -NuGetApiKey $NuGetApiKey
            } Else {
                Write-Host "$Module : Could not locate a module manifest in $pwd\$Module\" -ForegroundColor Red
            }

        } Else {
            Write-Host "$Module : The module is already up to date in the Gallery" -ForegroundColor Green
        }
    }
}
