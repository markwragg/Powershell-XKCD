Write-Host 'Running AppVeyor test script' -ForegroundColor Yellow
Write-Host "Current working directory: $pwd"

# Run Pester Tests
$testResultsFile = 'TestsResults.xml'
$Results = Invoke-Pester -Script .\Tests\*.Tests.ps1 -OutputFormat NUnitXml -OutputFile $testResultsFile -PassThru

If ($env:APPVEYOR){
    #Workaround for https://github.com/appveyor/ci/issues/1271
    [xml]$Content = Get-Content $testResultsFile
    $Content.'test-results'.'test-suite'.type = "Powershell"
    $Content.Save("$(Join-Path $pwd $testResultsFile)")
    #Remove workaround when issue 1271 fixed

    Write-Host 'Uploading results'
    (New-Object 'System.Net.WebClient').UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", (Resolve-Path $testResultsFile))
}

# Validate
If (($Results.FailedCount -gt 0) -or ($Results.PassedCount -eq 0)) { 
    throw "$($Results.FailedCount) tests failed."
} Else {
    Write-Host 'All tests passed' -ForegroundColor Green
}
