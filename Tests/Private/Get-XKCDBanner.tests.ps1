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

    Context 'Get-XKCDBanner Seasonal Tests' {

        It 'Flanks a line with a random Halloween emoji in October' {
            Mock -ModuleName $Module Get-Date { [datetime]'2026-10-15' }

            1..10 | ForEach-Object {
                $October = & $ModuleObj { Get-XKCDBanner }

                ($October.Lines -join "`n") | Should -Match '🎃|👻|🦇|💀'
                ($October.Lines | ForEach-Object Length | Sort-Object -Unique).Count | Should -Be 1
            }
        }

        It 'Flanks a line with a random Christmas emoji in December' {
            Mock -ModuleName $Module Get-Date { [datetime]'2026-12-15' }

            1..10 | ForEach-Object {
                $December = & $ModuleObj { Get-XKCDBanner }

                ($December.Lines -join "`n") | Should -Match '🎄|🎅|🎁|🔔'
                ($December.Lines | ForEach-Object Length | Sort-Object -Unique).Count | Should -Be 1
            }
        }

        It 'Adds no seasonal emoji outside of October/December' {
            Mock -ModuleName $Module Get-Date { [datetime]'2026-06-15' }

            $June = & $ModuleObj { Get-XKCDBanner }

            ($June.Lines -join "`n") | Should -Not -Match '🎃|👻|🦇|💀|🎄|🎅|🎁|🔔'
            ($June.Lines | ForEach-Object Length | Sort-Object -Unique).Count | Should -Be 1
        }
    }
}
