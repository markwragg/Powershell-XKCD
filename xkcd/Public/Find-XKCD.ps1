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

        The query used is appended to the resulting comic objects as a NoteProperty called 'query'.
        This allows you to group or filter the results by the search term.

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

    .LINK
        https://xkcd.com/json.html
    #>
    [cmdletbinding()]
    Param(
        # The search string to find
        [Parameter(Mandatory, Position = 0, ValueFromPipeline = $true)]
        [string]
        $Query,

        # Search the full text of the comic data, not just the title. Defaults to the value saved with
        # Set-XKCDDefault -FullSearch, if any.
        [switch]
        $FullSearch = (Get-XKCDDefaultValue -Name 'FullSearch' -Value $false),

        # Path to where comic data is cached. By default this is within the module path, unless a default has
        # been saved with Set-XKCDDefault -CachePath.
        [string]
        $CachePath = (Get-XKCDDefaultValue -Name 'CachePath' -Value (Join-Path $PSScriptRoot 'XKCD.json'))
    )
    begin {
        # Ensure the cache is up to date
        Update-XKCDCache -CachePath $CachePath
        $AllComics = Get-Content $CachePath | ConvertFrom-Json
    }
    process {
        if ($FullSearch) {
            $FullText = $_ | Out-String
            $AllComics | ForEach-Object {
                $FullText = $_ | Out-String
                $_ | Where-Object { $FullText -like "*$Query*"} | Add-Member NoteProperty -Name 'query' -Value $Query -PassThru
            }
        } else {
            $AllComics | Where-Object { $_.Title -like "*$Query*" } | Add-Member NoteProperty -Name 'query' -Value $Query -PassThru
        }
    }
}


