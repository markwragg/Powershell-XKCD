if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Unit Tests PS$PSVersion" {

    BeforeAll {
        $Root = "$PSScriptRoot/../.."
        $Module = 'xkcd'

        Get-Module $Module | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module "$Root/$Module" -Force

        $ModuleObj = Get-Module $Module
        $ImageBytes = [byte[]](1..10)
    }

    Context 'Get-XKCDTerminalImageColumnCount Tests' {

        BeforeAll {
            Mock -ModuleName $Module Get-XKCDImageSize { [pscustomobject]@{ Width = 400; Height = 200 } }
        }

        It 'Derives columns from the image pixel width and an assumed cell width' {
            # PixelWidth = min(400, 740) = 400; Columns = ceil(400/10) = 40.
            $Result = & $ModuleObj { Param($ImageBytes) Get-XKCDTerminalImageColumnCount -ImageBytes $ImageBytes -Width 100 } $ImageBytes

            $Result | Should -Be 40
        }

        It 'Raises the pixel width cap (and so the column count) when -HighQuality is specified' {
            Mock -ModuleName $Module Get-XKCDImageSize { [pscustomobject]@{ Width = 800; Height = 400 } }

            # Without -HighQuality: PixelWidth = min(800, 740) = 740; Columns = ceil(740/10) = 74.
            $Standard = & $ModuleObj { Param($ImageBytes) Get-XKCDTerminalImageColumnCount -ImageBytes $ImageBytes -Width 100 } $ImageBytes
            # With -HighQuality: PixelWidth = min(800, 925) = 800; Columns = ceil(800/10) = 80.
            $HighQuality = & $ModuleObj { Param($ImageBytes) Get-XKCDTerminalImageColumnCount -ImageBytes $ImageBytes -Width 100 -HighQuality } $ImageBytes

            $Standard | Should -Be 74
            $HighQuality | Should -Be 80
        }

        It 'Caps the column count to fit within a narrow console' {
            # Columns = min(20-4, ceil(400/10)) = min(16, 40) = 16.
            $Result = & $ModuleObj { Param($ImageBytes) Get-XKCDTerminalImageColumnCount -ImageBytes $ImageBytes -Width 20 } $ImageBytes

            $Result | Should -Be 16
        }
    }

    Context 'Get-XKCDTerminalImageColumnCount Unknown Size Tests' {

        BeforeAll {
            Mock -ModuleName $Module Get-XKCDImageSize { $null }
        }

        It 'Falls back to an assumed pixel width when the image size cannot be determined' {
            # PixelWidth falls back to 740; Columns = min(100-4, ceil(740/10)) = min(96, 74) = 74.
            $Result = & $ModuleObj { Param($ImageBytes) Get-XKCDTerminalImageColumnCount -ImageBytes $ImageBytes -Width 100 } $ImageBytes

            $Result | Should -Be 74
        }
    }
}
