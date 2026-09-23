if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Unit Tests PS$PSVersion" {

    BeforeAll {
        $Root = "$PSScriptRoot/../.."
        $Module = 'xkcd'

        Get-Module $Module | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module "$Root/$Module" -Force

        Add-Type -AssemblyName System.Drawing

        # Builds a solid-colour PNG by hand rather than via System.Drawing.Bitmap/Save -- System.Drawing.Common's
        # Bitmap/Graphics/Image APIs are Windows-only from .NET 6 onwards (System.Drawing.Color itself, used only
        # for its RGB properties here, is a plain struct and isn't affected), so Bitmap throws on the Linux/macOS
        # test runners this suite also needs to pass on.
        function New-XKCDTestImageBytes {
            Param(
                [int]$Width = 4,
                [int]$Height = 4,
                [System.Drawing.Color]$Color = [System.Drawing.Color]::Red
            )

            function ConvertTo-XKCDTestBigEndianBytes ([int]$Value) {
                [byte[]]@(
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

            # 8-bit RGB (colour type 2), no interlacing.
            $ihdrData = (ConvertTo-XKCDTestBigEndianBytes $Width) + (ConvertTo-XKCDTestBigEndianBytes $Height) + [byte[]]@(8, 2, 0, 0, 0)
            $ihdr = New-XKCDTestPngChunk 'IHDR' $ihdrData

            $scanlineBytes = [System.Collections.Generic.List[byte]]::new()
            for ($y = 0; $y -lt $Height; $y++) {
                $scanlineBytes.Add(0) # filter type: None
                for ($x = 0; $x -lt $Width; $x++) {
                    $scanlineBytes.AddRange([byte[]]@($Color.R, $Color.G, $Color.B))
                }
            }

            $ms = [System.IO.MemoryStream]::new()
            $deflateStream = [System.IO.Compression.DeflateStream]::new($ms, [System.IO.Compression.CompressionMode]::Compress, $true)
            $deflateStream.Write($scanlineBytes.ToArray(), 0, $scanlineBytes.Count)
            $deflateStream.Dispose()

            # zlib wrapper: a 2-byte header the decoder strips off, then the raw DEFLATE data, then a 4-byte
            # trailer the decoder never reads (real PNGs put an Adler32 checksum there).
            $idatData = [byte[]]@(0x78, 0x9C) + $ms.ToArray() + [byte[]]::new(4)
            $ms.Dispose()
            $idat = New-XKCDTestPngChunk 'IDAT' $idatData

            $iend = New-XKCDTestPngChunk 'IEND' @()

            , ($signature + $ihdr + $idat + $iend)
        }

        $ModuleObj = Get-Module $Module
    }

    Context 'ConvertTo-XKCDSixel Tests' {

        BeforeAll {
            $esc = [char]27
            $ImageBytes = New-XKCDTestImageBytes -Width 4 -Height 4

            $Sixel = & $ModuleObj { Param($ImageBytes) ConvertTo-XKCDSixel -ImageBytes $ImageBytes } $ImageBytes
        }

        It 'Returns a string' {
            $Sixel | Should -BeOfType [string]
        }

        It 'Starts with the Sixel introducer for the image dimensions' {
            $Header = "$esc" + 'Pq"1;1;4;4'
            $Sixel.Substring(0, $Header.Length) | Should -Be $Header
        }

        It 'Ends with the Sixel string terminator' {
            $Sixel.Substring($Sixel.Length - 2) | Should -Be "$esc\"
        }

        It 'Includes at least one colour palette definition' {
            $Sixel | Should -Match '#0;2;\d+;\d+;\d+'
        }
    }

    Context 'ConvertTo-XKCDSixel MaxWidth Tests' {

        BeforeAll {
            $WideImageBytes = New-XKCDTestImageBytes -Width 10 -Height 4

            $Sixel = & $ModuleObj { Param($ImageBytes) ConvertTo-XKCDSixel -ImageBytes $ImageBytes -MaxWidth 5 } $WideImageBytes
        }

        It 'Downscales images wider than -MaxWidth, preserving aspect ratio' {
            $esc = [char]27
            $Header = "$esc" + 'Pq"1;1;5;2'
            $Sixel.Substring(0, $Header.Length) | Should -Be $Header
        }
    }

    Context 'ConvertTo-XKCDSixel Large Image Warning Tests' {

        BeforeAll {
            $ImageBytes = New-XKCDTestImageBytes -Width 4 -Height 4

            $AboveThresholdWarning = & $ModuleObj {
                Param($ImageBytes)
                ConvertTo-XKCDSixel -ImageBytes $ImageBytes -LargeImageThreshold 10 -WarningVariable CapturedWarning -WarningAction SilentlyContinue | Out-Null
                $CapturedWarning
            } $ImageBytes

            $BelowThresholdWarning = & $ModuleObj {
                Param($ImageBytes)
                ConvertTo-XKCDSixel -ImageBytes $ImageBytes -LargeImageThreshold 1000 -WarningVariable CapturedWarning -WarningAction SilentlyContinue | Out-Null
                $CapturedWarning
            } $ImageBytes

            $DefaultThresholdWarning = & $ModuleObj {
                Param($ImageBytes)
                ConvertTo-XKCDSixel -ImageBytes $ImageBytes -WarningVariable CapturedWarning -WarningAction SilentlyContinue | Out-Null
                $CapturedWarning
            } $ImageBytes
        }

        It 'Writes a warning when the pixel count (post-downscale) exceeds -LargeImageThreshold' {
            $AboveThresholdWarning | Should -Match 'large image'
        }

        It 'Does not write a warning when the pixel count is below -LargeImageThreshold' {
            $BelowThresholdWarning | Should -BeNullOrEmpty
        }

        It 'Uses a default threshold that does not warn for a typical comic-sized image' {
            $DefaultThresholdWarning | Should -BeNullOrEmpty
        }
    }
}
