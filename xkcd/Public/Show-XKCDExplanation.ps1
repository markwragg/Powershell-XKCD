Function Show-XKCDExplanation {
    <#
    .SYNOPSIS
        Displays a comic's title, image, and explanation in the console.

    .DESCRIPTION
        The Show-XKCDExplanation cmdlet gets a comic's explanation from the explain xkcd wiki (via
        Get-XKCDExplanation) and displays it in the console: the title above, the image (if your terminal
        supports the Sixel, Kitty, or iTerm2 inline image graphics protocol), and the retrieved sections below.

        By default, only the explanation is displayed. Use -Explanation, -Transcript, and/or -Discussion to
        choose exactly which section(s) to display instead -- e.g. -Transcript on its own displays just the
        transcript, not the explanation -- or use -Full to always display all three. Each displayed section is
        shown under its own heading.

        By default, Show-XKCDExplanation also displays the comic itself (its title, image, and alt text) above
        the section(s) shown. Use -Explanation, -Transcript, and/or -Discussion (without -Full) to display text
        sections only, without fetching or showing the comic image -- the title and a link to the explanation
        are still shown. Use -Full to always display the comic image alongside every section.

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

        Displays the comic image, explanation, transcript, and reader discussion of comic number 2000, each
        under its own heading.

    .EXAMPLE
        Show-XKCDExplanation 2000 -Explanation

        Displays just the explanation of comic number 2000 as text, along with its title and a link, without
        fetching or displaying the comic image.

    .EXAMPLE
        Show-XKCDExplanation 2000 -Discussion

        Displays just the reader discussion of comic number 2000 as text, along with its title and a link,
        without fetching or displaying the comic image or the explanation.

    .EXAMPLE
        Show-XKCDExplanation 2000 -Explanation -Discussion

        Displays the explanation and reader discussion (but not the transcript) of comic number 2000 as text,
        along with its title and a link, without fetching or displaying the comic image.

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

        # Displays the comic's "Explanation" section. Combine with -Transcript and/or -Discussion to display more
        # than one section; on its own (without -Full), no comic image is fetched or displayed -- the title and
        # a link to the explanation are still shown. Defaults to the value saved with Set-XKCDDefault
        # -Explanation, if any.
        [switch]
        $Explanation = (Get-XKCDDefaultValue -Name 'Explanation' -Value $false),

        # Displays the comic's "Transcript" section. Combine with -Explanation and/or -Discussion to display more
        # than one section; on its own (without -Full), no comic image is fetched or displayed. Defaults to the
        # value saved with Set-XKCDDefault -Transcript, if any.
        [switch]
        $Transcript = (Get-XKCDDefaultValue -Name 'Transcript' -Value $false),

        # Displays the comic's reader "Discussion", from its explain xkcd talk page. Combine with -Explanation
        # and/or -Transcript to display more than one section; on its own (without -Full), no comic image is
        # fetched or displayed. Defaults to the value saved with Set-XKCDDefault -Discussion, if any.
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
            $ExplanationResult = Get-XKCDExplanation -Num $_
            if (-not $ExplanationResult) { return }

            # -Explanation, -Transcript, and -Discussion request text sections only, skipping the comic image
            # (title and link are still shown); -Full always brings the comic image back alongside every section.
            $ShowComic = $Full -or (-not $Explanation -and -not $Transcript -and -not $Discussion)

            # With no section switches at all, default to just the explanation; otherwise display exactly the
            # sections that were asked for (which may be just -Transcript, just -Discussion, or any combination),
            # unless -Full is set, which always displays all three.
            $AnySectionRequested = $Explanation -or $Transcript -or $Discussion -or $Full

            $DisplayProperties = 'Num', 'Title', 'Url'
            if ($Full -or $Explanation -or -not $AnySectionRequested) { $DisplayProperties += 'Explanation' }
            if ($Full -or $Transcript) { $DisplayProperties += 'Transcript' }
            if ($Full -or $Discussion) { $DisplayProperties += 'Discussion' }
            $ExplanationResult = $ExplanationResult | Select-Object $DisplayProperties

            $Comic = $null
            $ImageBytes = $null

            if ($ShowComic) {
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
            }

            Show-XKCDExplanationText -Explanation $ExplanationResult -Comic $Comic -ImageBytes $ImageBytes
        }
    }
}
