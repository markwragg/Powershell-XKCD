if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Unit Tests PS$PSVersion" {

    BeforeAll {
        $Root = "$PSScriptRoot/../.."
        $Module = 'xkcd'

        Get-Module $Module | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module "$Root/$Module" -Force

        $ModuleObj = Get-Module $Module

        function ConvertFrom-XKCDTestPngBytes {
            Param([byte[]]$ImageBytes)

            & $ModuleObj { Param($ImageBytes) ConvertFrom-XKCDPngBytes -ImageBytes $ImageBytes } $ImageBytes
        }

        # Hand-assembles a minimal valid PNG from raw (pre-filtered, pre-compressed) scanline bytes, so each
        # colour type/bit depth path in the decoder can be exercised directly without needing an encoder for
        # it (e.g. System.Drawing can't produce a palette or sub-byte-depth PNG). The decoder never validates
        # chunk CRCs, so those are left as zero.
        function New-XKCDTestPngBytes {
            Param(
                [int]$Width,
                [int]$Height,
                [byte]$BitDepth,
                [byte]$ColorType,
                [Parameter(Mandatory)]
                [byte[]]$ScanlineData,
                [byte[]]$Palette,
                [byte[]]$Transparency,
                [byte]$Interlace = 0
            )

            function ConvertTo-XKCDTestBigEndianBytes ([int]$Value) {
                , [byte[]]@(
                    [byte](($Value -shr 24) -band 0xFF),
                    [byte](($Value -shr 16) -band 0xFF),
                    [byte](($Value -shr 8) -band 0xFF),
                    [byte]($Value -band 0xFF)
                )
            }

            function New-XKCDTestPngChunk ([string]$Type, [byte[]]$Data) {
                if (-not $Data) { $Data = @() }
                (ConvertTo-XKCDTestBigEndianBytes $Data.Length) + [System.Text.Encoding]::ASCII.GetBytes($Type) + $Data + [byte[]]::new(4)
            }

            $signature = [byte[]]@(137, 80, 78, 71, 13, 10, 26, 10)

            $ihdrData = (ConvertTo-XKCDTestBigEndianBytes $Width) + (ConvertTo-XKCDTestBigEndianBytes $Height) + [byte[]]@($BitDepth, $ColorType, 0, 0, $Interlace)
            $ihdr = New-XKCDTestPngChunk 'IHDR' $ihdrData

            $plte = if ($Palette) { New-XKCDTestPngChunk 'PLTE' $Palette } else { @() }
            $trns = if ($Transparency) { New-XKCDTestPngChunk 'tRNS' $Transparency } else { @() }

            $ms = [System.IO.MemoryStream]::new()
            $deflateStream = [System.IO.Compression.DeflateStream]::new($ms, [System.IO.Compression.CompressionMode]::Compress, $true)
            $deflateStream.Write($ScanlineData, 0, $ScanlineData.Length)
            $deflateStream.Dispose()

            # zlib wrapper: a 2-byte header the decoder strips off, then the raw DEFLATE data, then a 4-byte
            # trailer the decoder never reads (real PNGs put an Adler32 checksum there).
            $idatData = [byte[]]@(0x78, 0x9C) + $ms.ToArray() + [byte[]]::new(4)
            $ms.Dispose()
            $idat = New-XKCDTestPngChunk 'IDAT' $idatData

            $iend = New-XKCDTestPngChunk 'IEND' @()

            $signature + $ihdr + $plte + $trns + $idat + $iend
        }
    }

    Context 'ConvertFrom-XKCDPngBytes RGB Tests' {

        BeforeAll {
            # 2x2 RGB (colour type 2), one filter-type-0 (None) byte per row followed by 2 pixels of 3 bytes each.
            $ScanlineData = [byte[]]@(
                0, 255, 0, 0, 0, 255, 0
                0, 0, 0, 255, 255, 255, 255
            )
            $ImageBytes = New-XKCDTestPngBytes -Width 2 -Height 2 -BitDepth 8 -ColorType 2 -ScanlineData $ScanlineData
            $Decoded = ConvertFrom-XKCDTestPngBytes -ImageBytes $ImageBytes
        }

        It 'Returns the image dimensions from IHDR' {
            $Decoded.Width | Should -Be 2
            $Decoded.Height | Should -Be 2
        }

        It 'Decodes each pixel to its RGBA bytes, with alpha defaulted to opaque' {
            $Decoded.Pixels[0..3] | Should -Be @(255, 0, 0, 255)
            $Decoded.Pixels[4..7] | Should -Be @(0, 255, 0, 255)
            $Decoded.Pixels[8..11] | Should -Be @(0, 0, 255, 255)
            $Decoded.Pixels[12..15] | Should -Be @(255, 255, 255, 255)
        }
    }

    Context 'ConvertFrom-XKCDPngBytes RGBA Tests' {

        BeforeAll {
            # 2x1 RGBA (colour type 6), each pixel carrying its own alpha byte.
            $ScanlineData = [byte[]]@(0, 10, 20, 30, 128, 200, 150, 100, 255)
            $ImageBytes = New-XKCDTestPngBytes -Width 2 -Height 1 -BitDepth 8 -ColorType 6 -ScanlineData $ScanlineData
            $Decoded = ConvertFrom-XKCDTestPngBytes -ImageBytes $ImageBytes
        }

        It 'Preserves the per-pixel alpha channel' {
            $Decoded.Pixels[0..3] | Should -Be @(10, 20, 30, 128)
            $Decoded.Pixels[4..7] | Should -Be @(200, 150, 100, 255)
        }
    }

    Context 'ConvertFrom-XKCDPngBytes Palette Tests' {

        BeforeAll {
            $Palette = [byte[]]@(255, 0, 0, 0, 255, 0, 0, 0, 255)
            $Transparency = [byte[]]@(0, 255, 128)
            # 3x1 palette (colour type 3) image, one index byte per pixel.
            $ScanlineData = [byte[]]@(0, 0, 1, 2)
            $ImageBytes = New-XKCDTestPngBytes -Width 3 -Height 1 -BitDepth 8 -ColorType 3 -ScanlineData $ScanlineData -Palette $Palette -Transparency $Transparency
            $Decoded = ConvertFrom-XKCDTestPngBytes -ImageBytes $ImageBytes
        }

        It 'Looks up each pixel''s colour from PLTE by index' {
            $Decoded.Pixels[0..2] | Should -Be @(255, 0, 0)
            $Decoded.Pixels[4..6] | Should -Be @(0, 255, 0)
            $Decoded.Pixels[8..10] | Should -Be @(0, 0, 255)
        }

        It 'Looks up each pixel''s alpha from tRNS by index' {
            $Decoded.Pixels[3] | Should -Be 0
            $Decoded.Pixels[7] | Should -Be 255
            $Decoded.Pixels[11] | Should -Be 128
        }
    }

    Context 'ConvertFrom-XKCDPngBytes Sub-Byte Bit Depth Tests' {

        BeforeAll {
            # 8x1 1-bit grayscale (colour type 0): bits 10110010, MSB first.
            $ScanlineData = [byte[]]@(0, 0xB2)
            $ImageBytes = New-XKCDTestPngBytes -Width 8 -Height 1 -BitDepth 1 -ColorType 0 -ScanlineData $ScanlineData
            $Decoded = ConvertFrom-XKCDTestPngBytes -ImageBytes $ImageBytes
        }

        It 'Unpacks each 1-bit sample and scales it to a full-range grayscale byte' {
            $grays = 0..7 | ForEach-Object { $Decoded.Pixels[$_ * 4] }
            $grays | Should -Be @(255, 0, 255, 255, 0, 0, 255, 0)
        }
    }

    Context 'ConvertFrom-XKCDPngBytes Invalid Signature Tests' {

        It 'Throws when the bytes do not start with the PNG signature' {
            { ConvertFrom-XKCDTestPngBytes -ImageBytes ([byte[]]@(1, 2, 3, 4, 5, 6, 7, 8)) } | Should -Throw '*PNG*'
        }
    }

    Context 'ConvertFrom-XKCDPngBytes Interlaced Tests' {

        It 'Throws for an interlaced (Adam7) image' {
            $ScanlineData = [byte[]]@(0, 255, 0, 0)
            $ImageBytes = New-XKCDTestPngBytes -Width 1 -Height 1 -BitDepth 8 -ColorType 2 -ScanlineData $ScanlineData -Interlace 1
            { ConvertFrom-XKCDTestPngBytes -ImageBytes $ImageBytes } | Should -Throw '*interlaced*'
        }
    }
}
