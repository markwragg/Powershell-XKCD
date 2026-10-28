function Get-XKCDSeasonalEmoji {
    <#
    .SYNOPSIS
        Returns a random seasonal emoji for the current month (Halloween in October, Christmas in December),
        or $null outside of those months.
    #>
    [cmdletbinding()]
    Param()

    switch ((Get-Date).Month) {
        10 { Get-Random -InputObject @('🎃', '👻', '🦇', '💀') }
        12 { Get-Random -InputObject @('🎄', '🎅', '🎁', '🔔') }
        default { $null }
    }
}
