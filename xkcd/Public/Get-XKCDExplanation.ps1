Function Get-XKCDExplanation {
    <#
    .SYNOPSIS
        Gets the explanation of a comic from the explain xkcd wiki: https://www.explainxkcd.com/.

    .DESCRIPTION
        The Get-XKCDExplanation cmdlet uses the explain xkcd wiki's MediaWiki API to retrieve a comic's
        "Explanation" and "Transcript" sections, and its reader "Discussion" (from its explain xkcd talk page),
        returning them as plain text, with the wiki markup used by the site stripped out for readability. All
        three are always included on the returned object, as its Explanation, Transcript, and Discussion
        properties.

        Use -Transcript and/or -Discussion with -Show (or on Show-XKCDExplanation) to also display the
        transcript and discussion alongside the explanation, or -Full to display all three -- each section
        shown is given its own heading. These switches only affect what's displayed; the returned object always
        has all three.

        By default, Get-XKCDExplanation returns the explanation of the latest available comic. When you use the
        -Num parameter you can specify one or more specific comics to return.

    .EXAMPLE
        Get-XKCDExplanation

        This command gets the explanation of the latest XKCD comic.

    .EXAMPLE
        Get-XKCDExplanation 2000

        This command returns the explanation of the 2000th XKCD comic.

    .EXAMPLE
        Get-XKCD -Random | Get-XKCDExplanation

        This command gets a random comic and then returns its explanation.

    .EXAMPLE
        (Get-XKCDExplanation 2000).Transcript

        This command returns just the transcript of comic number 2000. The Explanation, Transcript, and
        Discussion properties are always populated, so no switches are needed to retrieve them.

    .EXAMPLE
        Get-XKCDExplanation -Num 1 -Full -Show

        This command displays the title, image, explanation, transcript, and discussion of comic number 1
        directly in the console, each under its own heading (image display requires your terminal to support
        the Sixel, Kitty, or iTerm2 inline image protocol). Unlike other parameter combinations, -Show does not
        return the explanation object.

    .LINK
        https://www.explainxkcd.com/wiki/index.php/Main_Page
    #>
    [cmdletbinding()]
    Param(
        # Gets the explanation of the specified comics. Accepts array input. By default the latest comic is used.
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [int[]]
        $Num,

        # Use with -Show to also display the comic's "Transcript" section. The returned object always includes
        # it regardless of this switch. Defaults to the value saved with Set-XKCDDefault -Transcript, if any.
        [switch]
        $Transcript = (Get-XKCDDefaultValue -Name 'Transcript' -Value $false),

        # Use with -Show to also display the comic's reader "Discussion", from its explain xkcd talk page. The
        # returned object always includes it regardless of this switch. Defaults to the value saved with
        # Set-XKCDDefault -Discussion, if any.
        [switch]
        $Discussion = (Get-XKCDDefaultValue -Name 'Discussion' -Value $false),

        # Use with -Show to display all of the explanation, transcript, and discussion sections. The returned
        # object always includes all three regardless of this switch. Defaults to the value saved with
        # Set-XKCDDefault -Full, if any.
        [switch]
        $Full = (Get-XKCDDefaultValue -Name 'Full' -Value $false),

        # Displays the comic's title, image, and retrieved sections in the console instead of returning the
        # explanation object. Image display requires your terminal to support the Sixel, Kitty, or iTerm2
        # inline image graphics protocol.
        [switch]
        $Show,

        # Use with -Show to display the higher resolution (_2x) version of the image, where available. Comics
        # that do not have a higher resolution version are displayed at the standard quality instead. Defaults
        # to the value saved with Set-XKCDDefault -HighQuality, if any.
        [switch]
        $HighQuality = (Get-XKCDDefaultValue -Name 'HighQuality' -Value $false),

        # The base URL of the explain xkcd wiki's MediaWiki API.
        [string]
        $ApiUrl = 'https://www.explainxkcd.com/wiki/api.php'
    )

    Begin {
        if (-not $Num) { $Num = (Invoke-RestMethod 'https://xkcd.com/info.0.json').num }
    }

    Process {
        $Num | ForEach-Object {
            $ID = $_

            if ($Show) {
                Show-XKCDExplanation -Num $ID -Transcript:$Transcript -Discussion:$Discussion -Full:$Full -HighQuality:$HighQuality
                return
            }

            $Sections = (Invoke-RestMethod "${ApiUrl}?action=parse&page=$ID&redirects=1&prop=sections&format=json").parse

            if (-not $Sections) {
                Write-Warning "No explanation was found for comic #$ID at $ApiUrl"
                return
            }

            $ExplanationSection = $Sections.sections | Where-Object { $_.line -eq 'Explanation' } | Select-Object -First 1
            $SectionIndex = if ($ExplanationSection) { $ExplanationSection.index } else { 0 }

            $Wikitext = (Invoke-RestMethod "${ApiUrl}?action=parse&page=$ID&redirects=1&prop=wikitext&section=$SectionIndex&format=json").parse.wikitext.'*'

            $TranscriptSection = $Sections.sections | Where-Object { $_.line -eq 'Transcript' } | Select-Object -First 1
            $TranscriptText = if ($TranscriptSection) {
                $TranscriptWikitext = (Invoke-RestMethod "${ApiUrl}?action=parse&page=$ID&redirects=1&prop=wikitext&section=$($TranscriptSection.index)&format=json").parse.wikitext.'*'
                ConvertTo-XKCDPlainText -WikiText $TranscriptWikitext
            }
            else {
                ''
            }

            $TalkTitle = [uri]::EscapeDataString("Talk:$($Sections.title)")
            $TalkParse = (Invoke-RestMethod "${ApiUrl}?action=parse&page=$TalkTitle&prop=wikitext&format=json").parse
            $DiscussionText = if ($TalkParse) { ConvertTo-XKCDPlainText -WikiText $TalkParse.wikitext.'*' } else { '' }

            [pscustomobject]@{
                Num         = $ID
                Title       = $Sections.title -replace '^\d+:\s*', ''
                Url         = "https://www.explainxkcd.com/wiki/index.php/$ID"
                Explanation = ConvertTo-XKCDPlainText -WikiText $Wikitext
                Transcript  = $TranscriptText
                Discussion  = $DiscussionText
            }
        }
    }
}
