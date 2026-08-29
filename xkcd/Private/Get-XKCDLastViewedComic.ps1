function Get-XKCDLastViewedComic {
    <#
    .SYNOPSIS
        Returns the number of the most recently viewed comic recorded in the given state file, or 0 if the
        state file doesn't exist.
    #>
    [cmdletbinding()]
    Param(
        # Path to the file used to track the number of the most recently viewed comic.
        [Parameter(Mandatory)]
        [string]
        $StatePath
    )

    if (Test-Path $StatePath) {
        [int](Get-Content $StatePath | ConvertFrom-Json).LastViewed
    }
    else {
        0
    }
}
