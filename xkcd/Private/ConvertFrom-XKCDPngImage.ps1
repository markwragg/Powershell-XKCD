function ConvertFrom-XKCDPngImage {
    <#
    .SYNOPSIS
        Decodes PNG image bytes into raw 8-bit RGBA pixel data.

    .DESCRIPTION
        Used instead of System.Drawing so that ConvertTo-XKCDSixel works on Linux/macOS -- System.Drawing.Common
        is Windows-only from .NET 6 onwards, regardless of whether libgdiplus is installed.

        Supports the PNG colour types/bit depths that xkcd's comic images and common encoders (e.g.
        System.Drawing itself, when writing a PNG) actually produce: colour types 0/2/3/4/6, bit depths
        1/2/4/8/16, non-interlaced only. Interlaced (Adam7) images are not supported.
    #>
    [CmdletBinding()]
    Param(
        # The raw bytes of a PNG image.
        [Parameter(Mandatory)]
        [byte[]]
        $ImageBytes
    )

    $signature = 137, 80, 78, 71, 13, 10, 26, 10
    for ($i = 0; $i -lt 8; $i++) {
        if ($ImageBytes[$i] -ne $signature[$i]) {
            throw 'ConvertTo-XKCDSixel only supports PNG images on this platform (System.Drawing, which also supports other formats like JPEG, is unavailable outside Windows).'
        }
    }

    function Read-XKCDUInt32BE ([byte[]]$Bytes, [int]$Offset) {
        ([uint32]$Bytes[$Offset] -shl 24) -bor ([uint32]$Bytes[$Offset + 1] -shl 16) -bor ([uint32]$Bytes[$Offset + 2] -shl 8) -bor [uint32]$Bytes[$Offset + 3]
    }

    # Read every chunk up front: IHDR for the image's dimensions/format, PLTE/tRNS for palette colour and
    # transparency lookups (colour type 3), and IDAT (possibly split across several chunks) for the
    # compressed pixel data itself.
    $offset = 8
    $width = 0
    $height = 0
    $bitDepth = 0
    $colorType = 0
    $interlace = 0
    $idatChunks = [System.Collections.Generic.List[byte[]]]::new()
    $palette = $null
    $transparency = $null

    while ($offset -lt $ImageBytes.Length) {
        $length = Read-XKCDUInt32BE $ImageBytes $offset
        $type = [System.Text.Encoding]::ASCII.GetString($ImageBytes, $offset + 4, 4)
        $dataStart = $offset + 8

        if ($type -eq 'IHDR') {
            $width = Read-XKCDUInt32BE $ImageBytes $dataStart
            $height = Read-XKCDUInt32BE $ImageBytes ($dataStart + 4)
            $bitDepth = $ImageBytes[$dataStart + 8]
            $colorType = $ImageBytes[$dataStart + 9]
            $interlace = $ImageBytes[$dataStart + 12]
        }
        elseif ($type -eq 'PLTE') {
            $palette = [byte[]]::new($length)
            [Array]::Copy($ImageBytes, $dataStart, $palette, 0, $length)
        }
        elseif ($type -eq 'tRNS') {
            $transparency = [byte[]]::new($length)
            [Array]::Copy($ImageBytes, $dataStart, $transparency, 0, $length)
        }
        elseif ($type -eq 'IDAT') {
            $chunk = [byte[]]::new($length)
            [Array]::Copy($ImageBytes, $dataStart, $chunk, 0, $length)
            $idatChunks.Add($chunk)
        }
        elseif ($type -eq 'IEND') {
            $offset = $ImageBytes.Length
        }

        if ($type -ne 'IEND') {
            $offset = $dataStart + $length + 4
        }
    }

    if ($interlace -ne 0) {
        throw 'ConvertTo-XKCDSixel does not support interlaced PNG images.'
    }

    $channels = if ($colorType -eq 0) { 1 } # Grayscale
    elseif ($colorType -eq 2) { 3 } # RGB
    elseif ($colorType -eq 3) { 1 } # Palette
    elseif ($colorType -eq 4) { 2 } # Grayscale + alpha
    elseif ($colorType -eq 6) { 4 } # RGBA
    else { throw "ConvertTo-XKCDSixel does not support PNG colour type $colorType." }

    if ($bitDepth -notin 1, 2, 4, 8, 16) {
        throw "ConvertTo-XKCDSixel does not support PNG bit depth $bitDepth."
    }

    $totalLength = ($idatChunks | ForEach-Object Length | Measure-Object -Sum).Sum
    $compressed = [byte[]]::new($totalLength)
    $pos = 0
    foreach ($chunk in $idatChunks) {
        [Array]::Copy($chunk, 0, $compressed, $pos, $chunk.Length)
        $pos += $chunk.Length
    }

    # IDAT holds zlib-wrapped (RFC 1950) DEFLATE data. Strip the 2-byte zlib header and hand the rest to
    # DeflateStream, which reads raw DEFLATE and simply stops once the compressed stream ends -- the
    # trailing 4-byte Adler32 checksum after it is never touched. (System.IO.Compression.ZLibStream would
    # avoid this, but it's .NET 6+ only, whereas this needs to run under Windows PowerShell 5.1 too.)
    $deflateData = [byte[]]::new($compressed.Length - 2)
    [Array]::Copy($compressed, 2, $deflateData, 0, $deflateData.Length)

    $msIn = [System.IO.MemoryStream]::new($deflateData)
    $deflateStream = [System.IO.Compression.DeflateStream]::new($msIn, [System.IO.Compression.CompressionMode]::Decompress)
    $msOut = [System.IO.MemoryStream]::new()
    try {
        $deflateStream.CopyTo($msOut)
        $rawScanlines = $msOut.ToArray()
    }
    finally {
        $deflateStream.Dispose()
        $msIn.Dispose()
        $msOut.Dispose()
    }

    # bpp = bytes per *complete* pixel (minimum 1), as used by the filter algorithms below -- distinct from
    # the bits-per-sample unpacking done afterwards for sub-byte bit depths.
    $bpp = [Math]::Max(1, [int][Math]::Ceiling($bitDepth * $channels / 8))
    $scanlineBytes = [int][Math]::Ceiling($width * $bitDepth * $channels / 8)

    $pixelData = [byte[]]::new($height * $scanlineBytes)
    $srcOffset = 0
    $prevRow = [byte[]]::new($scanlineBytes)

    for ($y = 0; $y -lt $height; $y++) {
        $filterType = $rawScanlines[$srcOffset]
        $srcOffset++

        $row = [byte[]]::new($scanlineBytes)
        [Array]::Copy($rawScanlines, $srcOffset, $row, 0, $scanlineBytes)
        $srcOffset += $scanlineBytes

        for ($i = 0; $i -lt $scanlineBytes; $i++) {
            $a = if ($i -ge $bpp) { $row[$i - $bpp] } else { 0 }
            $b = $prevRow[$i]
            $c = if ($i -ge $bpp) { $prevRow[$i - $bpp] } else { 0 }
            $x = $row[$i]

            $value = if ($filterType -eq 0) { $x }
            elseif ($filterType -eq 1) { $x + $a }
            elseif ($filterType -eq 2) { $x + $b }
            elseif ($filterType -eq 3) { $x + [Math]::Floor(($a + $b) / 2) }
            elseif ($filterType -eq 4) {
                $p = $a + $b - $c
                $pa = [Math]::Abs($p - $a)
                $pb = [Math]::Abs($p - $b)
                $pc = [Math]::Abs($p - $c)
                $x + $(if ($pa -le $pb -and $pa -le $pc) { $a } elseif ($pb -le $pc) { $b } else { $c })
            }
            else { throw "ConvertTo-XKCDSixel encountered an unsupported PNG filter type $filterType." }

            $row[$i] = [byte]($value -band 0xFF)
        }

        [Array]::Copy($row, 0, $pixelData, $y * $scanlineBytes, $scanlineBytes)
        $prevRow = $row
    }

    function Get-XKCDPngRawSample ([byte[]]$PixelData, [int]$RowStart, [int]$SampleIndex, [int]$BitDepth) {
        if ($BitDepth -eq 8) {
            return $PixelData[$RowStart + $SampleIndex]
        }
        elseif ($BitDepth -eq 16) {
            return $PixelData[$RowStart + ($SampleIndex * 2)]
        }
        else {
            $bitOffset = $SampleIndex * $BitDepth
            $byteIndex = $RowStart + [int][Math]::Floor($bitOffset / 8)
            $shift = 8 - $BitDepth - ($bitOffset % 8)
            $mask = (1 -shl $BitDepth) - 1
            return ($PixelData[$byteIndex] -shr $shift) -band $mask
        }
    }

    # Expand to 8-bit-per-channel RGBA regardless of the source colour type/bit depth.
    $rgba = [byte[]]::new($width * $height * 4)

    for ($y = 0; $y -lt $height; $y++) {
        $rowStart = $y * $scanlineBytes
        for ($x = 0; $x -lt $width; $x++) {
            $rgbaOffset = (($y * $width) + $x) * 4
            $sampleBase = $x * $channels

            if ($colorType -eq 0) {
                # Grayscale: <8-bit samples are scaled up to fill the full 0-255 range.
                $raw = Get-XKCDPngRawSample $pixelData $rowStart $sampleBase $bitDepth
                $gray = if ($bitDepth -eq 8 -or $bitDepth -eq 16) { $raw } else { [byte]([Math]::Round($raw * 255 / ((1 -shl $bitDepth) - 1))) }
                $rgba[$rgbaOffset] = $gray
                $rgba[$rgbaOffset + 1] = $gray
                $rgba[$rgbaOffset + 2] = $gray
                $rgba[$rgbaOffset + 3] = 255
            }
            elseif ($colorType -eq 2) {
                $rgba[$rgbaOffset] = Get-XKCDPngRawSample $pixelData $rowStart $sampleBase $bitDepth
                $rgba[$rgbaOffset + 1] = Get-XKCDPngRawSample $pixelData $rowStart ($sampleBase + 1) $bitDepth
                $rgba[$rgbaOffset + 2] = Get-XKCDPngRawSample $pixelData $rowStart ($sampleBase + 2) $bitDepth
                $rgba[$rgbaOffset + 3] = 255
            }
            elseif ($colorType -eq 3) {
                # Palette: the sample is a raw index, never scaled.
                $index = Get-XKCDPngRawSample $pixelData $rowStart $sampleBase $bitDepth
                $paletteOffset = $index * 3
                $rgba[$rgbaOffset] = $palette[$paletteOffset]
                $rgba[$rgbaOffset + 1] = $palette[$paletteOffset + 1]
                $rgba[$rgbaOffset + 2] = $palette[$paletteOffset + 2]
                $rgba[$rgbaOffset + 3] = if ($transparency -and $index -lt $transparency.Length) { $transparency[$index] } else { 255 }
            }
            elseif ($colorType -eq 4) {
                $gray = Get-XKCDPngRawSample $pixelData $rowStart $sampleBase $bitDepth
                $rgba[$rgbaOffset] = $gray
                $rgba[$rgbaOffset + 1] = $gray
                $rgba[$rgbaOffset + 2] = $gray
                $rgba[$rgbaOffset + 3] = Get-XKCDPngRawSample $pixelData $rowStart ($sampleBase + 1) $bitDepth
            }
            elseif ($colorType -eq 6) {
                $rgba[$rgbaOffset] = Get-XKCDPngRawSample $pixelData $rowStart $sampleBase $bitDepth
                $rgba[$rgbaOffset + 1] = Get-XKCDPngRawSample $pixelData $rowStart ($sampleBase + 1) $bitDepth
                $rgba[$rgbaOffset + 2] = Get-XKCDPngRawSample $pixelData $rowStart ($sampleBase + 2) $bitDepth
                $rgba[$rgbaOffset + 3] = Get-XKCDPngRawSample $pixelData $rowStart ($sampleBase + 3) $bitDepth
            }
        }
    }

    [pscustomobject]@{
        Width  = $width
        Height = $height
        Pixels = $rgba
    }
}
