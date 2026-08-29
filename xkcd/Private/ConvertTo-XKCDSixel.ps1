function ConvertTo-XKCDSixel {
    <#
    .SYNOPSIS
        Converts raw image bytes into a Sixel escape sequence that can be written to a Sixel-capable terminal.

    .DESCRIPTION
        Each colour channel is posterized to 6 levels (216 colours max) to keep the palette within a size that's
        practical to build without a full colour-quantization algorithm. This works well for xkcd's mostly
        black-and-white line art, at the cost of some banding on any gradients/photos.
    #>
    [cmdletbinding()]
    Param(
        # The raw bytes of the image to convert (e.g. PNG or JPEG).
        [Parameter(Mandatory)]
        [byte[]]
        $ImageBytes,

        # The maximum pixel width to render the image at. Larger images are downscaled to this width, preserving aspect ratio.
        [int]
        $MaxWidth = 640,

        # The pixel count (width x height, after any -MaxWidth downscaling) above which a warning is written
        # that Sixel rendering may take a while. The per-pixel conversion below scales with image size, so this
        # gives a heads-up before the wait rather than after it. Defaults to roughly a 640x780 image.
        [int]
        $LargeImageThreshold = 500000
    )

    Add-Type -AssemblyName System.Drawing

    $stream = [System.IO.MemoryStream]::new($ImageBytes)
    $source = [System.Drawing.Bitmap]::new($stream)

    if ($source.Width -gt $MaxWidth) {
        $newHeight = [int]($source.Height * ($MaxWidth / $source.Width))
        $bitmap = [System.Drawing.Bitmap]::new($source, $MaxWidth, $newHeight)
        $source.Dispose()
    }
    else {
        $bitmap = $source
    }

    $width = $bitmap.Width
    $height = $bitmap.Height

    if (($width * $height) -gt $LargeImageThreshold) {
        Write-Warning "This is a large image ($width x $height pixels) - rendering it as Sixel may take a while."
    }

    $rect = [System.Drawing.Rectangle]::new(0, 0, $width, $height)
    $bitmapData = $bitmap.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)

    $pixelBytes = [byte[]]::new($bitmapData.Stride * $height)
    [System.Runtime.InteropServices.Marshal]::Copy($bitmapData.Scan0, $pixelBytes, 0, $pixelBytes.Length)
    $stride = $bitmapData.Stride

    $bitmap.UnlockBits($bitmapData)
    $bitmap.Dispose()

    # Posterize each pixel to a 6x6x6 palette and record a colour index per pixel.
    $colorIndex = [int[]]::new($width * $height)
    $palette = @{}

    for ($y = 0; $y -lt $height; $y++) {
        $rowOffset = $y * $stride
        for ($x = 0; $x -lt $width; $x++) {
            $pixelOffset = $rowOffset + ($x * 4)
            $blue = $pixelBytes[$pixelOffset]
            $green = $pixelBytes[$pixelOffset + 1]
            $red = $pixelBytes[$pixelOffset + 2]

            $rLevel = [int][math]::Round($red / 255 * 5)
            $gLevel = [int][math]::Round($green / 255 * 5)
            $bLevel = [int][math]::Round($blue / 255 * 5)
            $key = ($rLevel * 36) + ($gLevel * 6) + $bLevel

            if (-not $palette.Contains($key)) {
                $palette[$key] = [pscustomobject]@{
                    Index = $palette.Count
                    R     = [int]($rLevel / 5 * 100)
                    G     = [int]($gLevel / 5 * 100)
                    B     = [int]($bLevel / 5 * 100)
                }
            }

            $colorIndex[($y * $width) + $x] = $palette[$key].Index
        }
    }

    $esc = [char]27
    $sb = [System.Text.StringBuilder]::new()

    [void]$sb.Append($esc).Append('Pq"1;1;').Append($width).Append(';').Append($height)

    foreach ($entry in $palette.Values) {
        [void]$sb.Append('#').Append($entry.Index).Append(';2;').Append($entry.R).Append(';').Append($entry.G).Append(';').Append($entry.B)
    }

    for ($bandStart = 0; $bandStart -lt $height; $bandStart += 6) {
        $bandHeight = [Math]::Min(6, $height - $bandStart)
        $bandColors = [System.Collections.Generic.HashSet[int]]::new()

        for ($row = 0; $row -lt $bandHeight; $row++) {
            $y = $bandStart + $row
            for ($x = 0; $x -lt $width; $x++) {
                [void]$bandColors.Add($colorIndex[($y * $width) + $x])
            }
        }

        $isFirstColor = $true
        foreach ($color in $bandColors) {
            if (-not $isFirstColor) { [void]$sb.Append('$') }
            $isFirstColor = $false

            [void]$sb.Append('#').Append($color)

            $lastValue = -1
            $runLength = 0

            for ($x = 0; $x -lt $width; $x++) {
                $value = 0
                for ($row = 0; $row -lt $bandHeight; $row++) {
                    $y = $bandStart + $row
                    if ($colorIndex[($y * $width) + $x] -eq $color) {
                        $value = $value -bor (1 -shl $row)
                    }
                }

                if ($value -eq $lastValue) {
                    $runLength++
                }
                else {
                    if ($runLength -gt 0) {
                        $runChar = [char](63 + $lastValue)
                        if ($runLength -gt 1) { [void]$sb.Append('!').Append($runLength) }
                        [void]$sb.Append($runChar)
                    }
                    $lastValue = $value
                    $runLength = 1
                }
            }

            if ($runLength -gt 0) {
                $runChar = [char](63 + $lastValue)
                if ($runLength -gt 1) { [void]$sb.Append('!').Append($runLength) }
                [void]$sb.Append($runChar)
            }
        }

        [void]$sb.Append('-')
    }

    [void]$sb.Append($esc).Append('\')

    $sb.ToString()
}
