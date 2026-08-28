Function Show-XKCDExplanation {
    <#
    .SYNOPSIS
        Displays a comic's title, image, and explanation in the console.

    .DESCRIPTION
        The Show-XKCDExplanation cmdlet gets a comic's explanation from the explain xkcd wiki (via
        Get-XKCDExplanation) and displays it in the console: the title above, the image (if your terminal
        supports the Sixel, Kitty, or iTerm2 inline image graphics protocol), and the retrieved sections below.

        Use -Transcript and/or -Discussion to also display the comic's transcript and reader discussion, or
        -Full to display all three. When more than one section is displayed, each is shown under its own
        heading.

        By default, Show-XKCDExplanation displays the explanation of the latest available comic. When you use
        the -Num parameter you can specify one or more specific comics to display.

    .EXAMPLE
        Show-XKCDExplanation

        Displays the explanation of the latest comic.

    .EXAMPLE
        Show-XKCDExplanation 2000

        Displays the explanation of comic number 2000.

    .EXAMPLE
        Get-XKCD -Random | Show-XKCDExplanation

        Gets a random comic and displays its explanation in the console.

    .EXAMPLE
        Show-XKCDExplanation 2000 -Full

        Displays the explanation, transcript, and reader discussion of comic number 2000, each under its own heading.

    .EXAMPLE
        Get-XKCDExplanation -Show

        Shorthand equivalent of: Get-XKCDExplanation | Show-XKCDExplanation

    .LINK
        https://www.explainxkcd.com/wiki/index.php/Main_Page
    #>
    [cmdletbinding()]
    Param(
        # Displays the explanation of the specified comics. Accepts array input. By default the latest comic is displayed.
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [int[]]
        $Num,

        # Also displays the comic's "Transcript" section. Defaults to the value saved with
        # Set-XKCDDefault -Transcript, if any.
        [switch]
        $Transcript = (Get-XKCDDefaultValue -Name 'Transcript' -Value $false),

        # Also displays the comic's reader "Discussion", from its explain xkcd talk page. Defaults to the value
        # saved with Set-XKCDDefault -Discussion, if any.
        [switch]
        $Discussion = (Get-XKCDDefaultValue -Name 'Discussion' -Value $false),

        # Displays all of the explanation, transcript, and discussion sections. Defaults to the value saved
        # with Set-XKCDDefault -Full, if any.
        [switch]
        $Full = (Get-XKCDDefaultValue -Name 'Full' -Value $false),

        # Displays the higher resolution (_2x) version of the image, where available. Comics that do not have a
        # higher resolution version are displayed at the standard quality instead. Defaults to the value saved
        # with Set-XKCDDefault -HighQuality, if any.
        [switch]
        $HighQuality = (Get-XKCDDefaultValue -Name 'HighQuality' -Value $false)
    )

    Begin {
        if (-not $Num) { $Num = (Invoke-RestMethod 'https://xkcd.com/info.0.json').num }
    }

    Process {
        $Num | ForEach-Object {
            $Explanation = Get-XKCDExplanation -Num $_
            if (-not $Explanation) { return }

            $DisplayProperties = 'Num', 'Title', 'Url', 'Explanation'
            if ($Transcript -or $Full) { $DisplayProperties += 'Transcript' }
            if ($Discussion -or $Full) { $DisplayProperties += 'Discussion' }
            $Explanation = $Explanation | Select-Object $DisplayProperties

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

            Show-XKCDExplanationText -Explanation $Explanation -Comic $Comic -ImageBytes $ImageBytes
        }
    }
}
