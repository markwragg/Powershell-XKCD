function Get-XKCDBanner {
    <#
    .SYNOPSIS
        Returns the ASCII art "xkcd" banner and tagline shown at the top of Start-XKCD's interface.
    #>
    [cmdletbinding()]
    Param()

    [pscustomobject]@{
        # Every line is padded to the same length (35) so Show-XKCDTuiFrame centers each one identically,
        # rather than each line drifting by however many trailing spaces it happens to have.
        Lines   = @(
            '         888                   888 '
            '         888                   888 '
            '         888                   888 '
            '888  888 888  888  .d8888b .d88888 '
            '`Y8bd8P'' 888 .88P d88P"   d88" 888 '
            '  X88K   888888K  888     888  888 '
            '.d8""8b. 888 "88b Y88b.   Y88b 888 '
            '888  888 888  888  "Y8888P "Y88888 '
        )
        Tagline = 'A webcomic of romance, sarcasm, math, and language.'
    }
}
