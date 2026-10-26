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

    Context 'Read-XKCDConsoleLine Tests' {

        # Read-XKCDConsoleLine exists purely so Read-XKCDComicNumberPrompt's blocking console input can be
        # mocked in tests -- there's nothing meaningful to assert about [Console]::ReadLine itself without
        # real typed input, so this just confirms the wrapper is callable and mockable.
        It 'Can be mocked to simulate typed input without blocking' {
            Mock -ModuleName $Module Read-XKCDConsoleLine { '353' }

            $Result = & $ModuleObj { Read-XKCDConsoleLine }

            $Result | Should -Be '353'
        }
    }
}
