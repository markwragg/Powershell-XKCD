if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major
$Root = "$PSScriptRoot/../"
$Module = 'xkcd'

Get-Module $Module | Remove-Module -Force
Import-Module "$Root/$Module" -Force

Describe "Unit Tests PS$PSVersion" {

    Context 'Parameter Input Tests' {

        It 'Find-XKCD -Query requires an input' {
            { Find-XKCD -Query } | Should -Throw
        }
    }
}


Describe "Integration Tests PS$PSVersion" -tag 'Integration' {

    BeforeAll {
        $Root = "$PSScriptRoot/../"
        $Module = 'xkcd'

        Get-Module $Module | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module "$Root/$Module" -Force
    }

    Context 'Module Tests' {

        It "Module '$Module' imports cleanly" {
            { Import-Module "$Root/$Module" -force } | Should -Not -Throw
        }
    }

    Context 'Default Comic Tests' {

        BeforeAll {
            $Default = Find-XKCD -Query 'Spiders'
        }

        It 'Find-XKCD returns a PSCustomObject' {
            $Default | Should -BeOfType 'System.Management.Automation.PSCustomObject'
        }

        It "Find-XKCD returns 4 comics" {
            $Default.count | Should -Be 4
        }

        It "Find-XKCD tags each result with a 'query' NoteProperty matching the search term" {
            $Default | ForEach-Object { $_.query | Should -Be 'Spiders' }
        }
    }

    Context 'Pipeline Input Tests' {

        BeforeAll {
            $Piped = 'Spiders' | Find-XKCD
            $Multiple = 'Spiders', 'Robots' | Find-XKCD
        }

        It 'Find-XKCD accepts the query via the pipeline' {
            $Piped.count | Should -Be 4
        }

        It 'Find-XKCD accepts multiple queries via the pipeline' {
            @($Multiple | Where-Object query -eq 'Spiders').Count | Should -Be 4
            @($Multiple | Where-Object query -eq 'Robots').Count | Should -Be 1
        }
    }

    Context 'FullSearch Tests' {

        BeforeAll {
            $TitleOnly = Find-XKCD -Query 'guitar'
            $FullSearch = Find-XKCD -Query 'guitar' -FullSearch
        }

        It 'Find-XKCD without -FullSearch only matches against the title' {
            @($TitleOnly).Count | Should -Be 1
        }

        It 'Find-XKCD -FullSearch matches against the whole comic object, not just the title' {
            @($FullSearch).Count | Should -Be 10
        }

        It "Find-XKCD -FullSearch still tags each result with a 'query' NoteProperty" {
            $FullSearch | ForEach-Object { $_.query | Should -Be 'guitar' }
        }
    }
}
