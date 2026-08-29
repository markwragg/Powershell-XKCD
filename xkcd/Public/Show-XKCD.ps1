function Show-XKCD {
    <#
    .SYNOPSIS
        Displays a comic's title, image, and alt text in the console.

    .DESCRIPTION
        The Show-XKCD cmdlet gets and displays a comic in the console: the title above, the image (if your
        terminal supports the Sixel, Kitty, or iTerm2 inline image graphics protocol), and the alt text below.

        By default, Show-XKCD displays the latest available comic. When you use the -Num parameter you can
        specify one or more specific comics to display.

        Each displayed comic updates a local state file with two records: the highest-numbered comic you've ever
        viewed, used by Test-XKCD to report how many new comics have been published since you last checked; and
        the comic you most recently displayed in either direction, used by -Next and -Previous so you can page
        back and forth through comics sequentially. -Next displays nothing once you've reached the latest comic,
        and -Previous displays nothing once you've reached comic #1.

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

    .LINK
        https://xkcd.com/json.html
    #>
    [cmdletbinding(SupportsShouldProcess, DefaultParameterSetName = 'Specific')]
    Param(
        # Displays the specified comics. Accepts array input. By default the latest comic is displayed.
        [Parameter(ParameterSetName = 'Specific', ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [int[]]
        $Num,

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

        # Displays the higher resolution (_2x) version of the image, where available. Comics that do not have a
        # higher resolution version are displayed at the standard quality instead. Defaults to the value saved
        # with Set-XKCDDefault -HighQuality, if any.
        [switch]
        $HighQuality = (Get-XKCDDefaultValue -Name 'HighQuality' -Value $false),

        # Path to the file used to track the number of the most recently viewed comic (used by Test-XKCD). By
        # default this is within the module path, unless a default has been saved with Set-XKCDDefault -StatePath.
        [string]
        $StatePath = (Get-XKCDDefaultValue -Name 'StatePath' -Value (Join-Path $PSScriptRoot 'XKCD.state.json'))
    )

    Begin {
        if ($Next) {
            $Latest = (Invoke-RestMethod 'https://xkcd.com/info.0.json').num
            $NextNum = (Get-XKCDLastReadComic -StatePath $StatePath) + 1
            if ($NextNum -le $Latest) { $Num = $NextNum } else { $Num = @() }
        }
        elseif ($Previous) {
            $LastRead = Get-XKCDLastReadComic -StatePath $StatePath
            if ($LastRead -gt 1) { $Num = $LastRead - 1 } else { $Num = @() }
        }
        elseif (-not $Num) {
            $Num = (Invoke-RestMethod 'https://xkcd.com/info.0.json').num
        }
    }

    Process {
        $Num | ForEach-Object {
            $Comic = Get-XKCD -Num $_
            $Extension = [System.IO.Path]::GetExtension(([uri]$Comic.img).AbsolutePath)
            $ImageUrl = $Comic.img

            if ($HighQuality) {
                $ImageUrl = $Comic.img.Insert($Comic.img.LastIndexOf($Extension), '_2x')
            }

            try {
                $ImageBytes = (Invoke-WebRequest $ImageUrl -UseBasicParsing -ErrorAction Stop).Content
            }
            catch {
                if ($HighQuality) {
                    Write-Warning "High quality image not available for comic $($Comic.num), showing standard quality instead"
                    $ImageBytes = (Invoke-WebRequest $Comic.img -UseBasicParsing).Content
                }
                else {
                    throw
                }
            }

            Show-XKCDComic -Comic $Comic -ImageBytes $ImageBytes

            $LastViewedComic = Get-XKCDLastViewedComic -StatePath $StatePath
            $LastReadComic = Get-XKCDLastReadComic -StatePath $StatePath
            $NewLastViewed = [math]::Max($LastViewedComic, $Comic.num)

            if (($Comic.num -ne $LastReadComic -or $NewLastViewed -ne $LastViewedComic) -and
                $PSCmdlet.ShouldProcess($StatePath, "Update last read comic to #$($Comic.num)")) {
                [pscustomobject]@{ LastViewed = $NewLastViewed; LastRead = $Comic.num } | ConvertTo-Json | Out-File $StatePath -Force
            }
        }
    }
}
