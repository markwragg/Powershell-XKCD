if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Unit Tests PS$PSVersion" {

    BeforeAll {
        $Root = "$PSScriptRoot/../.."
        $Module = 'xkcd'

        Get-Module $Module | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module "$Root/$Module" -Force

        $ModuleObj = Get-Module $Module

        $Result = & $ModuleObj { Get-XKCDBanner }
    }

    Context 'Get-XKCDBanner Tests' {

        It 'Returns at least one banner line' {
            $Result.Lines.Count | Should -BeGreaterThan 0
        }

        It 'Returns banner lines that are all the same length (so each centers consistently)' {
            ($Result.Lines | ForEach-Object Length | Sort-Object -Unique).Count | Should -Be 1
        }

        It 'Returns a non-empty tagline' {
            $Result.Tagline | Should -Not -BeNullOrEmpty
        }
    }
}
