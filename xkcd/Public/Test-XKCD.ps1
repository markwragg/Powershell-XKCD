function Test-XKCD {
    <#
    .SYNOPSIS
        Checks whether any new comics have been published since the last time Test-XKCD was run.

    .DESCRIPTION
        The Test-XKCD cmdlet compares the latest comic number available from the XKCD API against a local
        record of the most recently viewed comic (updated by Show-XKCD and Get-XKCD -Show), and reports
        whether any new comics are available. Test-XKCD only reads this record -- it never updates it.

        By default it writes a friendly message to the console stating how many new comics are available and
        the publish date of the latest one, if that date can be determined. Use -Quiet to suppress this message
        and instead return a boolean. Use -Detailed to return a PSCustomObject describing how many new comics
        are available, alongside the last viewed and latest comic numbers.

    .EXAMPLE
        Test-XKCD

        Writes a friendly message to the console stating how many new comics are available (if any) and the
        publish date of the latest one, where determinable.

    .EXAMPLE
        Test-XKCD -Quiet

        Returns $true if new comics are available since the last check, otherwise $false, without writing a
        message to the console.

    .EXAMPLE
        Test-XKCD -Detailed

        Returns a PSCustomObject detailing whether new comics are available, how many, and the last viewed vs latest comic numbers.

    .EXAMPLE
        if (Test-XKCD -Quiet) { Test-XKCD }

        If new comics are available, this will write a friendly message to the console stating how many new comics are available
        (if any) and the publish date of the latest one, where determinable.

        Add this to your PowerShell profile.ps1 to have it run automatically when you open a new session and prompt you only when new
        comics are available.

    .LINK
        https://xkcd.com/json.html
    #>
    [cmdletbinding()]
    Param(
        # Suppresses the friendly console message and instead returns a boolean.
        [switch]
        $Quiet,

        # Returns a detailed PSCustomObject describing how many new comics are available, instead of a boolean or console message.
        [switch]
        $Detailed,

        # Path to the file that tracks the number of the most recently viewed comic (written by Show-XKCD and
        # Get-XKCD -Show). By default this is within the module path, unless a default has been saved with
        # Set-XKCDDefault -StatePath.
        [string]
        $StatePath = (Get-XKCDDefaultValue -Name 'StatePath' -Value (Join-Path $PSScriptRoot 'XKCD.state.json'))
    )

    $LatestComic = Invoke-RestMethod 'https://xkcd.com/info.0.json'
    $Latest = $LatestComic.num

    $LastViewed = Get-XKCDLastViewedComic -StatePath $StatePath
    if (-not (Test-Path $StatePath)) {
        Write-Verbose "No local record of previously viewed comics found at '$StatePath'. Treating all comics up to #$Latest as new."
    }

    $NewComicCount = [math]::Max(0, $Latest - $LastViewed)
    $HasNewComics = $NewComicCount -gt 0

    if ($Detailed) {
        [pscustomobject]@{
            HasNewComics  = $HasNewComics
            NewComicCount = $NewComicCount
            LastViewed    = $LastViewed
            LatestComic   = $Latest
        }
    }
    elseif ($Quiet) {
        $HasNewComics
    }
    else {
        $LatestDate = $null
        if ($LatestComic.year -and $LatestComic.month -and $LatestComic.day) {
            try {
                $LatestDate = Get-Date -Year ([int]$LatestComic.year) -Month ([int]$LatestComic.month) -Day ([int]$LatestComic.day) -ErrorAction Stop
            }
            catch {
                $LatestDate = $null
            }
        }
        $DateText = if ($LatestDate) { ", published $($LatestDate.ToString('d MMMM yyyy'))" } else { '' }

        if ($HasNewComics) {
            $ComicWord = if ($NewComicCount -eq 1) { 'comic' } else { 'comics' }
            "$NewComicCount new XKCD $ComicWord available! The latest is #$Latest$DateText."
        }
        else {
            "No new XKCD comics available. You're up to date with #$Latest$DateText."
        }
    }
}
