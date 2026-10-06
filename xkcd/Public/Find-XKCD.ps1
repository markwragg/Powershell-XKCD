function Find-XKCD {
    <#
    .SYNOPSIS
        Retrieves the details of comics @ https://xkcd.com/ based on whether a specified search string appears
        in the title text (by default). To search for a specified string in the full text of the comic data,
        use the -FullSearch switch.

    .DESCRIPTION
        The Find-XKCD cmdlet creates a local cache of the XKCD API comic data if one is not found to already
        exist. It also refreshes the local cache if it's found to be out of date. Comic searches are then
        performed against the local cache.

        -Query accepts more than one search string. A comic matches if it contains ANY of them, or any of the
        -Or terms (-Query and -Or are simply two ways of building the same "match any of these" group -- -Or
        exists so you can add alternatives without crowding the primary -Query list). If -And is also given, a
        comic must additionally contain ALL of those terms to match. If -Not is also given, a comic must
        additionally contain NONE of those terms to match, e.g. `Find-XKCD -Query 'Spider' -Not 'Man'` returns
        comics with 'Spider' in the title, excluding any that also have 'Man' in it.

        Each resulting comic object is tagged with a NoteProperty called 'query' -- specifically, every term
        that was actually part of why that comic matched: whichever -Query/-Or term(s) it matched (joined with
        ', ' if more than one), plus any -And terms (since all of those are required to be present, they're
        always part of the reason it matched too). -Not terms are never included, since they describe what must
        be absent, not why a comic matched.

        -Year, -Month and -Day further restrict matches to comics published in the given year(s), month(s)
        (1-12) and/or day(s) of the month -- a comic must match one of each that's specified, alongside the
        text search above, e.g. `Find-XKCD -Query 'Spider' -Year 2010,2011` returns comics with 'Spider' in
        the title published in 2010 or 2011.

        Each returned comic also has a 'date' property (a [datetime] combining day/month/year, so results can be
        sorted or filtered by date), and 'html_img'/'html' properties, computed from those properties, for
        embedding the comic in HTML output -- 'html_img' is just the <img> tag, and 'html' wraps that same tag in
        a link to the comic's page on xkcd.com. Use -Raw to omit these and get each comic exactly as cached
        (still tagged with 'query').

    .EXAMPLE
        Find-XKCD -Query 'Spider' | Format-Table

        Returns any comics with the word 'Spider' in the title as a table.

    .EXAMPLE
        Find-XKCD -Query 'Spider' | Get-XKCD -Open

        Returns any comics with the word 'Spider' in the title and then pipes the result to Get-XKCD which opens
        them in the default browser.

    .EXAMPLE
        Find-XKCD -Query 'Spider' | Get-XKCD -Show

        Returns any comics with the word 'Spider' in the title and then pipes the result to Get-XKCD which shows
        them in the terminal, if supported.

    .EXAMPLE
        'romance','math' | Find-XKCD | Group query

        Returns any comics with the word 'romance' or 'math' in the title and then groups the results by the search term.

    .EXAMPLE
        Find-XKCD -Query 'Spider','Robot'

        Returns any comics with the word 'Spider' OR 'Robot' in the title, in a single combined result set, each
        tagged with whichever of the two it actually matched. Piping the terms in separately instead
        (`'Spider','Robot' | Find-XKCD`) returns the same comics tagged the same way, except a comic matching
        both terms would appear twice (once per piped query) rather than once with 'query' set to 'Spider, Robot'.

    .EXAMPLE
        Find-XKCD -Query 'Time' -And 'Machine'

        Returns any comics with both 'Time' AND 'Machine' in the title, each tagged with 'query' set to
        'Time, Machine'.

    .EXAMPLE
        Find-XKCD -Query 'Spider' -Not 'Man'

        Returns comics with 'Spider' in the title, excluding any that also have 'Man' in it.

    .EXAMPLE
        Find-XKCD -Query 'Spider' -Not 'Man','Egg'

        Returns comics with 'Spider' in the title, excluding any that also have 'Man' OR 'Egg' in it.

    .EXAMPLE
        Find-XKCD -Query 'Spider' -Raw

        Returns each matching comic exactly as cached, without the 'date', 'html_img' or 'html' properties
        Find-XKCD normally adds (the 'query' property is still added).

    .EXAMPLE
        Find-XKCD -Query 'Spider' -Year 2010

        Returns comics with 'Spider' in the title that were published in 2010.

    .EXAMPLE
        Find-XKCD -Query 'Spider' -Month 10 -Day 31

        Returns comics with 'Spider' in the title that were published on October 31st of any year.

    .LINK
        https://github.com/markwragg/Powershell-XKCD/wiki/Find-XKCD

    .LINK
        https://xkcd.com/json.html
    #>
    [cmdletbinding()]
    Param(
        # The search string(s) to find. A comic matches if it contains any of these (or any of -Or).
        [Parameter(Mandatory, Position = 0, ValueFromPipeline = $true)]
        [string[]]
        $Query,

        # Additional search string(s) to match, alongside -Query -- a comic matches if it contains any of
        # -Query OR any of these.
        [string[]]
        $Or,

        # Search string(s) that must ALL also be present for a comic to match, alongside -Query/-Or.
        [string[]]
        $And,

        # Search string(s) that must NONE be present for a comic to match, alongside -Query/-Or/-And.
        [string[]]
        $Not,

        # Restricts matches to comics published in the specified year(s), alongside the text search.
        [int[]]
        $Year,

        # Restricts matches to comics published in the specified month(s) (1-12), alongside the text search.
        [ValidateRange(1, 12)]
        [int[]]
        $Month,

        # Restricts matches to comics published on the specified day(s) of the month, alongside the text search.
        [ValidateRange(1, 31)]
        [int[]]
        $Day,

        # Search the full text of the comic data, not just the title. Defaults to the value saved with
        # Set-XKCDDefault -FullSearch, if any.
        [switch]
        $FullSearch = (Get-XKCDDefaultValue -Name 'FullSearch' -Value $false),

        # Returns each matching comic object exactly as cached, without the 'date', 'html_img' or 'html'
        # properties Find-XKCD normally adds, and without the 'XKCD.Comic'/'XKCD.Comic.Search' type names that
        # drive its table/list formatting. The 'query' property is still added.
        [switch]
        $Raw,

        # Path to where comic data is cached. By default this is within the module path, unless a default has
        # been saved with Set-XKCDDefault -CachePath.
        [string]
        $CachePath = (Get-XKCDDefaultValue -Name 'CachePath' -Value (Join-Path $PSScriptRoot 'XKCD.json')),

        # Skips the Update-XKCDCache step, searching the cache as it currently exists on disk. Useful to avoid
        # the overhead of checking for new comics when you know the cache is already up to date. Defaults to
        # the value saved with Set-XKCDDefault -SkipCacheRefresh, if any.
        [switch]
        $SkipCacheRefresh = (Get-XKCDDefaultValue -Name 'SkipCacheRefresh' -Value $false)
    )
    begin {
        # Ensure the cache is up to date
        if (-not $SkipCacheRefresh) {
            Update-XKCDCache -CachePath $CachePath
        }
        $AllComics = Get-Content $CachePath | ConvertFrom-Json
    }
    process {
        # Filters out the trailing $null that @(...) + @(...) leaves behind when -Or isn't passed (@($null) is
        # a one-element array, not an empty one) -- a $null term would otherwise become the always-matching
        # wildcard pattern "*$null*" = "**".
        $OrTerms = (@($Query) + @($Or)) | Where-Object { $_ }
        $AndTerms = @($And) | Where-Object { $_ }
        $NotTerms = @($Not) | Where-Object { $_ }

        $AllComics | ForEach-Object {
            $Text = if ($FullSearch) { $_ | Out-String } else { $_.title }

            # The specific -Query/-Or term(s) this comic actually matched, not just whatever was passed in --
            # e.g. with -Query 'romance','math', a comic matching only 'math' gets tagged 'math', not
            # 'romance, math'.
            $MatchedTerms = @($OrTerms | Where-Object { $Text -like "*$_*" })
            $MatchesAny = $MatchedTerms.Count -gt 0
            $MatchesAll = @($AndTerms | Where-Object { $Text -notlike "*$_*" }).Count -eq 0
            $MatchesNone = @($NotTerms | Where-Object { $Text -like "*$_*" }).Count -eq 0
            $MatchesYear = -not $Year -or ([int]$_.year -in $Year)
            $MatchesMonth = -not $Month -or ([int]$_.month -in $Month)
            $MatchesDay = -not $Day -or ([int]$_.day -in $Day)

            if ($MatchesAny -and $MatchesAll -and $MatchesNone -and $MatchesYear -and $MatchesMonth -and $MatchesDay) {
                # 'query' is every term that was actually part of why this comic matched -- the -Query/-Or
                # term(s) above, plus $AndTerms (all guaranteed present here, since $MatchesAll is true).
                $Tag = (@($MatchedTerms) + @($AndTerms)) -join ', '

                # Select-Object * clones the comic instead of tagging the shared cache object $AllComics
                # holds directly -- without it, the same comic matching more than one query in a single
                # pipeline run (e.g. 'romance','time' | Find-XKCD, if a comic matches both) would throw on
                # the second Add-Member, since it'd already carry a 'query' member from the first.
                $Result = $_ | Select-Object * | Add-Member NoteProperty -Name 'query' -Value $Tag -PassThru

                if ($Raw) { $Result } else { $Result | Add-XKCDExtendedProperty -TypeName 'XKCD.Comic.Search' }
            }
        }
    }
}
