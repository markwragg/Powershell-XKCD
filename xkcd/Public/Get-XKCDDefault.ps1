function Get-XKCDDefault {
    <#
    .SYNOPSIS
        Gets the default preferences saved by Set-XKCDDefault.

    .DESCRIPTION
        The Get-XKCDDefault cmdlet returns the default preferences currently saved by Set-XKCDDefault, such as
        whether -HighQuality is used by default. Preferences that haven't been saved are omitted -- each
        cmdlet that honours a preference falls back to its own built-in behavior when one isn't saved here.

    .EXAMPLE
        Get-XKCDDefault

        Returns the currently saved default preferences.

    .LINK
        https://xkcd.com/json.html
    #>
    [cmdletbinding()]
    Param(
        # Path to the file used to store default preferences. By default this is in the user's per-user data
        # directory (~/.xkcd).
        [string]
        $DefaultsPath = (Get-XKCDUserDataPath -FileName 'XKCD.defaults.json' -LegacyDirectory $PSScriptRoot)
    )

    if (Test-Path $DefaultsPath) {
        Get-Content $DefaultsPath | ConvertFrom-Json
    }
    else {
        [pscustomobject]@{}
    }
}
