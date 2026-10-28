Task 'Commit' -Depends 'Init' {
    $lines

    Set-Location $ProjectRoot
    $Module = $env:BHProjectName

    git --version
    git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
    git config --global user.name "github-actions[bot]"
    git checkout $env:GITHUB_REF_NAME

    # The 'Test' task refreshes the comic cache only inside the staged module copy, not the source
    # checked into git. Copy it back so the seed used by the next build stays up to date.
    $StagedCachePath = Join-Path -Path $StagingModulePath -ChildPath 'XKCD.json'
    $SourceCachePath = Join-Path -Path $env:BHModulePath -ChildPath 'Public\XKCD.json'

    if (Test-Path $StagedCachePath) {
        Copy-Item -Path $StagedCachePath -Destination $SourceCachePath -Force
    }

    git add Documentation/*.md
    git add README.md
    git add CHANGELOG.md
    git add $SourceCachePath
    git add $env:BHPSModuleManifest
    git commit -m "[skip ci] GitHub Actions Build $env:GITHUB_RUN_NUMBER"
    git push
}
