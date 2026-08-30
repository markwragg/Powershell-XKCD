function Get-XKCDTerminalImageFile {
    <#
    .SYNOPSIS
        Reads a file saved by Export-XKCDTerminalImage, warning if it doesn't exist, can't be read, or was
        rendered for a different graphics protocol than the one detected for the current terminal.
    #>
    [cmdletbinding()]
    Param(
        # Path to a file previously saved with Export-XKCDTerminalImage.
        [Parameter(Mandatory)]
        [string]
        $Path
    )

    if (-not (Test-Path $Path)) {
        Write-Warning "No saved terminal image was found at '$Path'."
        return
    }

    try {
        $Saved = Get-Content $Path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        Write-Warning "Unable to read the saved terminal image at '$Path': $_"
        return
    }

    $CurrentProtocol = Get-XKCDTerminalGraphicsProtocol

    if (-not $CurrentProtocol) {
        Write-Warning "Your terminal does not appear to support inline image display (Sixel, Kitty, or iTerm2 graphics protocols); attempting to display the saved image from '$Path' anyway."
    }
    elseif ($Saved.Protocol -ne $CurrentProtocol) {
        Write-Warning "The terminal image saved at '$Path' was rendered for the $($Saved.Protocol) graphics protocol, but this terminal supports $CurrentProtocol instead -- it may not display correctly."
    }

    $Saved
}
