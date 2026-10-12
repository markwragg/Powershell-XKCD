# Create a single .psm1 module file containing all functions
# Copy new module and other supporting files (Documentation / Examples) to Staging folder
Task 'CombineFunctionsAndStage' -Depends 'Clean' {
    $lines

    # Create folders
    New-Item -Path $StagingFolder -ItemType 'Directory' -Force | Out-String | Write-Verbose
    New-Item -Path $StagingModulePath -ItemType 'Directory' -Force | Out-String | Write-Verbose

    # Get public and private function files
    $publicFunctions = @( Get-ChildItem -Path "$env:BHModulePath\Public\*.ps1" -Recurse -ErrorAction 'SilentlyContinue' )
    $privateFunctions = @( Get-ChildItem -Path "$env:BHModulePath\Private\*.ps1" -Recurse -ErrorAction 'SilentlyContinue' )

    # Combine functions into a single .psm1 module
    $combinedModulePath = Join-Path -Path $StagingModulePath -ChildPath "$($env:BHProjectName).psm1"
    @($publicFunctions + $privateFunctions) | Get-Content | Add-Content -Path $combinedModulePath

    # Copy other required folders and files if they exist
    $PathsToCopy = @(
        Join-Path -Path $ProjectRoot -ChildPath 'Documentation'
        Join-Path -Path $ProjectRoot -ChildPath 'Examples'
        Join-Path -Path $ProjectRoot -ChildPath 'CHANGELOG.md'
        Join-Path -Path $ProjectRoot -ChildPath 'README.md'
    )

    foreach ($Path in $PathsToCopy) {
        if (Test-Path $Path) {
            Copy-Item -Path $Path -Destination $StagingFolder -Recurse
        }
    }

    # Copy existing manifest
    Copy-Item -Path $env:BHPSModuleManifest -Destination $StagingModulePath -Recurse

    # Copy format/type ps1xml files (e.g. xkcd.Format.ps1xml) so the views they define ship with the
    # built module -- FormatsToProcess in the manifest references them by filename relative to the
    # module root, which the combined psm1 also resolves $PSScriptRoot to, so they need to sit
    # alongside it in Staging the same way they do in source.
    Get-ChildItem -Path $env:BHModulePath -Filter '*.ps1xml' -File | Copy-Item -Destination $StagingModulePath

    # Seed the staged module with the existing comic cache, so the 'Test' task's Update-XKCDCache call
    # can update it incrementally instead of rebuilding the entire cache from the XKCD API from scratch,
    # and so the cache ships as part of the published module (users don't have to build it themselves).
    $CacheSeedPath = Join-Path -Path $env:BHModulePath -ChildPath 'Public\XKCD.json'

    if (Test-Path $CacheSeedPath) {
        Copy-Item -Path $CacheSeedPath -Destination $StagingModulePath
    }
}
