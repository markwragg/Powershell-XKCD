Function Get-XKCDDefaultValue {
    <#
    .SYNOPSIS
        Returns the saved default for the named preference (set via Set-XKCDDefault), or the given fallback
        value if no default has been saved for it.
    #>
    [cmdletbinding()]
    Param(
        # The name of the preference to look up, e.g. 'HighQuality' or 'Path'.
        [Parameter(Mandatory)]
        [string]
        $Name,

        # The value to use if no default has been saved for this preference.
        $Value
    )

    $Stored = (Get-XKCDDefault).$Name

    if ($null -ne $Stored) { $Stored } else { $Value }
}
