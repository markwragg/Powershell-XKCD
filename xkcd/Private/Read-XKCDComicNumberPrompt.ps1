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
        $Latest
    )

    [Console]::Out.Write("Go to comic # (1-$Latest): ")
    $Line = Read-XKCDConsoleLine

    $Requested = 0
    if ([int]::TryParse($Line, [ref]$Requested) -and $Requested -ge 1 -and $Requested -le $Latest) {
        return $Requested
    }

    $null
}
