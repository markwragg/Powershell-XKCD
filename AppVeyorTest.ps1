Write-Host 'Running AppVeyor test script' -ForegroundColor Yellow
Write-Host "Current working directory: $pwd"

# Run Pester Tests
$testResultsFile = '.\TestsResults.xml'
$res             = Invoke-Pester -Script .\Tests\*.Tests.ps1 -OutputFormat NUnitXml -OutputFile $testResultsFile -PassThru

#Workaround for https://github.com/appveyor/ci/issues/1271
[xml]$content = Get-Content $testResultsFile
$content.'test-results'.'test-suite'.type = "Powershell"
$content.Save($testResultsFile)
#Remove workaround when issue fixed

Write-Host 'Uploading results'
(New-Object 'System.Net.WebClient').UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", (Resolve-Path $testResultsFile))

# Validate
If (($res.FailedCount -gt 0) -or ($res.PassedCount -eq 0)) { 
    throw "$($res.FailedCount) tests failed."
} else {
  Write-Host 'All tests passed' -ForegroundColor Green
}
