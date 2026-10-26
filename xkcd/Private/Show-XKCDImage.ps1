function Show-XKCDImage {
    <#
    .SYNOPSIS
        Writes an image to the console using whichever inline graphics protocol the terminal supports
        (Kitty, iTerm2, or Sixel). Does nothing but warn if none are detected.

    .DESCRIPTION
        For Kitty/iTerm2, requests a specific column count (derived from the image's own pixel width and the
        console width) rather than leaving it to the client's own default sizing -- otherwise, if the image's
        pixel height isn't an exact multiple of the terminal's actual cell pixel height, the partial trailing
        cell row is left as background-coloured padding, showing up as a thin solid bar under the image.
    #>
    [cmdletbinding()]
    Param(
        # The raw bytes of the image to display (e.g. PNG or JPEG).
        [Parameter(Mandatory)]
        [byte[]]
        $ImageBytes,

        # Indicates that $ImageBytes is a higher resolution (_2x) source image, so it should be rendered at a
        # correspondingly higher quality rather than downscaled to the standard size.
        [switch]
        $HighQuality,

        # The console width to fit the image within (used only to work out the Kitty/iTerm2 column count).
        [int]
        $Width = 80
    )

    $protocol = Get-XKCDTerminalGraphicsProtocol

    if (-not $protocol) {
        Write-Warning 'Your terminal does not appear to support inline image display (Sixel, Kitty, or iTerm2 graphics protocols), so the comic could not be shown.'
        return
    }

    try {
        $TerminalImageParams = @{
            ImageBytes  = $ImageBytes
            Protocol    = $protocol
            HighQuality = $HighQuality
        }
        if ($protocol -in 'Kitty', 'iTerm2') {
            $TerminalImageParams.Columns = Get-XKCDTerminalImageColumnCount -ImageBytes $ImageBytes -Width $Width -HighQuality:$HighQuality
        }

        $TerminalImage = ConvertTo-XKCDTerminalImage @TerminalImageParams
    }
    catch {
        Write-Warning "Unable to render the comic as $($protocol): $_"
        return
    }

    [Console]::Out.Write($TerminalImage)
    [Console]::Out.Write([Environment]::NewLine)
}
