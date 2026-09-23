function ConvertTo-XKCDSixel {
    <#
    .SYNOPSIS
        Converts raw image bytes into a Sixel escape sequence that can be written to a Sixel-capable terminal.

    .DESCRIPTION
        Decodes with System.Drawing on Windows (any format it supports, e.g. PNG or JPEG) since it's native code
        and roughly three orders of magnitude faster than decoding in PowerShell itself. System.Drawing is
        Windows-only from .NET 6 onwards though, so on Linux/macOS this instead decodes PNG images (which is
        all xkcd has served for every comic from roughly #150 onwards) with ConvertFrom-XKCDPngImage, a pure
        PowerShell/.NET decoder that works identically on every OS -- other formats (e.g. the JPEGs used by
        xkcd's earliest comics) fail with a clear error there.

        Each colour channel is posterized to 6 levels (216 colours max) to keep the palette within a size that's
        practical to build without a full colour-quantization algorithm. This works well for xkcd's mostly
        black-and-white line art, at the cost of some banding on any gradients/photos.
    #>
    [cmdletbinding()]
    Param(
        # The raw bytes of the image to convert. PNG works on every OS; other formats supported by
        # System.Drawing (e.g. JPEG) only decode on Windows.
        [Parameter(Mandatory)]
        [byte[]]
        $ImageBytes,

        # The maximum pixel width to render the image at. Larger images are downscaled to this width, preserving
        # aspect ratio. Defaults to 740, matching xkcd.com's own cap on comic image width.
        [int]
        $MaxWidth = 740,

        # The pixel count (width x height, after any -MaxWidth downscaling) above which a warning is written
        # that Sixel rendering may take a while. The per-pixel conversion below scales with image size, so this
        # gives a heads-up before the wait rather than after it. Defaults to roughly a 740x676 image.
        [int]
        $LargeImageThreshold = 500000
    )

    # Windows PowerShell 5.1 has no $IsWindows variable at all (it only ever runs on Windows); PowerShell 7+
    # sets it to $false on Linux/macOS, where System.Drawing isn't usable regardless of image format.
    if (-not (Test-Path Variable:Global:IsWindows) -or $IsWindows) {
        Add-Type -AssemblyName System.Drawing

        $stream = [System.IO.MemoryStream]::new($ImageBytes)
        $bitmap = [System.Drawing.Bitmap]::new($stream)
        $width = $bitmap.Width
        $height = $bitmap.Height

        $rect = [System.Drawing.Rectangle]::new(0, 0, $width, $height)
        $bitmapData = $bitmap.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $pixelBytes = [byte[]]::new($bitmapData.Stride * $height)
        [System.Runtime.InteropServices.Marshal]::Copy($bitmapData.Scan0, $pixelBytes, 0, $pixelBytes.Length)
        $bitmap.UnlockBits($bitmapData)
        $bitmap.Dispose()

        # Format32bppArgb stores each pixel as B,G,R,A in memory.
        $rIdx = 2
        $bIdx = 0
    }
    elseif ($ImageBytes.Length -ge 8 -and $ImageBytes[0] -eq 137 -and $ImageBytes[1] -eq 80 -and $ImageBytes[2] -eq 78 -and $ImageBytes[3] -eq 71) {
        $decoded = ConvertFrom-XKCDPngImage -ImageBytes $ImageBytes
        $pixelBytes = $decoded.Pixels
        $width = $decoded.Width
        $height = $decoded.Height

        # ConvertFrom-XKCDPngImage stores each pixel as R,G,B,A in memory.
        $rIdx = 0
        $bIdx = 2
    }
    else {
        throw 'ConvertTo-XKCDSixel only supports PNG images on this platform (System.Drawing, which also supports other formats like JPEG, is unavailable outside Windows).'
    }

    if ($width -gt $MaxWidth) {
        $newWidth = $MaxWidth
        $newHeight = [int]($height * ($MaxWidth / $width))
        $resized = [byte[]]::new($newWidth * $newHeight * 4)

        for ($y = 0; $y -lt $newHeight; $y++) {
            $srcY = [Math]::Min($height - 1, [int]($y * $height / $newHeight))
            for ($x = 0; $x -lt $newWidth; $x++) {
                $srcX = [Math]::Min($width - 1, [int]($x * $width / $newWidth))
                [Array]::Copy($pixelBytes, (($srcY * $width) + $srcX) * 4, $resized, (($y * $newWidth) + $x) * 4, 4)
            }
        }

        $pixelBytes = $resized
        $width = $newWidth
        $height = $newHeight
    }

    if (($width * $height) -gt $LargeImageThreshold) {
        Write-Warning "This is a large image ($width x $height pixels) - rendering it as Sixel may take a while."
    }

    $stride = $width * 4

    # Posterize each pixel to a 6x6x6 palette and record a colour index per pixel.
    $colorIndex = [int[]]::new($width * $height)
    $palette = @{}

    for ($y = 0; $y -lt $height; $y++) {
        $rowOffset = $y * $stride
        for ($x = 0; $x -lt $width; $x++) {
            $pixelOffset = $rowOffset + ($x * 4)
            $red = $pixelBytes[$pixelOffset + $rIdx]
            $green = $pixelBytes[$pixelOffset + 1]
            $blue = $pixelBytes[$pixelOffset + $bIdx]

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
