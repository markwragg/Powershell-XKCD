function ConvertTo-XKCDPlainText {
    <#
    .SYNOPSIS
        Converts explainxkcd wikitext markup into plain, readable text for display in the console.
    #>
    [cmdletbinding()]
    Param(
        # The raw MediaWiki wikitext to convert.
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyString()]
        [string]
        $WikiText
    )

    process {
        $Text = $WikiText

        # Builds a url-safe page-title segment: spaces become underscores (MediaWiki/Wikipedia's own convention,
        # kept for readability), and anything else that isn't url-safe (e.g. "?", seen in "what if? (blog)") is
        # percent-encoded so the link actually works, rather than being cut short or rejected by the server.
        # Parentheses are left literal, since e.g. "Installer_(OS_X)" is the real, working Wikipedia url.
        function Format-XKCDUrlSegment([string]$Value) {
            $Underscored = $Value -replace ' ', '_'
            ([uri]::EscapeDataString($Underscored)) -replace '%28', '(' -replace '%29', ')'
        }

        # Strip HTML comments and the section heading itself (its name is already known to the caller)
        $Text = $Text -replace '(?s)<!--.*?-->', ''
        $Text = $Text -replace '(?m)^==+\s*.*?\s*==+\s*$', ''

        # <nowiki>x</nowiki> just protects x from being interpreted as markup, so unwrap it as-is
        $Text = $Text -replace '(?s)<nowiki>(.*?)</nowiki>', '$1'

        # Inline/preformatted code, e.g. <code>print()</code> or <pre>...</pre>, is wrapped in backticks
        # (Markdown-style) so it stays recognisable as code in plain text and can be styled distinctly when displayed.
        $Text = $Text -replace '(?s)<code>(.*?)</code>', '`$1`'
        $Text = $Text -replace '(?s)<pre>(.*?)</pre>', '`$1`'

        # MediaWiki also renders any line starting with a space as preformatted code (a separate convention from
        # <code>/<pre>, e.g. a shell command example) -- wrap those in backticks too.
        $Text = $Text -replace '(?m)^ +(.+)$', '`$1`'

        # External links: [http://url display text] -> "[display text](http://url)" (Markdown-style, so the
        # words themselves can become the working hyperlink without printing the url separately);
        # [http://url] -> "http://url" since there's no other text to show.
        $Text = $Text -replace '\[(https?://\S+)\s+([^\]]+)\]', '[$2]($1)'
        $Text = $Text -replace '\[(https?://\S+)\]', '$1'

        # Internal wiki links/categories: [[Page|Display]] -> "[Display](url)", [[Page]] -> "[Page](url)", so
        # these become working hyperlinks too, the same way external links do. A leading ":" (used to link to a
        # category/file page rather than apply it) isn't part of the real title, so it's dropped from the url.
        # Anchors to a section of the current page (e.g. [[#Trivia]]) are left as plain text, since there's no
        # page url available here to link them against.
        $InternalLinkEvaluator = [System.Text.RegularExpressions.MatchEvaluator] {
            param($Match)
            $Parts = $Match.Groups[1].Value -split '\|'
            $Target = $Parts[0].TrimStart(':')
            $Display = $Parts[-1]

            if ($Target.StartsWith('#')) {
                $Display
            }
            else {
                $PageAndAnchor = $Target -split '#', 2
                $Page = Format-XKCDUrlSegment $PageAndAnchor[0]
                $UrlTarget = if ($PageAndAnchor.Count -gt 1) { "$Page#$($PageAndAnchor[1])" } else { $Page }
                "[$Display](https://www.explainxkcd.com/wiki/index.php/$UrlTarget)"
            }
        }
        $Text = [regex]::Replace($Text, '\[\[([^\]]+)\]\]', $InternalLinkEvaluator)

        # Templates. {{w|Page}}/{{w|Page|Display}} and {{what if|N}}/{{what if|N|Display}} are links to Wikipedia
        # and the What If blog respectively, so become working Markdown-style hyperlinks the same way other
        # links do, e.g. {{w|Retina Display}} -> "[Retina Display](https://en.wikipedia.org/wiki/Retina_Display)".
        # Other templates aren't links, e.g. {{Citation needed}} -> "[citation needed]". Resolved innermost-first
        # so nested templates (rare, but possible) collapse correctly.
        $TemplateEvaluator = [System.Text.RegularExpressions.MatchEvaluator] {
            param($Match)
            $Parts = $Match.Groups[1].Value -split '\|'
            $Name = $Parts[0].Trim()

            if ($Name -ieq 'w' -and $Parts.Count -gt 1) {
                $PageAndAnchor = $Parts[1] -split '#', 2
                $Page = Format-XKCDUrlSegment $PageAndAnchor[0]
                $UrlTarget = if ($PageAndAnchor.Count -gt 1) { "$Page#$($PageAndAnchor[1])" } else { $Page }
                "[$($Parts[-1])](https://en.wikipedia.org/wiki/$UrlTarget)"
            }
            elseif ($Name -ieq 'what if' -and $Parts.Count -gt 1) {
                $Display = if ($Parts.Count -gt 2) { $Parts[-1] } else { "what if #$($Parts[1])" }
                "[$Display](https://what-if.xkcd.com/$($Parts[1])/)"
            }
            elseif ($Parts.Count -gt 1) {
                $Parts[-1]
            }
            else {
                "[$($Parts[0].ToLower())]"
            }
        }
        while ($Text -match '\{\{([^{}]+)\}\}') {
            $Text = [regex]::Replace($Text, '\{\{([^{}]+)\}\}', $TemplateEvaluator)
        }

        # Bold/italic markup -> Markdown-style ("'''''" -> "***", "'''" -> "**", "''" -> "*") so it can be styled
        # distinctly when displayed, instead of just being discarded. Order matters: the longest marker must be
        # replaced first, since e.g. a run of 5 apostrophes is one bold-italic marker, not a 3- and a 2-marker.
        $Text = $Text -replace "'''''", '***' -replace "'''", '**' -replace "''", '*'

        # Definition lists, e.g. "; Term" -> "Term:". Description/reply lines are indented by nesting depth,
        # e.g. ": Description" -> "  Description", "::: Nested reply" -> "      Nested reply".
        $Text = $Text -replace '(?m)^;\s*(.+)$', '$1:'
        $IndentEvaluator = [System.Text.RegularExpressions.MatchEvaluator] {
            param($Match)
            '  ' * $Match.Groups[1].Value.Length
        }
        $Text = [regex]::Replace($Text, '(?m)^(:+)\s*', $IndentEvaluator)

        # Collapse the resulting excess blank lines and surrounding whitespace
        $Text = $Text -replace '(?m)[ \t]+$', ''
        $Text = $Text -replace '(?s)\n{3,}', "`n`n"

        $Text.Trim()
    }
}
