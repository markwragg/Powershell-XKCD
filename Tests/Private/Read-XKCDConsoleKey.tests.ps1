if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Unit Tests PS$PSVersion" {

    BeforeAll {
        $Root = "$PSScriptRoot/../.."
        $Module = 'xkcd'

        Get-Module $Module | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module "$Root/$Module" -Force

        $ModuleObj = Get-Module $Module
    }

    Context 'Read-XKCDConsoleKey Tests' {

        # Read-XKCDConsoleKey exists purely so Start-XKCD's blocking console input can be mocked in tests --
        # there's nothing meaningful to assert about [Console]::ReadKey itself without a real keypress, so
        # this just confirms the wrapper is callable and mockable (used throughout Tests/Start-XKCD.tests.ps1).
        It 'Can be mocked to simulate a keypress without blocking' {
            Mock -ModuleName $Module Read-XKCDConsoleKey { [System.ConsoleKeyInfo]::new([char]0, [System.ConsoleKey]::Escape, $false, $false, $false) }

            $Result = & $ModuleObj { Read-XKCDConsoleKey }

            $Result.Key | Should -Be ([System.ConsoleKey]::Escape)
        }
    }
}
