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
        - P or the left arrow displays the previous comic (does nothing at comic #1). Shift+Left jumps back
          10 comics at a time instead (clamped to comic #1).
        - R displays a random comic from the full archive.
        - N or the right arrow displays the next comic (does nothing once you reach the latest comic).
          Shift+Right jumps ahead 10 comics at a time instead (clamped to the latest comic).
        - L displays the latest comic.
        - Q or Escape exits back to your normal console.

        The image is only rendered if your terminal supports the Sixel, Kitty, or iTerm2 inline image graphics
        protocol; otherwise you'll still see the rest and can keep browsing. As with Show-XKCD, each comic you
        view updates the local state file also used by Get-XKCD/Show-XKCD's -Next/-Previous and by Test-XKCD,
        so stepping out of Start-XKCD leaves you exactly where Show-XKCD -Next would pick back up.

        By default, Start-XKCD opens on the latest available comic. Use -Number to open on a specific comic
        instead (accepts pipeline input, e.g. from Get-XKCD), -Random to open on a random comic -- optionally
        bounded by -Minimum/-Maximum (aliased -Min/-Max) -- or -Resume to open on whichever comic you last read,
        as recorded in the state file (falls back to the latest comic if the state file has no record yet).

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
        Start-XKCD -Random

        Opens the interactive viewer on a random comic from the full archive.

    .EXAMPLE
        Start-XKCD -Random -Minimum 100 -Maximum 150

        Opens the interactive viewer on a random comic numbered between 100 and 150.

    .EXAMPLE
        Get-XKCD -Random | Start-XKCD

        Opens the interactive viewer on a random comic retrieved via Get-XKCD, passed in via the pipeline.

    .EXAMPLE
        Start-XKCD -HighQuality

        Opens the interactive viewer, rendering the higher resolution (_2x) version of each comic's image
        where available.

    .EXAMPLE
        Start-XKCD -Offline

        Opens the interactive viewer using the local cache and previously downloaded images, instead of
        fetching either from the xkcd API.

    .EXAMPLE
        Start-XKCD -Resume

        Opens the interactive viewer on whichever comic you last read, as recorded in the state file.

    .LINK
        https://github.com/markwragg/Powershell-XKCD/wiki/Start-XKCD

    .LINK
        https://xkcd.com/json.html
    #>
    [cmdletbinding(SupportsShouldProcess, DefaultParameterSetName = 'Specific')]
    Param(
        # Opens the interactive viewer on the specified comic. By default it opens on the latest comic. Accepts
        # pipeline input, e.g. from Get-XKCD.
        [Parameter(ParameterSetName = 'Specific', Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Num')]
        [int]
        $Number,

        # Opens the interactive viewer on a random comic from the full archive, optionally bounded by
        # -Minimum/-Maximum.
        [Parameter(ParameterSetName = 'Random', Mandatory)]
        [switch]
        $Random,

        # Opens the interactive viewer on whichever comic you last read, as recorded in the state file (the
        # same record used by Get-XKCD/Show-XKCD's -Next/-Previous and by Test-XKCD). Falls back to the latest
        # comic if the state file has no record yet.
        [Parameter(ParameterSetName = 'Resume', Mandatory)]
        [switch]
        $Resume,

        # Use with -Random to define a lower bound within which to pick a comic. Defaults to 1.
        [Parameter(ParameterSetName = 'Random')]
        [Alias('Min')]
        [int]
        $Minimum = 1,

        # Use with -Random to define an upper bound within which to pick a comic. Defaults to the latest comic
        # number (or the latest cached comic number, with -Offline).
        [Parameter(ParameterSetName = 'Random')]
        [Alias('Max')]
        [int]
        $Maximum,

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

    Begin {
        $Latest = if ($Offline) {
            (Get-XKCDOfflineComic -CachePath $CachePath | Sort-Object num -Descending | Select-Object -First 1).num
        }
        else {
            (Invoke-RestMethod 'https://xkcd.com/info.0.json').num
        }

        $Width = 80
        try {
            if ([Console]::WindowWidth -gt 0) { $Width = [Console]::WindowWidth }
        }
        catch {
            Write-Verbose 'No console window available (e.g. output redirected), falling back to the default width'
        }

        # Caches each comic's rendered terminal image for the rest of this session, so revisiting one (e.g.
        # via P/N) skips re-rendering it -- which for Sixel in particular can take a while.
        $ImageCache = @{}
    }

    Process {
        $Current = if ($Random) {
            $RandomMaximum = if ($Maximum) { $Maximum } else { $Latest }
            Get-Random -Minimum $Minimum -Maximum ($RandomMaximum + 1)
        }
        elseif ($Resume) {
            $LastRead = Get-XKCDLastReadComic -StatePath $StatePath
            if ($LastRead -gt 0) { $LastRead } else { $Latest }
        }
        elseif ($Number) { $Number }
        else { $Latest }

        $NeedsRedraw = $true
        $BoundaryMessage = $null
        $ComicPromptMessageShown = $false

        try {
            [Console]::CursorVisible = $false
        }
        catch {
            Write-Verbose 'Unable to hide the console cursor (e.g. output redirected); continuing with it shown.'
        }

        try {
            while ($true) {
                if ($NeedsRedraw) {
                    $Comic = Get-XKCD -Num $Current -NoStateUpdate -Offline:$Offline -CachePath $CachePath
                    if (-not $Comic) { return }

                    $ImageBytes = if ($Offline) {
                        Get-XKCDOfflineImageContent -Comic $Comic -Path $DownloadPath -WarningVariable ImageWarning -WarningAction SilentlyContinue
                    }
                    else {
                        Get-XKCDComicImageContent -Comic $Comic -HighQuality:$HighQuality -WarningVariable ImageWarning -WarningAction SilentlyContinue
                    }

                    Show-XKCDTuiFrame -Comic $Comic -ImageBytes $ImageBytes -HighQuality:$HighQuality -Width $Width -Warning ($ImageWarning | Select-Object -Last 1) -Cache $ImageCache

                    if ($PSCmdlet.ShouldProcess($StatePath, "Track comic #$Current as the one most recently viewed")) {
                        Update-XKCDLastReadState -Num $Current -StatePath $StatePath -Cmdlet $PSCmdlet
                    }

                    $NeedsRedraw = $false
                }
                elseif ($BoundaryMessage) {
                    Write-XKCDCenteredLine -InPlace -Width $Width -Text "$([char]27)[33m$BoundaryMessage$([char]27)[0m"
                }

                $Key = Read-XKCDConsoleKey
                $MoveUpForPrompt = $ComicPromptMessageShown
                $BoundaryMessage = $null
                $ComicPromptMessageShown = $false

                if ($Key.KeyChar -eq '`') {
                    $Jump = Show-XKCDAdminConsole -CachePath $CachePath
                    if ($Jump) { $Current = $Jump }
                    $NeedsRedraw = $true
                }
                else {
                    # Shift+Left/Right jumps 10 comics at a time instead of 1. Scoped to the arrow keys
                    # specifically (rather than just checking the Shift modifier) because P/N share this same
                    # switch arm, and a terminal reports typing an upper-case "P" the same way: ConsoleKey.P
                    # with the Shift modifier set -- without this, that would wrongly jump 10 instead of 1.
                    $Step = if (($Key.Key -in 'LeftArrow', 'RightArrow') -and ($Key.Modifiers -band [System.ConsoleModifiers]::Shift)) { 10 } else { 1 }

                    switch ($Key.Key) {
                        { $_ -in 'LeftArrow', 'P' } {
                            if ($Current -gt 1) { $Current = [Math]::Max(1, $Current - $Step); $NeedsRedraw = $true }
                            else { $BoundaryMessage = "You're already viewing the first comic." }
                        }
                        { $_ -in 'RightArrow', 'N' } {
                            if ($Current -lt $Latest) { $Current = [Math]::Min($Latest, $Current + $Step); $NeedsRedraw = $true }
                            else { $BoundaryMessage = "You're already viewing the latest comic." }
                        }
                        'R' { $Current = Get-Random -Minimum 1 -Maximum ($Latest + 1); $NeedsRedraw = $true }
                        'F' {
                            if ($Current -ne 1) { $Current = 1; $NeedsRedraw = $true }
                            else { $BoundaryMessage = "You're already viewing the first comic." }
                        }
                        'L' {
                            if ($Current -ne $Latest) { $Current = $Latest; $NeedsRedraw = $true }
                            else { $BoundaryMessage = "You're already viewing the latest comic." }
                        }
                        'G' {
                            $Requested = Read-XKCDComicNumberPrompt -Latest $Latest -Width $Width -MoveUp:$MoveUpForPrompt
                            if (-not $Requested) {
                                $BoundaryMessage = "That's not a valid comic number."
                                $ComicPromptMessageShown = $true
                            }
                            else {
                                $RequestedComic = $null
                                try {
                                    $RequestedComic = Get-XKCD -Num $Requested -NoStateUpdate -Offline:$Offline -CachePath $CachePath -WarningAction SilentlyContinue
                                }
                                catch {
                                    $RequestedComic = $null
                                }

                                if ($RequestedComic) {
                                    $Current = $Requested
                                    $NeedsRedraw = $true
                                }
                                else {
                                    $BoundaryMessage = "Comic #$Requested doesn't exist."
                                    $ComicPromptMessageShown = $true
                                }
                            }
                        }
                        { $_ -in 'Q', 'Escape' } { return }
                    }
                }
            }
        }
        finally {
            try {
                [Console]::CursorVisible = $true
            }
            catch {
                Write-Verbose 'Unable to restore the console cursor (e.g. output redirected).'
            }
        }
    }
}
