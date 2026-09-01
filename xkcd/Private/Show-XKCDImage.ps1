function Show-XKCDImage {
    <#
    .SYNOPSIS
        Writes an image to the console using whichever inline graphics protocol the terminal supports
        (Kitty, iTerm2, or Sixel). Does nothing but warn if none are detected.
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
        $HighQuality
    )

    $protocol = Get-XKCDTerminalGraphicsProtocol

    if (-not $protocol) {
        Write-Warning 'Your terminal does not appear to support inline image display (Sixel, Kitty, or iTerm2 graphics protocols), so the comic could not be shown.'
        return
    }

    try {
        $TerminalImage = ConvertTo-XKCDTerminalImage -ImageBytes $ImageBytes -Protocol $protocol -HighQuality:$HighQuality
    }
    catch {
        Write-Warning "Unable to render the comic as $($protocol): $_"
        return
    }

    [Console]::Out.Write($TerminalImage)
    [Console]::Out.Write([Environment]::NewLine)
}
