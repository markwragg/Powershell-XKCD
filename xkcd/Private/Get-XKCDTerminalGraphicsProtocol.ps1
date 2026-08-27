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

    # Checked ahead of WT_SESSION below: TERM_PROGRAM is set directly by whichever terminal is actually
    # rendering output, whereas WT_SESSION can leak through process environment inheritance (e.g. when VS
    # Code itself was launched from within a Windows Terminal session) even though Windows Terminal isn't
    # what's actually displaying this session. VS Code's integrated terminal has had opt-in Sixel support
    # since v1.80, but there's no environment variable exposing whether the user has actually turned it on,
    # so warn once per session rather than silently rendering nothing if they haven't.
    if ($env:TERM_PROGRAM -eq 'vscode') {
        if (-not $script:XKCDVSCodeImagesWarned) {
            Write-Warning "VS Code's integrated terminal can display images, but only if you've enabled the 'terminal.integrated.enableImages' setting."
            $script:XKCDVSCodeImagesWarned = $true
        }

        return 'Sixel'
    }

    # Windows Terminal has supported Sixel output since v1.22
    if ($env:WT_SESSION) {
        return 'Sixel'
    }

    return $null
}
