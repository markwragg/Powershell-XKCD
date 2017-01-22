#---------------------------------# 
# Header                          # 
#---------------------------------# 
Write-Host 'Running AppVeyor deploy script' -ForegroundColor Yellow

#---------------------------------# 
# Update module manifest          # 
#---------------------------------# 
Write-Host 'Creating new module manifest'
$ModuleManifestPath = Join-Path -path "$pwd\$env:ModuleName" -ChildPath ("$env:ModuleName"+'.psd1')
$ModuleManifest     = Get-Content $ModuleManifestPath -Raw

[regex]::replace($ModuleManifest,'(ModuleVersion = )(.*)',"`$1'$env:APPVEYOR_BUILD_VERSION'") | Out-File -LiteralPath $ModuleManifestPath

#---------------------------------# 
# Publish to PS Gallery           # 
#---------------------------------# 
if ($env:APPVEYOR_REPO_BRANCH -notmatch 'master')
{
    Write-Host "Finished testing of branch: $env:APPVEYOR_REPO_BRANCH - Exiting"
    exit;
}

$ModulePath = Split-Path "$pwd\$env:ModuleName"
Write-Host "Adding $ModulePath to 'psmodulepath' PATH variable"
$env:psmodulepath = $env:psmodulepath + ';' + $ModulePath

Write-Host 'Publishing module to Powershell Gallery'
#Uncomment the below line, make sure you set the variables in appveyor.yml
Publish-Module -Name $env:ModuleName -NuGetApiKey $env:NuGetApiKey
