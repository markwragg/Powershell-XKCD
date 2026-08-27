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

    Context 'Show-XKCDComic Tests' {

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

        It 'Writes the comic number and title' {
            $Output | Should Match '#1000: A Test Comic'
        }

        It 'Writes the alt text' {
            $Output | Should Match 'This is some alt text used to verify'
        }

        It 'Delegates image rendering to Show-XKCDImage' {
            Assert-MockCalled -ModuleName $Module Show-XKCDImage -Times 1 -Exactly
        }
    }

    Context 'Show-XKCDComic Error Handling Tests' {

        $Comic = [pscustomobject]@{
            num   = 1
            title = 'Barrel - Part 1'
            alt   = 'Don''t we all.'
        }
        $ImageBytes = [byte[]](1..10)

        Mock -ModuleName $Module Show-XKCDImage { throw 'Simulated rendering failure' }

        It 'Warns instead of throwing when rendering fails' {
            {
                Get-XKCDCapturedOutput {
                    & $ModuleObj {
                        Param($Comic, $ImageBytes)
                        Show-XKCDComic -Comic $Comic -ImageBytes $ImageBytes -WarningAction SilentlyContinue
                    } $Comic $ImageBytes
                }
            } | Should Not Throw
        }
    }
}
