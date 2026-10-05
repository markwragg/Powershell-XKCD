function Get-XKCDCache {
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

        Each returned comic also has a 'date' property (a [datetime] combining day/month/year, so results can be
        sorted or filtered by date), and 'html_img'/'html' properties, computed from those properties, for
        embedding the comic in HTML output -- 'html_img' is just the <img> tag, and 'html' wraps that same tag in
        a link to the comic's page on xkcd.com. Comics are tagged with the 'XKCD.Comic' type name, so they pick
        up the same curated list/table views as Get-XKCD -- a single comic as a list, several as a table. Use
        -Raw to omit these and get each comic exactly as cached.

    .EXAMPLE
        Get-XKCDCache

        Returns every comic in the local cache.

    .EXAMPLE
        Get-XKCDCache -Number 4,5,6

        Returns comics 4, 5 and 6 from the local cache.

    .EXAMPLE
        4,5,6 | Get-XKCDCache

        Returns comics 4, 5 and 6 from the local cache, specified via the pipeline.

    .EXAMPLE
        Get-XKCDCache | Where-Object year -eq 2010

        Returns every comic published in 2010, by filtering the full local cache.

    .EXAMPLE
        Get-XKCDCache -Year 2010

        Returns every comic published in 2010, equivalent to the previous example but filtered within the cache
        instead of by Where-Object.

    .EXAMPLE
        Get-XKCDCache -Month 10 -Day 31

        Returns every comic published on October 31st, of any year.

    .EXAMPLE
        Get-XKCDCache | Sort-Object -Property { $_.title.Length } -Descending | Select-Object -First 1 title

        Returns the comic with the longest title.

    .EXAMPLE
        Get-XKCDCache -Raw

        Returns every cached comic exactly as cached, without the 'date', 'html_img' or 'html' properties
        Get-XKCDCache normally adds, and without the 'XKCD.Comic' type name that drives its table/list formatting.

    .LINK
        https://xkcd.com/json.html
    #>
    [cmdletbinding()]
    Param(
        # Returns only the specified comic numbers from the cache. Accepts array and pipeline input. By default every
        # cached comic is returned.
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [Alias('Num')]
        [int[]]
        $Number,

        # Returns only comics published in the specified year(s). By default comics from every year are returned.
        [int[]]
        $Year,

        # Returns only comics published in the specified month(s) (1-12). By default comics from every month are
        # returned.
        [ValidateRange(1, 12)]
        [int[]]
        $Month,

        # Returns only comics published on the specified day(s) of the month. By default comics from every day
        # are returned.
        [ValidateRange(1, 31)]
        [int[]]
        $Day,

        # Path to where comic data is cached. By default this is within the module path, unless a default has
        # been saved with Set-XKCDDefault -CachePath.
        [string]
        $CachePath = (Get-XKCDDefaultValue -Name 'CachePath' -Value (Join-Path $PSScriptRoot 'XKCD.json')),

        # Returns each comic object exactly as cached, without the 'date', 'html_img' or 'html' properties
        # Get-XKCDCache normally adds, and without the 'XKCD.Comic' type name that drives its table/list
        # formatting.
        [switch]
        $Raw
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
        $Comics = $AllComics

        if ($Number) {
            $Comics = $Comics | Where-Object { $_.num -in $Number }
        }
        if ($Year) {
            $Comics = $Comics | Where-Object { [int]$_.year -in $Year }
        }
        if ($Month) {
            $Comics = $Comics | Where-Object { [int]$_.month -in $Month }
        }
        if ($Day) {
            $Comics = $Comics | Where-Object { [int]$_.day -in $Day }
        }

        if ($Raw) {
            $Comics
        }
        else {
            # Select-Object * clones each comic instead of tagging the shared $AllComics object directly --
            # without it, piping in duplicate/overlapping -Number values (e.g. `4,4 | Get-XKCDCache`) would throw
            # on the second Add-Member, since the same cached object would already carry those properties.
            $Comics | Select-Object * | Add-XKCDExtendedProperty
        }
    }
}
