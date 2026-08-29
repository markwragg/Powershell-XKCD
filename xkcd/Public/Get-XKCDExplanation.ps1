function Get-XKCDExplanation {
    <#
    .SYNOPSIS
        Gets the explanation of a comic from the explain xkcd wiki: https://www.explainxkcd.com/.

    .DESCRIPTION
        The Get-XKCDExplanation cmdlet uses the explain xkcd wiki's MediaWiki API to retrieve a comic's
        "Explanation" section, and optionally its "Transcript" section and reader "Discussion" (from its
        explain xkcd talk page), returning them as plain text, with the wiki markup used by the site stripped
        out for readability.

        By default, only the Explanation is retrieved. Use -Transcript and/or -Discussion to also retrieve
        those sections on the returned object, or -Full to always retrieve all three. Sections that aren't
        requested are never fetched from the API (saving a request each) and are omitted from the returned
        object entirely, rather than being included empty.

        With -Show (or on Show-XKCDExplanation), -Explanation, -Transcript, and -Discussion each display just
        that one section -- e.g. -Show -Transcript on its own displays just the transcript, not the explanation.
        Combine them to display more than one, or use -Full to always display all three. Each displayed section
        is given its own heading. These same switches determine what's fetched as well as what's displayed, so
        -Show never retrieves a section it isn't about to show.

        With -Show, -Explanation, -Transcript, and -Discussion (without -Full) display text sections only,
        without fetching or showing the comic image -- the title and a link to the explanation are still shown.
        Use -Full with -Show to always display the comic image alongside every section.

        By default, Get-XKCDExplanation returns the explanation of the latest available comic. Use -Random to
        get a random comic instead (optionally within a -Min/-Max range), or -Newest to get the specified
        number of most recent comics. Use the -Num parameter to specify one or more specific comics to return.

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
        Get-XKCDExplanation -Random -Min 100 -Max 150

        This command returns the explanation of a random comic numbered between 100 and 150.

    .EXAMPLE
        Get-XKCDExplanation -Newest 5

        This command returns the explanation of the latest 5 comics.

    .EXAMPLE
        (Get-XKCDExplanation 2000 -Transcript).Transcript

        This command returns just the transcript of comic number 2000. -Transcript is required to retrieve it --
        by default only the Explanation is fetched and returned.

    .EXAMPLE
        Get-XKCDExplanation -Num 1 -Full -Show

        This command displays the title, image, explanation, transcript, and discussion of comic number 1
        directly in the console, each under its own heading (image display requires your terminal to support
        the Sixel, Kitty, or iTerm2 inline image protocol). Unlike other parameter combinations, -Show does not
        return the explanation object.

    .EXAMPLE
        Get-XKCDExplanation -Num 1 -Explanation -Show

        This command displays just the explanation of comic number 1 as text, along with its title and a link,
        without fetching or displaying the comic image.

    .EXAMPLE
        Get-XKCDExplanation -Open

        This command returns the explanation of the latest comic and opens it in your default web browser.

    .LINK
        https://www.explainxkcd.com/wiki/index.php/Main_Page
    #>
    [cmdletbinding(DefaultParameterSetName = 'Specific')]
    Param(
        # Gets the explanation of a random comic.
        [Parameter(ParameterSetName = 'Random')]
        [switch]
        $Random,

        # Use with -Random to define a lower bound range within which to return a comic.
        [Parameter(ParameterSetName = 'Random')]
        [int]
        $Min = 1,

        # Use with -Random to define an upper bound range within which to return a comic. -Max is the latest comic number by default.
        [Parameter(ParameterSetName = 'Random')]
        [int]
        $Max,

        # Gets the explanation of the specified number of the most recent comics.
        [Parameter(ParameterSetName = 'Newest')]
        [int]
        $Newest,

        # Opens the comic/s in your default web browser.
        [switch]
        $Open,

        # Retrieves, and with -Show displays, the comic's "Explanation" section. The Explanation is always
        # retrieved regardless of this switch -- it only affects what -Show displays, where combining it with
        # -Transcript and/or -Discussion displays more than one section. Defaults to the value saved with
        # Set-XKCDDefault -Explanation, if any.
        [switch]
        $Explanation = (Get-XKCDDefaultValue -Name 'Explanation' -Value $false),

        # Retrieves, and with -Show displays, the comic's "Transcript" section. Without this switch (or -Full),
        # the Transcript is not fetched and its property is omitted from the returned object entirely. Combine
        # with -Explanation and/or -Discussion to display more than one section with -Show. Defaults to the
        # value saved with Set-XKCDDefault -Transcript, if any.
        [switch]
        $Transcript = (Get-XKCDDefaultValue -Name 'Transcript' -Value $false),

        # Retrieves, and with -Show displays, the comic's reader "Discussion", from its explain xkcd talk page.
        # Without this switch (or -Full), the Discussion is not fetched and its property is omitted from the
        # returned object entirely. Combine with -Explanation and/or -Transcript to display more than one
        # section with -Show. Defaults to the value saved with Set-XKCDDefault -Discussion, if any.
        [switch]
        $Discussion = (Get-XKCDDefaultValue -Name 'Discussion' -Value $false),

        # Retrieves, and with -Show displays, all of the explanation, transcript, and discussion sections.
        # Defaults to the value saved with Set-XKCDDefault -Full, if any.
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
        $ApiUrl = 'https://www.explainxkcd.com/wiki/api.php',

        # Gets the explanation of the specified comics. Accepts array input. By default the latest comic is used.
        [Parameter(ParameterSetName = 'Specific', ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [int[]]
        $Num = $Max,

        # Bypass the confirmation check if you try to open more than 9 comics in your browser.
        [switch]
        $Force
    )

    Begin {
        if (-not $Max) { $Max = (Invoke-RestMethod 'https://xkcd.com/info.0.json').num }
        if ($Random)   { $Num = Get-Random -min $Min -max $Max }
        if ($Newest)   { $Num = (($Max - $Newest) + 1)..$Max }
        if (-not $Num) { $Num = $Max }
    }

    Process {
        $Num | ForEach-Object {
            $ID = $_

            if ($Show) {
                Show-XKCDExplanation -Num $ID -Explanation:$Explanation -Transcript:$Transcript -Discussion:$Discussion -Full:$Full -HighQuality:$HighQuality
            }
            else {
                $Sections = (Invoke-RestMethod "${ApiUrl}?action=parse&page=$ID&redirects=1&prop=sections&format=json").parse

                if (-not $Sections) {
                    Write-Warning "No explanation was found for comic #$ID at $ApiUrl"
                }
                else {
                    $ExplanationSection = $Sections.sections | Where-Object { $_.line -eq 'Explanation' } | Select-Object -First 1
                    $SectionIndex = if ($ExplanationSection) { $ExplanationSection.index } else { 0 }

                    $Wikitext = (Invoke-RestMethod "${ApiUrl}?action=parse&page=$ID&redirects=1&prop=wikitext&section=$SectionIndex&format=json").parse.wikitext.'*'

                    $ExplanationProperties = [ordered]@{
                        Num         = $ID
                        Title       = $Sections.title -replace '^\d+:\s*', ''
                        Url         = "https://www.explainxkcd.com/wiki/index.php/$ID"
                        Explanation = ConvertTo-XKCDPlainText -WikiText $Wikitext
                    }

                    # Transcript and Discussion each cost an extra API call, so they're only fetched -- and only
                    # added to the returned object -- when actually requested via -Transcript/-Discussion/-Full.
                    if ($Transcript -or $Full) {
                        $TranscriptSection = $Sections.sections | Where-Object { $_.line -eq 'Transcript' } | Select-Object -First 1
                        $ExplanationProperties.Transcript = if ($TranscriptSection) {
                            $TranscriptWikitext = (Invoke-RestMethod "${ApiUrl}?action=parse&page=$ID&redirects=1&prop=wikitext&section=$($TranscriptSection.index)&format=json").parse.wikitext.'*'
                            ConvertTo-XKCDPlainText -WikiText $TranscriptWikitext
                        }
                        else {
                            ''
                        }
                    }

                    if ($Discussion -or $Full) {
                        $TalkTitle = [uri]::EscapeDataString("Talk:$($Sections.title)")
                        $TalkParse = (Invoke-RestMethod "${ApiUrl}?action=parse&page=$TalkTitle&prop=wikitext&format=json").parse
                        $ExplanationProperties.Discussion = if ($TalkParse) { ConvertTo-XKCDPlainText -WikiText $TalkParse.wikitext.'*' } else { '' }
                    }

                    [pscustomobject]$ExplanationProperties
                }
            }

            if ($Open) {
                if ($Num.count -ge 10 -and -not $Force) {
                    if (-not $confirmation) { $confirmation = Read-Host "This will open $($Num.count) comics in your default browser. Are you sure you want to proceed? [y|n]" }
                }
                if ($confirmation -eq 'y' -or $Num.count -lt 10 -or $Force) {
                    Start-Process "https://xkcd.com/$ID"
                }
            }
        }
    }
}
