[CmdletBinding()]
param (
    [Parameter()]
    [System.String[]]
    $TaskList = 'Default',

    [Parameter()]
    [System.Collections.Hashtable]
    $Parameters,

    [Parameter()]
    [System.Collections.Hashtable]
    $Properties,

    [Parameter()]
    [Switch]
    $ResolveDependency
)

Write-Output "`nSTARTED TASKS: $($TaskList -join ',')`n"

Write-Output "`nPowerShell Version Information:"
$PSVersionTable

# Load dependencies
if ($PSBoundParameters.Keys -contains 'ResolveDependency') {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    # Bootstrap environment
    Get-PackageProvider -Name 'NuGet' -ForceBootstrap | Out-Null

    # Install PSDepend module if it is not already installed
    if (-not (Get-Module -Name 'PSDepend' -ListAvailable)) {
        Write-Output "`nPSDepend is not yet installed...installing PSDepend now..."
        Install-Module -Name 'PSDepend' -Scope 'CurrentUser' -Force
    } else {
        Write-Output "`nPSDepend already installed...skipping."
    }

    # Install build dependencies
    $psdependencyConfigPath = Join-Path -Path $PSScriptRoot -ChildPath 'build.depend.psd1'
    Write-Output "Checking / resolving module dependencies from [$psdependencyConfigPath]..."
    Import-Module -Name 'PSDepend'
    $invokePSDependParams = @{
        Path    = $psdependencyConfigPath
        # Tags = 'Bootstrap'
        # Import: PSDepend's own bundled YamlDotNet.dll (loaded on `Import-Module PSDepend` above)
        # conflicts with PlatyPS's newer bundled YamlDotNet.dll under PowerShell 7+ if PSDepend tries
        # to import every dependency into this same process. Installing only and letting each task
        # import/autoload what it needs (as they already do) avoids the clash.
        Import  = $false
        Confirm = $false
        Install = $true
        # Verbose = $true
    }
    Invoke-PSDepend @invokePSDependParams

    # Remove ResolveDependency PSBoundParameter ready for passthru to PSake
    $PSBoundParameters.Remove('ResolveDependency')
} else {
    Write-Host "Skipping dependency check...`n" -ForegroundColor 'Yellow'
}


# Init BuildHelpers
Set-BuildEnvironment -Force

# BuildHelpers 2.0.1 (pinned in build.depend.psd1) has no GitHub Actions detection, so Set-BuildEnvironment
# above would otherwise leave BHBuildSystem as 'Unknown' (silently disabling deploy.psdeploy.ps1's deploy
# gate) and fall back to a git rev-parse for BHBranchName, which returns 'HEAD' rather than the branch name
# when actions/checkout leaves the repo in a detached-HEAD state.
if ($env:GITHUB_ACTIONS -eq 'true') {
    $env:BHBuildSystem = 'GitHub Actions'
    $env:BHBranchName = $env:GITHUB_REF_NAME
    $env:BHBuildNumber = $env:GITHUB_RUN_NUMBER
}


# Execute PSake tasts
$invokePsakeParams = @{
    buildFile = (Join-Path -Path $env:BHProjectPath -ChildPath 'Build\build.psake.ps1')
    nologo    = $true
}
Invoke-Psake @invokePsakeParams @PSBoundParameters

Write-Output "`nFINISHED TASKS: $($TaskList -join ',')"

exit ( [int](-not $psake.build_success) )
