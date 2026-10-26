function Get-XKCDTerminalImageColumnCount {
    <#
    .SYNOPSIS
        Works out how many terminal columns to request an image be rendered into for Kitty/iTerm2, based on
        the image's own pixel width (capped to a sensible maximum) and an assumed typical monospace cell width.

    .DESCRIPTION
        Kitty and iTerm2 can be told exactly how many terminal columns to render an image into, in which case
        the client scales the image to fit exactly (auto-computing rows to preserve aspect ratio). Leaving
        columns unspecified instead renders at the image's native resolution mapped onto whole terminal cells
        -- if the image's pixel height isn't an exact multiple of the terminal's actual cell pixel height,
        the partial trailing cell row is left as background-coloured padding, which shows up as a thin solid
        bar under the image. Requesting an explicit column count avoids that.
    #>
    [cmdletbinding()]
    Param(
        # The raw bytes of the image to measure (e.g. PNG or JPEG).
        [Parameter(Mandatory)]
        [byte[]]
        $ImageBytes,

        # The console width to fit the image within.
        [int]
        $Width = 80,

        # Indicates that $ImageBytes is a higher resolution (_2x) source image, so it should be rendered at a
        # correspondingly higher quality rather than downscaled to the standard size.
        [switch]
        $HighQuality
    )

    $MaxPixelWidth = if ($HighQuality) { 925 } else { 740 }
    $AssumedCellWidthPx = 10

    $Size = Get-XKCDImageSize -ImageBytes $ImageBytes
    $PixelWidth = if ($Size) { [Math]::Min($Size.Width, $MaxPixelWidth) } else { $MaxPixelWidth }

    [Math]::Max(1, [Math]::Min($Width - 4, [int][Math]::Ceiling($PixelWidth / $AssumedCellWidthPx)))
}
