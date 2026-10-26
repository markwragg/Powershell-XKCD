if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Unit Tests PS$PSVersion" {

    BeforeAll {
        $Root = "$PSScriptRoot/../.."
        $Module = 'xkcd'

        Get-Module $Module | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module "$Root/$Module" -Force

        $ModuleObj = Get-Module $Module

        # System.Drawing.Common's Bitmap/Image/Graphics APIs are Windows-only from .NET 6 onwards, so this
        # suite also needs to pass on the Linux/macOS test runners it runs on -- matching how
        # Get-XKCDImageSize itself only exercises that fallback when running on Windows.
        $IsWindowsPlatform = (-not (Test-Path Variable:Global:IsWindows)) -or $IsWindows

        # Only the first 24 bytes (the 8-byte PNG signature and the IHDR chunk's width/height fields) are
        # ever read by Get-XKCDImageSize, so this doesn't need to be a fully valid/decodable PNG.
        function New-XKCDTestPngHeaderBytes ([int]$Width, [int]$Height) {
            function ConvertTo-XKCDTestBigEndianBytes ([int]$Value) {
                [byte[]]@(
                    [byte](($Value -shr 24) -band 0xFF),
                    [byte](($Value -shr 16) -band 0xFF),
                    [byte](($Value -shr 8) -band 0xFF),
                    [byte]($Value -band 0xFF)
                )
            }

            ([byte[]]@(137, 80, 78, 71, 13, 10, 26, 10)) +
            ([byte[]]@(0, 0, 0, 13)) +
            [System.Text.Encoding]::ASCII.GetBytes('IHDR') +
            (ConvertTo-XKCDTestBigEndianBytes $Width) +
            (ConvertTo-XKCDTestBigEndianBytes $Height) +
            ([byte[]]@(8, 2, 0, 0, 0))
        }
    }

    Context 'Get-XKCDImageSize PNG Tests' {

        It 'Reads width/height directly from the IHDR chunk' {
            $Bytes = New-XKCDTestPngHeaderBytes -Width 740 -Height 492

            $Result = & $ModuleObj { Param($Bytes) Get-XKCDImageSize -ImageBytes $Bytes } $Bytes

            $Result.Width | Should -Be 740
            $Result.Height | Should -Be 492
        }
    }

    Context 'Get-XKCDImageSize Non-PNG Tests' -Skip:(-not $IsWindowsPlatform) {

        BeforeAll {
            Add-Type -AssemblyName System.Drawing

            $Bitmap = [System.Drawing.Bitmap]::new(300, 150)
            $Stream = [System.IO.MemoryStream]::new()
            $Bitmap.Save($Stream, [System.Drawing.Imaging.ImageFormat]::Jpeg)
            $JpegBytes = $Stream.ToArray()
            $Bitmap.Dispose()
            $Stream.Dispose()
        }

        It 'Falls back to System.Drawing for non-PNG images on Windows' {
            $Result = & $ModuleObj { Param($Bytes) Get-XKCDImageSize -ImageBytes $Bytes } $JpegBytes

            $Result.Width | Should -Be 300
            $Result.Height | Should -Be 150
        }
    }

    Context 'Get-XKCDImageSize Unrecognized Image Tests' -Skip:($IsWindowsPlatform) {

        It 'Returns $null for a non-PNG image when System.Drawing is unavailable' {
            $Bytes = [byte[]](1..10)

            $Result = & $ModuleObj { Param($Bytes) Get-XKCDImageSize -ImageBytes $Bytes } $Bytes

            $Result | Should -BeNullOrEmpty
        }
    }
}
