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

    Context 'Show-XKCDComicImage Tests' {

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

        It 'Delegates image rendering to Show-XKCDImage' {
            Assert-MockCalled -ModuleName $Module Show-XKCDImage -Times 1 -Exactly
        }

        It 'Writes the alt text' {
            $Output | Should Match 'This is some alt text used to verify'
        }
    }

    Context 'Show-XKCDComicImage Wrapping Tests' {

        $Comic = [pscustomobject]@{
            num = 1000
            alt = 'One two three four five six seven eight nine ten'
        }
        $ImageBytes = [byte[]](1..10)

        Mock -ModuleName $Module Show-XKCDImage { }

        It 'Wraps the alt text onto multiple lines to fit the specified width' {
            $Output = Get-XKCDCapturedOutput {
                & $ModuleObj {
                    Param($Comic, $ImageBytes)
                    Show-XKCDComicImage -Comic $Comic -ImageBytes $ImageBytes -Width 10
                } $Comic $ImageBytes
            }

            ($Output -split "`r?`n") | Where-Object { $_ -match 'One' -and $_ -match 'ten' } | Should BeNullOrEmpty
        }
    }

    Context 'Show-XKCDComicImage No Alt Text Tests' {

        $Comic = [pscustomobject]@{ num = 1000 }
        $ImageBytes = [byte[]](1..10)

        Mock -ModuleName $Module Show-XKCDImage { }

        It 'Does not throw when the comic has no alt text' {
            {
                Get-XKCDCapturedOutput {
                    & $ModuleObj {
                        Param($Comic, $ImageBytes)
                        Show-XKCDComicImage -Comic $Comic -ImageBytes $ImageBytes
                    } $Comic $ImageBytes
                }
            } | Should Not Throw
        }
    }
}
