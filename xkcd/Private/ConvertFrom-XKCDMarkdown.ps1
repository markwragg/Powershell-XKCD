function ConvertFrom-XKCDMarkdown {
    <#
    .SYNOPSIS
        Strips the Markdown-style formatting and urls written by ConvertTo-XKCDPlainText, returning fully plain text.
    #>
    [cmdletbinding()]
    Param(
        # The Markdown-style text to convert, as produced by ConvertTo-XKCDPlainText.
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyString()]
        [string]
        $Text
    )

    process {
        $Result = $Text

        # Markdown-style links, "[text](url)" -> "text" (see ConvertTo-XKCDPlainText). The url may itself contain
        # one level of parentheses (e.g. a Wikipedia disambiguation link), so it's matched as a balanced group
        # rather than stopping at the first closing paren, which would otherwise cut the match short.
        $Result = $Result -replace '\[([^\]]+)\]\(https?://(?:[^()]|\([^()]*\))+\)', '$1'

        # Bare urls (e.g. from "[http://url]" with no display text) carry no other information once urls are
        # being stripped entirely, so they're dropped rather than left behind as unreadable noise. Stops before
        # an immediately-following ")" or "]" rather than eating it too, so a wrapping "(url)" or "[url]" is
        # left as an empty, still-paired "()"/"[]" for the cleanup below to then drop.
        $Result = $Result -replace 'https?://[^\s)\]]+', ''

        # Bold/italic markup, longest marker first -- a run left over after "***" is consumed must not be
        # re-matched as a separate "**" or "*" (see ConvertTo-XKCDPlainText).
        $Result = $Result -replace '\*\*\*([^*]+)\*\*\*', '$1'
        $Result = $Result -replace '\*\*([^*]+)\*\*', '$1'
        $Result = $Result -replace '\*([^*]+)\*', '$1'

        # Inline/preformatted code.
        $Result = $Result -replace '`([^`]+)`', '$1'

        # Drop brackets/parens left wrapping nothing but whitespace by a removed bare url, e.g. "(http://x)" ->
        # "()" -> "". A url alongside other text, e.g. "(see http://x)" -> "(see )", is left as-is -- there's
        # still a real word in there worth keeping the parens around.
        $Result = $Result -replace '\(\s*\)', ''
        $Result = $Result -replace '\[\s*\]', ''

        # Collapse the extra interior whitespace left behind by removed urls/markers on each line, without
        # touching leading indentation (which conveys reply nesting depth in the Discussion section).
        $Result = ($Result -split "`n" | ForEach-Object {
            if ($_ -match '^(?<indent>[ \t]*)(?<rest>.*)$') {
                "$($Matches['indent'])$(($Matches['rest'] -replace ' {2,}', ' ').TrimEnd())"
            }
            else {
                $_
            }
        }) -join "`n"

        $Result = $Result -replace '(?s)\n{3,}', "`n`n"

        $Result.Trim()
    }
}
