Function Find-XKCD {
    <#
    .SYNOPSIS
        Retrieves the details of comics @ http://xkcd.com/ based on whether a specified search string appears
        in the title text.

    .DESCRIPTION
        The Find-XKCD cmdlet creates a local cache of the XKCD API comic data if one is not found to already
        exist. It also refreshes the local cache if it's found to be out of date. Comic searches are then
        performed against the local cache.

    .EXAMPLE
        Find-XKCD -Query 'Spider' | Format-Table

        Returns any comics with the word 'Spider' in the title as a table.
    
    .EXAMPLE
        Find-XKCD -Query 'Spider' | Get-XKCD -Open

        Returns any comics with the word 'Spider' in the title and then pipes the result to Get-XKCD which opens
        them in the default browser.

    .LINK
        https://xkcd.com/json.html
    #>
    [cmdletbinding()]
    Param(
        # The search string to find
        [Parameter(Mandatory)]
        [string]
        $Query,

        # Path to where comic data is cached
        [string]
        $CachePath = (Join-Path $PSScriptRoot 'XKCD.json')
    )
    
    Update-XKCDCache -CachePath $CachePath

    $AllComics = Get-Content $CachePath | ConvertFrom-Json

    $AllComics | Where-Object { $_.Title -like "*$Query*" }
}


