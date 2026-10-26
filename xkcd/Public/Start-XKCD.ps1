function Start-XKCD {
    <#
    .SYNOPSIS
        Opens a full-screen terminal interface for browsing XKCD comics -- a TUI parody of https://xkcd.com/.

    .DESCRIPTION
        The Start-XKCD cmdlet opens an interactive, full-screen view of a comic (its title, image, and alt
        text, framed by an ASCII art "xkcd" banner, with a control bar shown both above and below the image)
        and lets you browse the archive without leaving it:

        - G prompts for a comic number to jump straight to.
        - F displays the first comic (#1).
        - P or the left arrow displays the previous comic (does nothing at comic #1).
        - R displays a random comic from the full archive.
        - N or the right arrow displays the next comic (does nothing once you reach the latest comic).
        - L displays the latest comic.
        - Q or Escape exits back to your normal console.

        The image is only rendered if your terminal supports the Sixel, Kitty, or iTerm2 inline image graphics
        protocol; otherwise you'll still see the rest and can keep browsing. As with Show-XKCD, each comic you
        view updates the local state file also used by Get-XKCD/Show-XKCD's -Next/-Previous and by Test-XKCD,
        so stepping out of Start-XKCD leaves you exactly where Show-XKCD -Next would pick back up.

        By default, Start-XKCD opens on the latest available comic. Use -Number to open on a specific comic
        instead.

        Use -Offline to browse using data from the local cache (created/refreshed by Update-XKCDCache) and
        images previously saved with Get-XKCD -Download, instead of fetching either from the xkcd API -- this
        also governs which comic counts as "latest" for the default starting comic, the right arrow boundary,
        and R. If a comic's image hasn't been downloaded to -DownloadPath yet, a warning is shown and that
        comic's frame is displayed without an image, rather than stopping you from continuing to browse.
        Defaults to the value saved with Set-XKCDDefault -Offline, if any.

    .EXAMPLE
        Start-XKCD

        Opens the interactive viewer on the latest comic.

    .EXAMPLE
        Start-XKCD 2000

        Opens the interactive viewer on comic number 2000.

    .EXAMPLE
        Start-XKCD -HighQuality

        Opens the interactive viewer, rendering the higher resolution (_2x) version of each comic's image
        where available.

    .EXAMPLE
        Start-XKCD -Offline

        Opens the interactive viewer using the local cache and previously downloaded images, instead of
        fetching either from the xkcd API.

    .LINK
        https://github.com/markwragg/Powershell-XKCD/wiki/Start-XKCD

    .LINK
        https://xkcd.com/json.html
    #>
    [cmdletbinding(SupportsShouldProcess)]
    Param(
        # Opens the interactive viewer on the specified comic. By default it opens on the latest comic.
        [Parameter(Position = 0)]
        [Alias('Num')]
        [int]
        $Number,

        # Renders the higher resolution (_2x) version of each comic's image, where available. Comics that do
        # not have a higher resolution version are rendered at the standard quality instead. Defaults to the
        # value saved with Set-XKCDDefault -HighQuality, if any.
        [switch]
        $HighQuality = (Get-XKCDDefaultValue -Name 'HighQuality' -Value $false),

        # Path to the file used to track the number of the most recently viewed comic (used by Test-XKCD and
        # by Get-XKCD/Show-XKCD's -Next/-Previous). By default this is in the user's per-user data directory
        # (~/.xkcd), unless a default has been saved with Set-XKCDDefault -StatePath.
        [string]
        $StatePath = (Get-XKCDDefaultValue -Name 'StatePath' -Value (Get-XKCDUserDataPath -FileName 'XKCD.state.json' -LegacyDirectory $PSScriptRoot)),

        # Browses comic data from the local cache, and renders each comic's image from a copy previously
        # saved with Get-XKCD -Download, instead of fetching either from the xkcd API. Shows a warning and
        # displays the comic without an image if it hasn't been downloaded to -DownloadPath yet. Defaults to
        # the value saved with Set-XKCDDefault -Offline, if any.
        [switch]
        $Offline = (Get-XKCDDefaultValue -Name 'Offline' -Value $false),

        # Use with -Offline to specify where comic data is cached. By default this is within the module path,
        # unless a default has been saved with Set-XKCDDefault -CachePath.
        [string]
        $CachePath = (Get-XKCDDefaultValue -Name 'CachePath' -Value (Join-Path $PSScriptRoot 'XKCD.json')),

        # Use with -Offline to specify the local directory to look for previously downloaded comic images in
        # (as saved by Get-XKCD -Download). By default this is the current working directory, unless a
        # default has been saved with Set-XKCDDefault -Path.
        [string]
        $DownloadPath = (Get-XKCDDefaultValue -Name 'Path' -Value $PWD)
    )

    $Latest = if ($Offline) {
        (Get-XKCDOfflineComic -CachePath $CachePath | Sort-Object num -Descending | Select-Object -First 1).num
    }
    else {
        (Invoke-RestMethod 'https://xkcd.com/info.0.json').num
    }

    $Current = if ($Number) { $Number } else { $Latest }

    $Width = 80
    try {
        if ([Console]::WindowWidth -gt 0) { $Width = [Console]::WindowWidth }
    }
    catch {
        Write-Verbose 'No console window available (e.g. output redirected), falling back to the default width'
    }

    while ($true) {
        $Comic = Get-XKCD -Num $Current -NoStateUpdate -Offline:$Offline -CachePath $CachePath
        if (-not $Comic) { return }

        $ImageBytes = if ($Offline) {
            Get-XKCDOfflineImageContent -Comic $Comic -Path $DownloadPath
        }
        else {
            Get-XKCDComicImageContent -Comic $Comic -HighQuality:$HighQuality
        }

        Show-XKCDTuiFrame -Comic $Comic -ImageBytes $ImageBytes -HighQuality:$HighQuality -Width $Width

        Update-XKCDLastReadState -Num $Current -StatePath $StatePath -Cmdlet $PSCmdlet

        $Key = Read-XKCDConsoleKey

        switch ($Key.Key) {
            { $_ -in 'LeftArrow', 'P' } { if ($Current -gt 1) { $Current-- } }
            { $_ -in 'RightArrow', 'N' } { if ($Current -lt $Latest) { $Current++ } }
            'R' { $Current = Get-Random -Minimum 1 -Maximum ($Latest + 1) }
            'F' { $Current = 1 }
            'L' { $Current = $Latest }
            'G' {
                $Requested = Read-XKCDComicNumberPrompt -Latest $Latest
                if ($Requested) { $Current = $Requested }
            }
            { $_ -in 'Q', 'Escape' } { return }
        }
    }
}
