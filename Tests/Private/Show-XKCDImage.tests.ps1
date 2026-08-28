if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major
$Root = "$PSScriptRoot/../.."
$Module = 'xkcd'

Get-Module $Module | Remove-Module -Force
Import-Module "$Root/$Module" -Force

$ModuleObj = Get-Module $Module

Function Get-XKCDCapturedOutput {
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

Describe "Unit Tests PS$PSVersion" {

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

            $Output | Should -Match ([regex]::Escape("$esc") + '_Ga=T,f=100,m=0;')
            $Output | Should -Match ([regex]::Escape("$esc\"))
        }

        It 'Chunks large images across multiple Kitty escape sequences' {
            $Output = Get-XKCDCapturedOutput {
                & $ModuleObj { Param($ImageBytes) Show-XKCDImage -ImageBytes $ImageBytes } $LargeImageBytes
            }

            $Output | Should -Match ([regex]::Escape("$esc") + '_Ga=T,f=100,m=1;')
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
            $Output | Should -Match ([regex]::Escape("$esc") + '\]1337;File=inline=1;size=10:')
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
