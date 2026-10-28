function Get-XKCDBanner {
    <#
    .SYNOPSIS
        Returns the ASCII art "xkcd" banner and tagline shown at the top of Start-XKCD's interface.
    #>
    [cmdletbinding()]
    Param()

    # Every line is padded to the same length (35) so Show-XKCDTuiFrame centers each one identically,
    # rather than each line drifting by however many trailing spaces it happens to have.
    $RawLines = @(
        '         888                   888 '
        '         888                   888 '
        '         888                   888 '
        '888  888 888  888  .d8888b .d88888 '
        '`Y8bd8P'' 888 .88P d88P"   d88" 888 '
        '  X88K   888888K  888     888  888 '
        '.d8""8b. 888 "88b Y88b.   Y88b 888 '
        '888  888 888  888  "Y8888P "Y88888 '
    )

    # A seasonal emoji flanking one line of the banner: a random Halloween pick in October, a random
    # Christmas pick in December. Flanked with an equal-width space placeholder on every other line, so all
    # lines stay the same length (required for each to center consistently) and the "xkcd" art itself doesn't
    # shift out of alignment -- all candidates are single-codepoint, supplementary-plane emoji (so .Length is
    # 2 for each of them), which keeps that alignment math the same regardless of which one is picked.
    $Seasonal = switch ((Get-Date).Month) {
        10 { Get-Random -InputObject @('🎃', '👻', '🦇', '💀') }
        12 { Get-Random -InputObject @('🎄', '🎅', '🎁', '🔔') }
        default { $null }
    }

    if ($Seasonal) {
        $Pad = ' ' * $Seasonal.Length
        $Lines = for ($i = 0; $i -lt $RawLines.Count; $i++) {
            if ($i -eq 5) { "$Seasonal $($RawLines[$i]) $Seasonal" }
            else { "$Pad $($RawLines[$i]) $Pad" }
        }
    }
    else {
        $Lines = $RawLines
    }

    [pscustomobject]@{
        Lines   = $Lines
        Tagline = 'A webcomic of romance, sarcasm, math, and language.'
    }
}
