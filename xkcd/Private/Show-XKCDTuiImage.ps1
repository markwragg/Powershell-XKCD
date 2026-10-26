function Show-XKCDTuiImage {
    <#
    .SYNOPSIS
        Writes a comic's image to the console, horizontally centered, using whichever inline graphics protocol
        the terminal supports (Kitty, iTerm2, or Sixel). Does nothing but warn if none are detected.

    .DESCRIPTION
        Kitty and iTerm2 can be told exactly how many terminal columns to render an image into, so centering
        for those protocols is exact. Sixel has no equivalent control -- it always renders at the image's
        actual pixel size relative to the terminal's real (and unqueryable, from here) cell size -- so its
        padding is only an approximation, estimated from the image's own pixel width (after the same
        downscaling ConvertTo-XKCDSixel applies) and an assumed typical monospace cell width.
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

        # The console width to center the image within.
        [int]
        $Width = 80
    )

    $Protocol = Get-XKCDTerminalGraphicsProtocol

    if (-not $Protocol) {
        Write-Warning 'Your terminal does not appear to support inline image display (Sixel, Kitty, or iTerm2 graphics protocols), so the comic could not be shown.'
        return
    }

    $MaxPixelWidth = if ($HighQuality) { 925 } else { 740 }
    $AssumedCellWidthPx = 10

    $Size = Get-XKCDImageSize -ImageBytes $ImageBytes
    $PixelWidth = if ($Size) { [Math]::Min($Size.Width, $MaxPixelWidth) } else { $MaxPixelWidth }

    $DisplayColumns = [Math]::Max(1, [Math]::Min($Width - 4, [int][Math]::Ceiling($PixelWidth / $AssumedCellWidthPx)))
    $Padding = [Math]::Max(0, [int][Math]::Floor(($Width - $DisplayColumns) / 2))

    try {
        $TerminalImageParams = @{
            ImageBytes  = $ImageBytes
            Protocol    = $Protocol
            HighQuality = $HighQuality
        }
        if ($Protocol -in 'Kitty', 'iTerm2') {
            $TerminalImageParams.Columns = $DisplayColumns
        }

        $TerminalImage = ConvertTo-XKCDTerminalImage @TerminalImageParams
    }
    catch {
        Write-Warning "Unable to render the comic as $($Protocol): $_"
        return
    }

    [Console]::Out.Write(' ' * $Padding)
    [Console]::Out.Write($TerminalImage)
    [Console]::Out.Write([Environment]::NewLine)
}
