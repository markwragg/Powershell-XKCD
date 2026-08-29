if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major
$Root = "$PSScriptRoot/../.."
$Module = 'xkcd'

Describe "Unit Tests PS$PSVersion" {

    BeforeAll {
        $Root = "$PSScriptRoot/../.."
        $Module = 'xkcd'

        Get-Module $Module | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module "$Root/$Module" -Force

        Add-Type -AssemblyName System.Drawing

        Function New-XKCDTestImageBytes {
            Param(
                [int]$Width = 4,
                [int]$Height = 4,
                [System.Drawing.Color]$Color = [System.Drawing.Color]::Red
            )

            $bitmap = [System.Drawing.Bitmap]::new($Width, $Height)

            for ($x = 0; $x -lt $Width; $x++) {
                for ($y = 0; $y -lt $Height; $y++) {
                    $bitmap.SetPixel($x, $y, $Color)
                }
            }

            $stream = [System.IO.MemoryStream]::new()
            $bitmap.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
            $bitmap.Dispose()

            , $stream.ToArray()
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
}
