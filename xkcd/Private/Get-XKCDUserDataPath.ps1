function Get-XKCDUserDataPath {
    <#
    .SYNOPSIS
        Returns the full path to a file in the module's per-user data directory, creating the directory if it
        doesn't already exist.

    .DESCRIPTION
        Used for preferences (Set-XKCDDefault) and view-tracking state (Get-XKCD -Show et al) that need to
        survive a module upgrade -- PowerShell Gallery installs each version into its own version-numbered
        folder, so anything stored under $PSScriptRoot would be orphaned the moment the module updates.

        Resolves to a '.xkcd' folder directly under the user's home directory (e.g. ~/.xkcd), the same
        convention used by many other cross-platform CLI tools (.ssh, .aws, .docker, .npm, etc.). $HOME is a
        built-in PowerShell variable that's reliably set on every version (including Windows PowerShell 5.1)
        and platform, unlike [Environment]::GetFolderPath('ApplicationData') -- on Unix that returns an empty
        string when XDG_CONFIG_HOME isn't set (true on most Linux distros by default) rather than falling back
        to ~/.config, and its mapping for macOS changed between .NET 7 (~/.config) and .NET 8+
        (~/Library/Application Support).

        If the file doesn't exist yet in the new location but is found in $LegacyDirectory (older versions of
        this module stored these files at $PSScriptRoot, alongside the module itself, which is exactly what
        gets orphaned by an upgrade), it's copied over so existing preferences/state survive the move.
    #>
    [CmdletBinding()]
    Param(
        # The file name to resolve within the per-user data directory, e.g. 'XKCD.state.json'.
        [Parameter(Mandatory)]
        [string]
        $FileName,

        # The directory this file used to be stored in (pass the calling function's own $PSScriptRoot), checked
        # for a one-time migration if the file isn't already present in the new location.
        [string]
        $LegacyDirectory
    )

    $Directory = Join-Path $HOME '.xkcd'

    if (-not (Test-Path $Directory)) {
        New-Item -ItemType Directory -Path $Directory -Force | Out-Null
    }

    $Path = Join-Path $Directory $FileName

    if ($LegacyDirectory -and -not (Test-Path $Path)) {
        $LegacyPath = Join-Path $LegacyDirectory $FileName

        if (Test-Path $LegacyPath) {
            Copy-Item -Path $LegacyPath -Destination $Path
        }
    }

    $Path
}
