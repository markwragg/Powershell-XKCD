Write-Host 'Running AppVeyor deploy script' -ForegroundColor Yellow

If ($env:APPVEYOR_REPO_BRANCH -notmatch 'master'){
    Write-Host "Finished testing of branch: $env:APPVEYOR_REPO_BRANCH - Exiting."
    exit;
}

Function Get-ModuleContents {
    Param ([string]$Path)
    Get-ChildItem -Exclude *.psd1 $Path | Where-Object { -not $_.PsIsContainer } | Get-Content
}

# Check module for differences 
Save-Module -Name $env:ModuleName -Path .\

$GitModuleContents = Get-ModuleContents .\$env:ModuleName\
$PSGModuleContents = Get-ModuleContents .\$env:ModuleName\*\*

$Differences = Compare-Object -ReferenceObject $GitModuleContents -DifferenceObject $PSGModuleContents

If ($Differences){
    # Update module manifest
    Write-Host 'Creating new module manifest'
    $ModuleManifestPath = Join-Path -path "$pwd\$env:ModuleName" -ChildPath ("$env:ModuleName"+'.psd1')
    $ModuleManifest     = Get-Content $ModuleManifestPath -Raw
    [regex]::replace($ModuleManifest,'(ModuleVersion = )(.*)',"`$1'$env:APPVEYOR_BUILD_VERSION'") | Out-File -LiteralPath $ModuleManifestPath

    # Publish to PS Gallery
    $ModulePath = Split-Path "$pwd\$env:ModuleName"
    Write-Host "Adding $ModulePath to 'psmodulepath' PATH variable"
    $env:psmodulepath = $env:psmodulepath + ';' + $ModulePath

    Write-Host 'Publishing module to Powershell Gallery.'
    Publish-Module -Name $env:ModuleName -NuGetApiKey $env:NuGetApiKey
} Else {
    Write-Host 'The module is unchanged, publishing skipped.'
}
