function Get-XKCDControlsText {
    <#
    .SYNOPSIS
        Returns the control bar text shown both above and below the comic image in Start-XKCD's interface.

    .DESCRIPTION
        Deliberately plain ASCII -- Previous/Next are also bound to the left/right arrow keys, but those
        don't have a safe, universally-rendering glyph to hint at in the control bar itself (e.g. the arrow
        characters U+2190/U+2192 don't render in VS Code's integrated terminal), so P/N are shown instead,
        alongside the plain ASCII "<-"/"->" as a directional hint.
    #>
    [cmdletbinding()]
    Param()

    ' [G]o to   [F]irst   <- [P]revious   [R]andom   [N]ext ->   [L]ast   [Q]uit '
}
