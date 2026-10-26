function Read-XKCDComicNumberPrompt {
    <#
    .SYNOPSIS
        Prompts for and returns a comic number to jump to, used by Start-XKCD's N control. Returns $null
        (leaving the currently displayed comic unchanged) if the input is blank, isn't a whole number, or
        falls outside 1..$Latest.
    #>
    [cmdletbinding()]
    Param(
        # The highest valid comic number that can be entered.
        [Parameter(Mandatory)]
        [int]
        $Latest,

        # The console width to center the prompt within.
        [int]
        $Width = 80,

        # Indicates the line below the prompt still holds a message from a previous failed attempt (e.g.
        # "invalid comic number") that should stay visible rather than be overwritten -- so the prompt moves
        # up one line and reclaims its own original line instead.
        [switch]
        $MoveUp
    )

    $esc = [char]27
    $Prompt = "Go to comic # (1-$Latest): "
    $Padding = [Math]::Max(0, [int][Math]::Floor(($Width - $Prompt.Length) / 2))

    # `\r` + erase-line returns to the start of the current line and clears it first, so re-prompting (e.g.
    # after an invalid entry) reuses that same line instead of appending onto whatever's already there --
    # which could otherwise run past the console width and visually wrap onto a further line. With -MoveUp,
    # a cursor-up sequence first returns to the prompt's own line, one above the still-visible message.
    $CursorReset = if ($MoveUp) { "$esc[1A`r$esc[2K" } else { "`r$esc[2K" }
    [Console]::Out.Write($CursorReset + (' ' * $Padding) + $Prompt)

    if ($MoveUp) {
        # The line below (where the previous attempt's message is still showing) is now stale, since a fresh
        # prompt is on screen -- clear it too. The cursor position is saved/restored around this so the
        # upcoming input still echoes right after the prompt text above, rather than wherever this leaves it.
        [Console]::Out.Write("$esc[s$esc[1B`r$esc[2K$esc[u")
    }

    $Line = Read-XKCDConsoleLine

    $Requested = 0
    if ([int]::TryParse($Line, [ref]$Requested) -and $Requested -ge 1 -and $Requested -le $Latest) {
        return $Requested
    }

    $null
}
