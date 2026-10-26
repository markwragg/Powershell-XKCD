function Write-XKCDCenteredLine {
    <#
    .SYNOPSIS
        Writes a line of text to the console, horizontally centered within the given width, followed by a
        newline. Used throughout Start-XKCD's TUI so the banner, title, controls, image, alt text, and any
        notice/warning lines are all centered consistently.
    #>
    [cmdletbinding()]
    Param(
        # The text to center and write. May contain ANSI/OSC8 escape sequences (colour/style codes, or a
        # hyperlink wrapper) -- these are ignored when working out how much padding to use, since they occupy
        # no columns on screen.
        [Parameter(Position = 0)]
        [string]
        $Text = '',

        # The console width to center within.
        [int]
        $Width = 80,

        # Returns to the start of the current line and erases it before writing, instead of advancing to a
        # new line afterwards -- so a repeated call (e.g. a status message updated in response to a keypress)
        # overwrites itself in place rather than pushing prior output down the screen.
        [switch]
        $InPlace
    )

    $esc = [char]27
    $Plain = ($Text -replace "$esc\[[0-9;]*[a-zA-Z]", '') -replace "$esc\][^$esc]*$esc\\", ''
    $Padding = [Math]::Max(0, [int][Math]::Floor(($Width - $Plain.Length) / 2))

    if ($InPlace) {
        [Console]::Out.Write("`r$esc[2K" + (' ' * $Padding) + $Text)
    }
    else {
        [Console]::Out.Write((' ' * $Padding) + $Text + [Environment]::NewLine)
    }
}
