Function Get-XKCDCache {
    <#
    .SYNOPSIS
        Returns the details of comics @ https://xkcd.com/ from the local cache.

    .DESCRIPTION
        The Get-XKCDCache cmdlet returns comic data straight from the local cache, without querying the XKCD API
        for each individual comic. This makes it a much faster way to retrieve the details of comics that have
        already been cached, and lets you use Where-Object, Sort-Object, Group-Object etc. to query the whole set
        of comics at once.

        Unlike Find-XKCD, this cmdlet does not create or refresh the cache itself. It only checks whether the
        cache exists and is up to date, and warns you to run Update-XKCDCache if it isn't.

    .EXAMPLE
        Get-XKCDCache

        Returns every comic in the local cache.

    .EXAMPLE
        Get-XKCDCache -Num 4,5,6

        Returns comics 4, 5 and 6 from the local cache.

    .EXAMPLE
        4,5,6 | Get-XKCDCache

        Returns comics 4, 5 and 6 from the local cache, specified via the pipeline.

    .EXAMPLE
        Get-XKCDCache | Where-Object year -eq 2010

        Returns every comic published in 2010, by filtering the full local cache.

    .EXAMPLE
        Get-XKCDCache | Sort-Object -Property { $_.title.Length } -Descending | Select-Object -First 1 title

        Returns the comic with the longest title.

    .LINK
        https://xkcd.com/json.html
    #>
    [cmdletbinding()]
    Param(
        # Returns only the specified comic numbers from the cache. Accepts array and pipeline input. By default every
        # cached comic is returned.
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [int[]]
        $Num,

        # Path to where comic data is cached
        [string]
        $CachePath = (Join-Path $PSScriptRoot 'XKCD.json')
    )
    begin {
        if (Test-Path $CachePath) {
            $AllComics = Get-Content $CachePath | ConvertFrom-Json
            $LastComic = ($AllComics | Sort-Object num -Descending | Select-Object -First 1).num
            $Latest = (Invoke-RestMethod 'https://xkcd.com/info.0.json').num

            if ($Latest -gt $LastComic) {
                Write-Warning "The local cache is out of date (latest cached comic is #$LastComic, #$Latest is now available). Run Update-XKCDCache to refresh it."
            }
        }
        else {
            Write-Warning "No local cache was found at '$CachePath'. Run Update-XKCDCache to create one."
            $AllComics = @()
        }
    }
    process {
        if ($Num) {
            $AllComics | Where-Object { $_.num -in $Num }
        }
        else {
            $AllComics
        }
    }
}
