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
    }

    Context 'Show-XKCDComic Tests' {

        BeforeAll {
            $Comic = [pscustomobject]@{
                num   = 1000
                title = 'A Test Comic'
                alt   = 'This is some alt text used to verify that Show-XKCDComic renders it below the image.'
            }
            $ImageBytes = [byte[]](1..10)

            Mock -ModuleName $Module Show-XKCDImage { }

            $Output = Get-XKCDCapturedOutput {
                & $ModuleObj {
                    Param($Comic, $ImageBytes)
                    Show-XKCDComic -Comic $Comic -ImageBytes $ImageBytes
                } $Comic $ImageBytes
            }
        }

        It 'Writes the comic number and title' {
            $Output | Should -Match '#1000: A Test Comic'
        }

        It 'Writes the alt text' {
            $Output | Should -Match 'This is some alt text used to verify'
        }

        It 'Delegates image rendering to Show-XKCDImage' {
            Should -Invoke -CommandName Show-XKCDImage -ModuleName $Module -Times 1 -Exactly -Scope Context
        }

        It 'Writes a hyperlink to the comic' {
            $Output | Should -Match '\x1b\]8;;https://xkcd\.com/1000\x1b\\https://xkcd\.com/1000\x1b\]8;;\x1b\\'
        }
    }

    Context 'Show-XKCDComic Date Tests' {

        BeforeAll {
            $Comic = [pscustomobject]@{
                num   = 1000
                title = 'A Test Comic'
                alt   = 'Some alt text.'
                year  = '2017'
                month = '1'
                day   = '16'
            }
            $ImageBytes = [byte[]](1..10)

            Mock -ModuleName $Module Show-XKCDImage { }

            $Output = Get-XKCDCapturedOutput {
                & $ModuleObj {
                    Param($Comic, $ImageBytes)
                    Show-XKCDComic -Comic $Comic -ImageBytes $ImageBytes
                } $Comic $ImageBytes
            }
        }

        It 'Writes the comic publish date when year, month, and day are present' {
            $Output | Should -Match '16 January 2017'
        }
    }

    Context 'Show-XKCDComic Error Handling Tests' {

        BeforeAll {
            $Comic = [pscustomobject]@{
                num   = 1
                title = 'Barrel - Part 1'
                alt   = 'Don''t we all.'
            }
            $ImageBytes = [byte[]](1..10)

            Mock -ModuleName $Module Show-XKCDImage { throw 'Simulated rendering failure' }
        }

        It 'Warns instead of throwing when rendering fails' {
            {
                Get-XKCDCapturedOutput {
                    & $ModuleObj {
                        Param($Comic, $ImageBytes)
                        Show-XKCDComic -Comic $Comic -ImageBytes $ImageBytes -WarningAction SilentlyContinue
                    } $Comic $ImageBytes
                }
            } | Should -Not -Throw
        }
    }
}
