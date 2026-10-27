if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Unit Tests PS$PSVersion" {

    BeforeAll {
        $Root = "$PSScriptRoot/../.."
        $Module = 'xkcd'

        Get-Module $Module | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module "$Root/$Module" -Force

        $ModuleObj = Get-Module $Module
        $esc = [char]27
        $ImageBytes = [byte[]](1..10)

        function Get-XKCDCapturedOutput {
            Param(
                [scriptblock]$ScriptBlock
            )

            $OriginalOut = [Console]::Out
            $Writer = [System.IO.StringWriter]::new()

            try {
                [Console]::SetOut($Writer)
                & $ScriptBlock
            }
            finally {
                [Console]::SetOut($OriginalOut)
            }

            $Writer.ToString()
        }

        # Counts the spaces written before the image's escape sequence begins, i.e. the left padding used to
        # center it.
        function Get-XKCDLeadingSpaceCount ([string]$Output) {
            $Output.Substring(0, $Output.IndexOf($esc)).Length
        }
    }

    Context 'Show-XKCDTuiImage Kitty Centering Tests' {

        BeforeAll {
            Mock -ModuleName $Module Get-XKCDTerminalGraphicsProtocol { 'Kitty' }
            Mock -ModuleName $Module Get-XKCDImageSize { [pscustomobject]@{ Width = 400; Height = 200 } }
        }

        It 'Requests a column width from Kitty and centers using the same value' {
            # PixelWidth = min(400, 740) = 400; DisplayColumns = min(100-4, ceil(400/10)) = 40; Padding = floor((100-40)/2) = 30.
            $Output = Get-XKCDCapturedOutput {
                & $ModuleObj { Param($ImageBytes) Show-XKCDTuiImage -ImageBytes $ImageBytes -Width 100 } $ImageBytes
            }

            $Output | Should -Match ',c=40;'
            Get-XKCDLeadingSpaceCount $Output | Should -Be 30
        }

        It 'Raises the pixel width cap (and so the requested columns) when -HighQuality is specified' {
            Mock -ModuleName $Module Get-XKCDImageSize { [pscustomobject]@{ Width = 800; Height = 400 } }

            # Without -HighQuality: PixelWidth = min(800, 740) = 740; DisplayColumns = ceil(740/10) = 74.
            $Standard = Get-XKCDCapturedOutput {
                & $ModuleObj { Param($ImageBytes) Show-XKCDTuiImage -ImageBytes $ImageBytes -Width 100 } $ImageBytes
            }
            # With -HighQuality: PixelWidth = min(800, 925) = 800; DisplayColumns = ceil(800/10) = 80.
            $HighQuality = Get-XKCDCapturedOutput {
                & $ModuleObj { Param($ImageBytes) Show-XKCDTuiImage -ImageBytes $ImageBytes -Width 100 -HighQuality } $ImageBytes
            }

            $Standard | Should -Match ',c=74;'
            $HighQuality | Should -Match ',c=80;'
        }

        It 'Falls back to an assumed pixel width when the image size cannot be determined' {
            Mock -ModuleName $Module Get-XKCDImageSize { $null }

            # PixelWidth falls back to 740; DisplayColumns = min(100-4, ceil(740/10)) = min(96, 74) = 74.
            $Output = Get-XKCDCapturedOutput {
                & $ModuleObj { Param($ImageBytes) Show-XKCDTuiImage -ImageBytes $ImageBytes -Width 100 } $ImageBytes
            }

            $Output | Should -Match ',c=74;'
        }

        It 'Caps the requested columns to fit within a narrow console' {
            # DisplayColumns = min(20-4, ceil(400/10)) = min(16, 40) = 16.
            $Output = Get-XKCDCapturedOutput {
                & $ModuleObj { Param($ImageBytes) Show-XKCDTuiImage -ImageBytes $ImageBytes -Width 20 } $ImageBytes
            }

            $Output | Should -Match ',c=16;'
        }
    }

    Context 'Show-XKCDTuiImage iTerm2 Centering Tests' {

        BeforeAll {
            Mock -ModuleName $Module Get-XKCDTerminalGraphicsProtocol { 'iTerm2' }
            Mock -ModuleName $Module Get-XKCDImageSize { [pscustomobject]@{ Width = 400; Height = 200 } }
        }

        It 'Requests a cell width from iTerm2 and centers using the same value' {
            $Output = Get-XKCDCapturedOutput {
                & $ModuleObj { Param($ImageBytes) Show-XKCDTuiImage -ImageBytes $ImageBytes -Width 100 } $ImageBytes
            }

            $Output | Should -Match ';width=40:'
            Get-XKCDLeadingSpaceCount $Output | Should -Be 30
        }
    }

    Context 'Show-XKCDTuiImage Sixel Tests' {

        BeforeAll {
            Mock -ModuleName $Module Get-XKCDTerminalGraphicsProtocol { 'Sixel' }
            Mock -ModuleName $Module Get-XKCDImageSize { [pscustomobject]@{ Width = 400; Height = 200 } }
            Mock -ModuleName $Module ConvertTo-XKCDSixel { 'FAKE-SIXEL-DATA' }
        }

        It 'Writes the Sixel data with an estimated centering padding, without requesting a column width' {
            $Output = Get-XKCDCapturedOutput {
                & $ModuleObj { Param($ImageBytes) Show-XKCDTuiImage -ImageBytes $ImageBytes -Width 100 } $ImageBytes
            }

            $Output | Should -Match 'FAKE-SIXEL-DATA'
            $Output.Substring(0, $Output.IndexOf('FAKE-SIXEL-DATA')).Length | Should -Be 30
        }

        It 'Re-uses a cached render for the same -CacheKey instead of converting again' {
            $Cache = @{}

            1..2 | ForEach-Object {
                & $ModuleObj {
                    Param($ImageBytes, $Cache)
                    Show-XKCDTuiImage -ImageBytes $ImageBytes -Width 100 -Cache $Cache -CacheKey '1786|False'
                } $ImageBytes $Cache
            } | Out-Null

            Should -Invoke -CommandName ConvertTo-XKCDSixel -ModuleName $Module -Times 1 -Exactly
        }

        It 'Renders separately when -CacheKey differs' {
            $Cache = @{}

            & $ModuleObj {
                Param($ImageBytes, $Cache)
                Show-XKCDTuiImage -ImageBytes $ImageBytes -Width 100 -Cache $Cache -CacheKey '1786|False'
                Show-XKCDTuiImage -ImageBytes $ImageBytes -Width 100 -Cache $Cache -CacheKey '1787|False'
            } $ImageBytes $Cache

            Should -Invoke -CommandName ConvertTo-XKCDSixel -ModuleName $Module -Times 2 -Exactly
        }

        It 'Shows the large-image warning while converting, then clears it once the image is ready' {
            Mock -ModuleName $Module ConvertTo-XKCDSixel {
                Param($ImageBytes, $MaxWidth, $OnLargeImageWarning)
                & $OnLargeImageWarning 'This is a large image (999 x 999 pixels) - rendering it as Sixel may take a while.'
                'FAKE-SIXEL-DATA'
            }

            $Output = Get-XKCDCapturedOutput {
                & $ModuleObj { Param($ImageBytes) Show-XKCDTuiImage -ImageBytes $ImageBytes -Width 100 } $ImageBytes
            }

            $Output | Should -Match 'may take a while'
            $Output | Should -Match ([regex]::Escape("`r$esc[2K"))
            $Output | Should -Match 'FAKE-SIXEL-DATA'
        }
    }

    Context 'Show-XKCDTuiImage Unsupported Terminal Tests' {

        BeforeAll {
            Mock -ModuleName $Module Get-XKCDTerminalGraphicsProtocol { $null }
        }

        It 'Warns and writes nothing when no graphics protocol is detected' {
            $Output = Get-XKCDCapturedOutput {
                & $ModuleObj {
                    Param($ImageBytes)
                    Show-XKCDTuiImage -ImageBytes $ImageBytes -WarningAction SilentlyContinue
                } $ImageBytes
            }

            $Output | Should -BeNullOrEmpty
        }
    }

    Context 'Show-XKCDTuiImage Render Failure Tests' {

        BeforeAll {
            Mock -ModuleName $Module Get-XKCDTerminalGraphicsProtocol { 'Sixel' }
            Mock -ModuleName $Module ConvertTo-XKCDSixel { throw 'Simulated conversion failure' }
        }

        It 'Warns and does not throw when rendering the image fails' {
            {
                Get-XKCDCapturedOutput {
                    & $ModuleObj {
                        Param($ImageBytes)
                        Show-XKCDTuiImage -ImageBytes $ImageBytes -WarningAction SilentlyContinue
                    } $ImageBytes
                }
            } | Should -Not -Throw
        }
    }
}
