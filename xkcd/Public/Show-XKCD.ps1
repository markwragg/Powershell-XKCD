Function Show-XKCD {
    <#
    .SYNOPSIS
        Displays a comic's title, image, and alt text in the console.

    .DESCRIPTION
        The Show-XKCD cmdlet gets and displays a comic in the console: the title above, the image (if your
        terminal supports the Sixel, Kitty, or iTerm2 inline image graphics protocol), and the alt text below.

        By default, Show-XKCD displays the latest available comic. When you use the -Num parameter you can
        specify one or more specific comics to display.

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

    .LINK
        https://xkcd.com/json.html
    #>
    [cmdletbinding()]
    Param(
        # Displays the specified comics. Accepts array input. By default the latest comic is displayed.
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [int[]]
        $Num,

        # Displays the higher resolution (_2x) version of the image, where available. Comics that do not have a
        # higher resolution version are displayed at the standard quality instead.
        [switch]
        $HighQuality
    )

    Begin {
        if (-not $Num) { $Num = (Invoke-RestMethod 'http://xkcd.com/info.0.json').num }
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
        }
    }
}
