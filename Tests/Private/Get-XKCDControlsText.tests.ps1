if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Unit Tests PS$PSVersion" {

    BeforeAll {
        $Root = "$PSScriptRoot/../.."
        $Module = 'xkcd'

        Get-Module $Module | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module "$Root/$Module" -Force

        $ModuleObj = Get-Module $Module

        $Result = & $ModuleObj { Get-XKCDControlsText }
    }

    Context 'Get-XKCDControlsText Tests' {

        It 'Describes every available control, with the hotkey letter bracketed' {
            $Result | Should -Match '\[G\]o to'
            $Result | Should -Match '\[F\]irst'
            $Result | Should -Match '\[P\]revious'
            $Result | Should -Match '\[R\]andom'
            $Result | Should -Match '\[N\]ext'
            $Result | Should -Match '\[L\]ast'
            $Result | Should -Match '\[Q\]uit'
        }

        It 'Uses only plain ASCII (no arrow glyphs, which do not render in every terminal)' {
            $Result | Should -Match '^[\x00-\x7F]*$'
        }

        It 'Includes plain ASCII directional arrows alongside Previous/Next' {
            $Result | Should -Match '<-\s*\[P\]revious'
            $Result | Should -Match '\[N\]ext\s*->'
        }
    }
}
