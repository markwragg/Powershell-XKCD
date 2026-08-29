function Show-XKCDExplanationText {
    <#
    .SYNOPSIS
        Displays a comic's title and image above its retrieved explainxkcd sections, formatted for the console.
    #>
    [cmdletbinding()]
    Param(
        # The explanation object returned by Get-XKCDExplanation (must have Num, Title, Url, and Explanation
        # properties, and may also have Transcript and/or Discussion properties).
        [Parameter(Mandatory)]
        [pscustomobject]
        $Explanation,

        # The comic object returned by the xkcd API (must have a num property, and may have year, month, and
        # day), used to show the comic's publish date and a hyperlink to it above the explanation.
        [pscustomobject]
        $Comic,

        # The raw bytes of the comic image (e.g. PNG or JPEG).
        [byte[]]
        $ImageBytes
    )

    try {
        $esc = [char]27
        $titleStyle = "$esc[1;4;96m"
        $headingStyle = "$esc[1;4;93m"
        $signatureStyle = "$esc[1;95m"
        $codeStyle = "$esc[92m"
        $linkStyle = "$esc[4;94m"
        $boldStyle = "$esc[1m"
        $italicStyle = "$esc[3m"
        $boldItalicStyle = "$esc[1;3m"
        $dim = "$esc[2m"
        $reset = "$esc[0m"
        $newLine = [Environment]::NewLine
        $SignaturePattern = '\S+(?:\s+\(talk\))?\s+\d{1,2}:\d{2},\s+\d{1,2}\s+\w+\s+\d{4}\s+\(UTC\)'

        # Matches a Markdown-style "[words](url)" link (see ConvertTo-XKCDPlainText) or a bare url on its own.
        # For the former, the words themselves become the clickable hyperlink and the url is never printed; for
        # the latter, the url is the only text available so it's shown as-is. The url in a "[words](url)" link
        # may itself contain one level of parentheses (e.g. a Wikipedia disambiguation page like
        # "Installer_(OS_X)#Installer_package"), so that's matched as a balanced group rather than stopping at
        # its first closing paren, which would otherwise cut the url short and leak the rest as plain text.
        $LinkPattern = '\[([^\]]+)\]\((https?://(?:[^()]|\([^()]*\))+)\)|(https?://[^\s()`]+)'
        $LinkEvaluator = [System.Text.RegularExpressions.MatchEvaluator] {
            param($Match)
            if ($Match.Groups[2].Success) {
                $LinkText = $Match.Groups[1].Value
                $Url = $Match.Groups[2].Value
            }
            else {
                $LinkText = $Match.Groups[3].Value
                $Url = $Match.Groups[3].Value
            }
            "$linkStyle$esc]8;;$Url$esc\$LinkText$esc]8;;$esc\$reset"
        }

        # Strips ANSI/OSC escape sequences so word-wrapping measures how wide a styled or hyperlinked word
        # actually looks on screen, rather than its much longer raw string length (which would otherwise wrap
        # far too early, since e.g. a short hyperlinked word carries dozens of invisible characters).
        $AnsiPattern = "$esc\[[0-9;]*[A-Za-z]|$esc\][^$esc]*$esc\\"
        function Get-VisibleLength([string]$Text) {
            ($Text -replace $AnsiPattern, '').Length
        }

        $width = 80
        try {
            if ([Console]::WindowWidth -gt 0) { $width = [Console]::WindowWidth }
        }
        catch {
            Write-Verbose 'No console window available (e.g. output redirected), falling back to the default width'
        }

        [Console]::Out.Write($newLine)
        [Console]::Out.Write("$titleStyle#$($Explanation.Num): $($Explanation.Title)$reset")
        [Console]::Out.Write($newLine + $newLine)

        if ($Explanation.Url) {
            $ExplanationHyperlink = "$esc]8;;$($Explanation.Url)$esc\$($Explanation.Url)$esc]8;;$esc\"
            [Console]::Out.Write("$dim$ExplanationHyperlink$reset")
            [Console]::Out.Write($newLine + $newLine)
        }

        if ($Comic) {
            $MetaText = Get-XKCDComicMetaText -Comic $Comic
            [Console]::Out.Write("$dim$MetaText$reset")
            [Console]::Out.Write($newLine + $newLine)
        }

        if ($ImageBytes) {
            Show-XKCDComicImage -Comic $Comic -ImageBytes $ImageBytes -Width $width
        }

        $Sections = [ordered]@{}
        if ($Explanation.PSObject.Properties.Name -contains 'Explanation') { $Sections.Explanation = $Explanation.Explanation }
        if ($Explanation.PSObject.Properties.Name -contains 'Transcript') { $Sections.Transcript = $Explanation.Transcript }
        if ($Explanation.PSObject.Properties.Name -contains 'Discussion') { $Sections.Discussion = $Explanation.Discussion }

        foreach ($SectionName in $Sections.Keys) {
            [Console]::Out.Write("$headingStyle$SectionName$reset")
            [Console]::Out.Write($newLine + $newLine)

            $Text = $Sections[$SectionName]
            if ([string]::IsNullOrWhiteSpace($Text)) { $Text = "No $($SectionName.ToLower()) is available yet." }

            foreach ($Paragraph in ($Text -split '\n{2,}')) {
                # Turn any URL into a working, clickable hyperlink first, while the text is still plain -- every
                # highlighting step below inserts ANSI codes containing literal "[" characters (e.g. "<esc>[3m"),
                # which would otherwise be misread as the start of a "[text](url)" link. This matters especially
                # for wikitext like "''[[Page|Display]]''", where a link sits directly inside bold/italic markup.
                $Paragraph = [regex]::Replace($Paragraph, $LinkPattern, $LinkEvaluator)

                # Highlight Markdown-style bold/italic markup (see ConvertTo-XKCDPlainText) next, while what's
                # left is still otherwise plain. Longest marker first, since e.g. "**bold**" left over after
                # "***" is consumed must not be re-matched as two separate "*"s.
                $Paragraph = $Paragraph -replace '\*\*\*([^*]+)\*\*\*', "$boldItalicStyle`$1$reset"
                $Paragraph = $Paragraph -replace '\*\*([^*]+)\*\*', "$boldStyle`$1$reset"
                $Paragraph = $Paragraph -replace '\*([^*]+)\*', "$italicStyle`$1$reset"

                # Highlight backtick-wrapped code (see ConvertTo-XKCDPlainText).
                $Paragraph = $Paragraph -replace '`([^`]+)`', "$codeStyle`$1$reset"

                # In the Discussion section, highlight each message's trailing "User (talk) HH:MM, D Month YYYY
                # (UTC)" signature so it's easy to see at a glance who wrote what.
                if ($SectionName -eq 'Discussion') {
                    $Paragraph = $Paragraph -replace $SignaturePattern, "$signatureStyle`$0$reset"
                }

                # Preserve each paragraph's leading indentation (used to show reply nesting in a discussion) as a
                # hanging indent, so wrapped lines still line up under it instead of collapsing back to the margin.
                $null = $Paragraph -match '^(?<indent>[ ]*)'
                $Indent = $Matches['indent']
                $WrapWidth = [Math]::Max(20, $width - $Indent.Length)

                $Words = $Paragraph.Substring($Indent.Length) -split '\s+'
                $Lines = [System.Collections.Generic.List[string]]::new()
                $CurrentLine = ''
                $CurrentVisibleLength = 0

                foreach ($Word in $Words) {
                    $WordVisibleLength = Get-VisibleLength $Word

                    if (-not $CurrentLine) {
                        $CurrentLine = $Word
                        $CurrentVisibleLength = $WordVisibleLength
                    }
                    elseif (($CurrentVisibleLength + 1 + $WordVisibleLength) -le $WrapWidth) {
                        $CurrentLine = "$CurrentLine $Word"
                        $CurrentVisibleLength += 1 + $WordVisibleLength
                    }
                    else {
                        $Lines.Add($CurrentLine)
                        $CurrentLine = $Word
                        $CurrentVisibleLength = $WordVisibleLength
                    }
                }
                if ($CurrentLine) { $Lines.Add($CurrentLine) }

                [Console]::Out.Write((($Lines | ForEach-Object { "$Indent$_" }) -join $newLine))
                [Console]::Out.Write($newLine + $newLine)
            }
        }
    }
    catch {
        # Console access can fail in non-interactive/headless hosts (e.g. CI build agents) in ways that vary by
        # environment. Displaying an explanation is inherently best-effort there, so degrade to a warning rather than throw.
        Write-Warning "Unable to display the explanation in this console: $_"
    }
}
