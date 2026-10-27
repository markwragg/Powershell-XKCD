if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Unit Tests PS$PSVersion" {

    BeforeAll {
        $Root = "$PSScriptRoot/../.."
        $Module = 'xkcd'

        Get-Module $Module | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module "$Root/$Module" -Force

        $ModuleObj = Get-Module $Module

        $Comic = @(
            [pscustomobject]@{ num = 1; title = 'Comic 1'; year = '2006'; month = '1'; day = '1' }
            [pscustomobject]@{ num = 2; title = 'Comic 2'; year = '2006'; month = '1'; day = '2' }
            [pscustomobject]@{ num = 3; title = 'Comic 3'; year = '2006'; month = '2'; day = '1' }
            [pscustomobject]@{ num = 4; title = 'Comic 4'; year = '2007'; month = '1'; day = '1' }
        )

        function Get-XKCDTestArchiveEntry ([object[]]$Comic, [string[]]$Path) {
            & $ModuleObj { Param($Comic, $Path) Get-XKCDArchiveEntry -Comic $Comic -Path $Path } $Comic $Path
        }
    }

    Context 'Root Tests' {

        It 'Returns one directory per distinct year, sorted ascending' {
            $Result = Get-XKCDTestArchiveEntry -Comic $Comic -Path @()

            $Result.Name | Should -Be @('2006', '2007')
            $Result.Type | Should -Be @('Directory', 'Directory')
        }
    }

    Context 'Year Tests' {

        It 'Returns one directory per distinct month within that year, zero-padded and sorted ascending' {
            $Result = Get-XKCDTestArchiveEntry -Comic $Comic -Path @('2006')

            $Result.Name | Should -Be @('01', '02')
            $Result.Type | Should -Be @('Directory', 'Directory')
        }

        It 'Returns nothing for a year with no comics' {
            $Result = Get-XKCDTestArchiveEntry -Comic $Comic -Path @('1999')

            $Result | Should -BeNullOrEmpty
        }
    }

    Context 'Month Tests' {

        It 'Returns one file per comic in that year/month, sorted by comic number' {
            $Result = Get-XKCDTestArchiveEntry -Comic $Comic -Path @('2006', '01')

            $Result.Name | Should -Be @('1.json', '2.json')
            $Result.Type | Should -Be @('File', 'File')
        }

        It 'Attaches the underlying comic object to each file entry' {
            $Result = Get-XKCDTestArchiveEntry -Comic $Comic -Path @('2006', '01')

            $Result[0].Comic.title | Should -Be 'Comic 1'
        }

        It 'Matches the month numerically, so "1" and "01" are equivalent' {
            $Result = Get-XKCDTestArchiveEntry -Comic $Comic -Path @('2006', '1')

            $Result.Name | Should -Be @('1.json', '2.json')
        }
    }

    Context 'Beyond Month Tests' {

        It 'Returns nothing for a path deeper than year/month' {
            $Result = Get-XKCDTestArchiveEntry -Comic $Comic -Path @('2006', '01', '1.json')

            $Result | Should -BeNullOrEmpty
        }
    }
}
