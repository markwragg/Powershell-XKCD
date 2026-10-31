if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Unit Tests PS$PSVersion" {

    BeforeAll {
        $Root = "$PSScriptRoot/../.."
        $Module = 'xkcd'

        Get-Module $Module | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module "$Root/$Module" -Force

        $ModuleObj = Get-Module $Module

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
    }

    Context 'Show-XKCDImage Kitty Tests' {

        BeforeAll {
            $esc = [char]27
            $SmallImageBytes = [byte[]](1..10)
            $LargeImageBytes = [byte[]](1..4000 | ForEach-Object { $_ % 256 })

            Mock -ModuleName $Module Get-XKCDTerminalGraphicsProtocol { 'Kitty' }
        }

        It 'Writes a single Kitty graphics escape sequence for small images' {
            $Output = Get-XKCDCapturedOutput {
                & $ModuleObj { Param($ImageBytes) Show-XKCDImage -ImageBytes $ImageBytes } $SmallImageBytes
            }

            # Now also requests an explicit column count (so Kitty scales the image to fit exactly, rather
            # than leaving a partial trailing cell row of background padding under it) -- hence ",c=<n>"
            # before the first chunk's terminating ";", rather than "m=0;" directly.
            $Output | Should -Match ([regex]::Escape("$esc") + '_Ga=T,f=100,m=0,c=\d+;')
            $Output | Should -Match ([regex]::Escape("$esc\"))
        }

        It 'Chunks large images across multiple Kitty escape sequences' {
            $Output = Get-XKCDCapturedOutput {
                & $ModuleObj { Param($ImageBytes) Show-XKCDImage -ImageBytes $ImageBytes } $LargeImageBytes
            }

            $Output | Should -Match ([regex]::Escape("$esc") + '_Ga=T,f=100,m=1,c=\d+;')
            $Output | Should -Match ([regex]::Escape("$esc") + '_Gm=0;')
        }
    }

    Context 'Show-XKCDImage iTerm2 Tests' {

        BeforeAll {
            $esc = [char]27
            $bel = [char]7
            $ImageBytes = [byte[]](1..10)

            Mock -ModuleName $Module Get-XKCDTerminalGraphicsProtocol { 'iTerm2' }

            $Output = Get-XKCDCapturedOutput {
                & $ModuleObj { Param($ImageBytes) Show-XKCDImage -ImageBytes $ImageBytes } $ImageBytes
            }
        }

        It 'Writes an iTerm2 inline image escape sequence' {
            # Now also requests an explicit width (so iTerm2 scales the image to fit exactly, rather than
            # leaving a partial trailing cell row of background padding under it), hence ";width=<n>" before
            # the ":", rather than "size=10:" directly.
            $Output | Should -Match ([regex]::Escape("$esc") + '\]1337;File=inline=1;size=10;width=\d+:')
            $Output | Should -Match ([regex]::Escape("$bel"))
        }
    }

    Context 'Show-XKCDImage Sixel Tests' {

        BeforeAll {
            $ImageBytes = [byte[]](1..10)

            Mock -ModuleName $Module Get-XKCDTerminalGraphicsProtocol { 'Sixel' }
        }

        It 'Writes the Sixel data produced by ConvertTo-XKCDSixel' {
            Mock -ModuleName $Module ConvertTo-XKCDSixel { 'FAKE-SIXEL-DATA' }

            $Output = Get-XKCDCapturedOutput {
                & $ModuleObj { Param($ImageBytes) Show-XKCDImage -ImageBytes $ImageBytes } $ImageBytes
            }

            $Output | Should -Match 'FAKE-SIXEL-DATA'
        }

        It 'Warns and does not throw when Sixel conversion fails' {
            Mock -ModuleName $Module ConvertTo-XKCDSixel { throw 'Simulated conversion failure' }

            {
                Get-XKCDCapturedOutput {
                    & $ModuleObj {
                        Param($ImageBytes)
                        Show-XKCDImage -ImageBytes $ImageBytes -WarningAction SilentlyContinue
                    } $ImageBytes
                }
            } | Should -Not -Throw
        }
    }

    Context 'Show-XKCDImage Session Cache Tests' {

        BeforeAll {
            $ImageBytes = [byte[]](1..10)

            Mock -ModuleName $Module Get-XKCDTerminalGraphicsProtocol { 'Sixel' }
            Mock -ModuleName $Module ConvertTo-XKCDSixel { 'FAKE-SIXEL-DATA' }
        }

        BeforeEach {
            # The cache is a module-scoped variable (so it survives across separate Show-XKCD/
            # Show-XKCDExplanation calls, unlike Start-XKCD's own per-call -Cache hashtable) -- reset it before
            # each test so earlier tests in this context can't leave a stale entry behind.
            & $ModuleObj { $script:XKCDImageCache = @{} }
        }

        It 'Re-uses a cached render for the same -CacheKey instead of converting again' {
            1..2 | ForEach-Object {
                & $ModuleObj {
                    Param($ImageBytes)
                    Show-XKCDImage -ImageBytes $ImageBytes -CacheKey '1786|False'
                } $ImageBytes
            } | Out-Null

            Should -Invoke -CommandName ConvertTo-XKCDSixel -ModuleName $Module -Times 1 -Exactly
        }

        It 'Renders separately when -CacheKey differs' {
            & $ModuleObj {
                Param($ImageBytes)
                Show-XKCDImage -ImageBytes $ImageBytes -CacheKey '1786|False'
                Show-XKCDImage -ImageBytes $ImageBytes -CacheKey '1787|False'
            } $ImageBytes

            Should -Invoke -CommandName ConvertTo-XKCDSixel -ModuleName $Module -Times 2 -Exactly
        }

        It 'Renders fresh each time when no -CacheKey is supplied' {
            1..2 | ForEach-Object {
                & $ModuleObj {
                    Param($ImageBytes)
                    Show-XKCDImage -ImageBytes $ImageBytes
                } $ImageBytes
            } | Out-Null

            Should -Invoke -CommandName ConvertTo-XKCDSixel -ModuleName $Module -Times 2 -Exactly
        }
    }

    Context 'Show-XKCDImage Unsupported Terminal Tests' {

        BeforeAll {
            $ImageBytes = [byte[]](1..10)

            Mock -ModuleName $Module Get-XKCDTerminalGraphicsProtocol { $null }
        }

        It 'Warns and writes nothing when no graphics protocol is detected' {
            $Output = Get-XKCDCapturedOutput {
                & $ModuleObj {
                    Param($ImageBytes)
                    Show-XKCDImage -ImageBytes $ImageBytes -WarningAction SilentlyContinue
                } $ImageBytes
            }

            $Output | Should -BeNullOrEmpty
        }
    }
}
