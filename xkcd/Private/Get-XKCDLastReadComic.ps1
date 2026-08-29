function Get-XKCDLastReadComic {
    <#
    .SYNOPSIS
        Returns the number of the comic most recently displayed in either direction, as recorded in the given
        state file. Falls back to the recorded LastViewed value if no LastRead value has been recorded yet, or 0
        if the state file doesn't exist.
    #>
    [cmdletbinding()]
    Param(
        # Path to the file used to track the number of the comic most recently displayed.
        [Parameter(Mandatory)]
        [string]
        $StatePath
    )

    if (Test-Path $StatePath) {
        $State = Get-Content $StatePath | ConvertFrom-Json
        if ($null -ne $State.LastRead) {
            [int]$State.LastRead
        }
        else {
            [int]$State.LastViewed
        }
    }
    else {
        0
    }
}
