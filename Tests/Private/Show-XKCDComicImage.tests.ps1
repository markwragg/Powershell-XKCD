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

    Context 'Show-XKCDComicImage Tests' {

        BeforeAll {
            $Comic = [pscustomobject]@{
                num = 1000
                alt = 'This is some alt text used to verify that Show-XKCDComicImage renders it below the image.'
            }
            $ImageBytes = [byte[]](1..10)

            Mock -ModuleName $Module Show-XKCDImage { }

            $Output = Get-XKCDCapturedOutput {
                & $ModuleObj {
                    Param($Comic, $ImageBytes)
                    Show-XKCDComicImage -Comic $Comic -ImageBytes $ImageBytes
                } $Comic $ImageBytes
            }
        }

        It 'Delegates image rendering to Show-XKCDImage' {
            Should -Invoke -CommandName Show-XKCDImage -ModuleName $Module -Times 1 -Exactly -Scope Context
        }

        It 'Writes the alt text' {
            $Output | Should -Match 'This is some alt text used to verify'
        }
    }

    Context 'Show-XKCDComicImage Wrapping Tests' {

        BeforeAll {
            $Comic = [pscustomobject]@{
                num = 1000
                alt = 'One two three four five six seven eight nine ten'
            }
            $ImageBytes = [byte[]](1..10)

            Mock -ModuleName $Module Show-XKCDImage { }
        }

        It 'Wraps the alt text onto multiple lines to fit the specified width' {
            $Output = Get-XKCDCapturedOutput {
                & $ModuleObj {
                    Param($Comic, $ImageBytes)
                    Show-XKCDComicImage -Comic $Comic -ImageBytes $ImageBytes -Width 10
                } $Comic $ImageBytes
            }

            ($Output -split "`r?`n") | Where-Object { $_ -match 'One' -and $_ -match 'ten' } | Should -BeNullOrEmpty
        }
    }

    Context 'Show-XKCDComicImage No Alt Text Tests' {

        BeforeAll {
            $Comic = [pscustomobject]@{ num = 1000 }
            $ImageBytes = [byte[]](1..10)

            Mock -ModuleName $Module Show-XKCDImage { }
        }

        It 'Does not throw when the comic has no alt text' {
            {
                Get-XKCDCapturedOutput {
                    & $ModuleObj {
                        Param($Comic, $ImageBytes)
                        Show-XKCDComicImage -Comic $Comic -ImageBytes $ImageBytes
                    } $Comic $ImageBytes
                }
            } | Should -Not -Throw
        }
    }
}
