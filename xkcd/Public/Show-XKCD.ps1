function Show-XKCD {
    <#
    .SYNOPSIS
        Displays a comic's title, image, and alt text in the console.

    .DESCRIPTION
        The Show-XKCD cmdlet gets and displays a comic in the console: the title above, the image (if your
        terminal supports the Sixel, Kitty, or iTerm2 inline image graphics protocol), and the alt text below.

        By default, Show-XKCD displays the latest available comic. When you use the -Number parameter (aliased as
        -Num) you can specify one or more specific comics to display.

        Each displayed comic updates a local state file with two records: the highest-numbered comic you've ever
        viewed, used by Test-XKCD to report how many new comics have been published since you last checked; and
        the comic you most recently displayed in either direction, used by -Next and -Previous so you can page
        back and forth through comics sequentially. -Next displays nothing once you've reached the latest comic,
        and -Previous displays nothing once you've reached comic #1.

        Use -Path to display a comic from a file previously saved with Export-XKCDTerminalImage instead of
        fetching it from the xkcd API -- useful for redisplaying a comic without needing network access, or for
        a comic whose image was rendered on another machine. The saved image is written to the console as-is
        rather than being re-rendered, so it's only guaranteed to display correctly in a terminal that supports
        the same graphics protocol it was exported with; a warning is shown if that doesn't match the protocol
        detected for the terminal you're displaying it in.

        Use -Offline to display a comic using data from the local cache (created/refreshed by Update-XKCDCache)
        and an image previously saved with Get-XKCD -Download, instead of fetching either from the xkcd API --
        this also governs where -Next/-Previous and the default (no -Number) consider the "latest" comic to
        be. If the comic's image hasn't been downloaded to -DownloadPath yet, a warning is shown asking you to
        use -Download first, and that comic is skipped. Defaults to the value saved with Set-XKCDDefault
        -Offline, if any.

    .EXAMPLE
        Show-XKCD

        Displays the latest comic.

    .EXAMPLE
        Show-XKCD 2000

        Displays comic number 2000.

    .EXAMPLE
        Get-XKCD -Random | Show-XKCD

        Gets a random comic and displays it in the console.

    .EXAMPLE
        Find-XKCD -Query 'Spider' | Get-XKCD | Show-XKCD

        Finds comics with 'Spider' in the title and displays each one in the console.

    .EXAMPLE
        Get-XKCD -Show

        Shorthand equivalent of: Get-XKCD | Show-XKCD

    .EXAMPLE
        Show-XKCD -Next

        Displays the comic after the one you most recently displayed with Show-XKCD or Get-XKCD -Show, as
        recorded in the state file. Displays nothing if you're already at the latest comic.

    .EXAMPLE
        Show-XKCD -Previous

        Displays the comic before the one you most recently displayed with Show-XKCD or Get-XKCD -Show, as
        recorded in the state file. Calling -Previous repeatedly steps back further each time. Displays nothing
        if you're already at comic #1.

    .EXAMPLE
        Show-XKCD -Path .\353.xkcdterm.json

        Displays the comic saved to '.\353.xkcdterm.json' by Export-XKCDTerminalImage, without fetching
        anything from the xkcd API.

    .EXAMPLE
        Export-XKCDTerminalImage -Number 353 -PassThru | Show-XKCD

        Exports comic number 353 and immediately displays it from the saved file.

    .EXAMPLE
        Show-XKCD -Offline

        Displays the latest cached comic, rendering its image from a copy previously saved with
        Get-XKCD -Download, instead of fetching either from the xkcd API.

    .EXAMPLE
        Show-XKCD -Num 353 -Offline -DownloadPath C:\XKCD

        Displays comic number 353 from the local cache, rendering its image from a copy previously saved to
        C:\XKCD with Get-XKCD -Download -Path C:\XKCD. Warns and skips displaying the comic if no copy of its
        image is found there.

    .LINK
        https://github.com/markwragg/Powershell-XKCD/wiki/Show-XKCD

    .LINK
        https://xkcd.com/json.html
    #>
    [cmdletbinding(SupportsShouldProcess, DefaultParameterSetName = 'Specific')]
    Param(
        # Displays the specified comics. Accepts array input. By default the latest comic is displayed.
        [Parameter(ParameterSetName = 'Specific', ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [Alias('Num')]
        [int[]]
        $Number,

        # Displays the comic after the one most recently displayed with Show-XKCD or Get-XKCD -Show, as recorded
        # in the state file. Displays nothing if you're already at the latest comic.
        [Parameter(ParameterSetName = 'Next', Mandatory)]
        [switch]
        $Next,

        # Displays the comic before the one most recently displayed with Show-XKCD or Get-XKCD -Show, as recorded
        # in the state file. Displays nothing if you're already at comic #1.
        [Parameter(ParameterSetName = 'Previous', Mandatory)]
        [switch]
        $Previous,

        # Displays the comic saved in the specified file(s), previously created with Export-XKCDTerminalImage,
        # instead of fetching it from the xkcd API. Accepts array input and FileInfo objects via the pipeline
        # (e.g. from Get-ChildItem or Export-XKCDTerminalImage -PassThru).
        [Parameter(ParameterSetName = 'File', Mandatory, ValueFromPipelineByPropertyName, Position = 0)]
        [Alias('FullName')]
        [string[]]
        $Path,

        # Displays the higher resolution (_2x) version of the image, where available. Comics that do not have a
        # higher resolution version are displayed at the standard quality instead. Defaults to the value saved
        # with Set-XKCDDefault -HighQuality, if any.
        [switch]
        $HighQuality = (Get-XKCDDefaultValue -Name 'HighQuality' -Value $false),

        # Path to the file used to track the number of the most recently viewed comic (used by Test-XKCD). By
        # default this is in the user's per-user data directory (~/.xkcd), unless a default has been saved with
        # Set-XKCDDefault -StatePath.
        [string]
        $StatePath = (Get-XKCDDefaultValue -Name 'StatePath' -Value (Get-XKCDUserDataPath -FileName 'XKCD.state.json' -LegacyDirectory $PSScriptRoot)),

        # Displays comic data from the local cache, and the comic's image from a copy previously saved with
        # Get-XKCD -Download, instead of fetching either from the xkcd API. Warns and skips the comic if its
        # image hasn't been downloaded to -DownloadPath yet. Defaults to the value saved with
        # Set-XKCDDefault -Offline, if any.
        [switch]
        $Offline = (Get-XKCDDefaultValue -Name 'Offline' -Value $false),

        # Use with -Offline to specify where comic data is cached. By default this is within the module path,
        # unless a default has been saved with Set-XKCDDefault -CachePath.
        [string]
        $CachePath = (Get-XKCDDefaultValue -Name 'CachePath' -Value (Join-Path $PSScriptRoot 'XKCD.json')),

        # Use with -Offline to specify the local directory to look for previously downloaded comic images in
        # (as saved by Get-XKCD -Download). By default this is the current working directory, unless a default
        # has been saved with Set-XKCDDefault -Path.
        [string]
        $DownloadPath = (Get-XKCDDefaultValue -Name 'Path' -Value $PWD)
    )

    Begin {
        if ($PSCmdlet.ParameterSetName -eq 'File') { return }

        if ($Next -or (-not $Previous -and -not $Number)) {
            $Latest = if ($Offline) {
                (Get-XKCDOfflineComic -CachePath $CachePath | Sort-Object num -Descending | Select-Object -First 1).num
            }
            else {
                (Invoke-RestMethod 'https://xkcd.com/info.0.json').num
            }
        }

        if ($Next) {
            $NextNum = (Get-XKCDLastReadComic -StatePath $StatePath) + 1
            if ($NextNum -le $Latest) { $Number = $NextNum } else { $Number = @() }
        }
        elseif ($Previous) {
            $LastRead = Get-XKCDLastReadComic -StatePath $StatePath
            if ($LastRead -gt 1) { $Number = $LastRead - 1 } else { $Number = @() }
        }
        elseif (-not $Number) {
            $Number = $Latest
        }
    }

    Process {
        if ($PSCmdlet.ParameterSetName -eq 'File') {
            $Path | ForEach-Object {
                $Saved = Get-XKCDTerminalImageFile -Path $_
                if (-not $Saved) { return }

                $Comic = $Saved | Select-Object * -ExcludeProperty Protocol, Image
                Show-XKCDComic -Comic $Comic -TerminalImage $Saved.Image

                Update-XKCDLastReadState -Num $Comic.num -StatePath $StatePath -Cmdlet $PSCmdlet
            }
            return
        }

        $Number | ForEach-Object {
            $Comic = Get-XKCD -Num $_ -NoStateUpdate -Offline:$Offline -CachePath $CachePath
            if (-not $Comic) { return }

            if ($Offline) {
                $ImageBytes = Get-XKCDOfflineImageContent -Comic $Comic -Path $DownloadPath
                if (-not $ImageBytes) { return }
            }
            else {
                $ImageBytes = Get-XKCDComicImageContent -Comic $Comic -HighQuality:$HighQuality
            }

            Show-XKCDComic -Comic $Comic -ImageBytes $ImageBytes -HighQuality:$HighQuality

            Update-XKCDLastReadState -Num $Comic.num -StatePath $StatePath -Cmdlet $PSCmdlet
        }
    }
}
