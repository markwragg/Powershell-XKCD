Function Get-XKCDTerminalGraphicsProtocol {
    <#
    .SYNOPSIS
        Detects which inline image graphics protocol, if any, the current terminal supports.
    #>
    [cmdletbinding()]
    Param()

    if ($env:TERM -eq 'xterm-kitty' -or $env:KITTY_WINDOW_ID -or $env:TERM_PROGRAM -in 'WezTerm', 'ghostty') {
        return 'Kitty'
    }

    if ($env:TERM_PROGRAM -eq 'iTerm.app') {
        return 'iTerm2'
    }

    # Windows Terminal has supported Sixel output since v1.22
    if ($env:WT_SESSION) {
        return 'Sixel'
    }

    return $null
}
