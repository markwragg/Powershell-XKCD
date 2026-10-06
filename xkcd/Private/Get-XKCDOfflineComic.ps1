function Get-XKCDOfflineComic {
    <#
    .SYNOPSIS
        Returns comic(s) from the local cache for use by -Offline, without making any network request. Throws
        if the cache file doesn't exist, since there's nothing offline to return in that case.
    #>
    [cmdletbinding()]
    Param(
        # Path to where comic data is cached.
        [Parameter(Mandatory)]
        [string]
        $CachePath,

        # Returns only the specified comic number(s) from the cache. By default every cached comic is returned.
        [int[]]
        $Number
    )

    if (-not (Test-Path $CachePath)) {
        throw "No local cache was found at '$CachePath'. Run Update-XKCDCache first, or omit -Offline."
    }

    $AllComics = Get-Content $CachePath | ConvertFrom-Json

    if ($Number) {
        $AllComics | Where-Object { $_.num -in $Number }
    }
    else {
        $AllComics
    }
}
