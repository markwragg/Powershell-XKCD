if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Unit Tests PS$PSVersion" {

    BeforeAll {
        $Root = "$PSScriptRoot/../.."
        $Module = 'xkcd'

        Get-Module $Module | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module "$Root/$Module" -Force

        $ModuleObj = Get-Module $Module

        function Get-XKCDTestComicMetaText {
            Param([pscustomobject]$Comic)

            & $ModuleObj { Param($Comic) Get-XKCDComicMetaText -Comic $Comic } $Comic
        }
    }

    Context 'Get-XKCDComicMetaText Tests' {

        BeforeAll {
            $Comic = [pscustomobject]@{ num = 1786; year = '2017'; month = '1'; day = '16' }
            $Result = Get-XKCDTestComicMetaText -Comic $Comic
        }

        It 'Includes the formatted publish date' {
            $Result | Should -Match '16 January 2017'
        }

        It 'Includes a hyperlink to the comic' {
            $Result | Should -Match "$([char]27)\]8;;https://xkcd\.com/1786$([char]27)\\https://xkcd\.com/1786$([char]27)\]8;;$([char]27)\\"
        }
    }

    Context 'Get-XKCDComicMetaText Without Date Tests' {

        BeforeAll {
            $Comic = [pscustomobject]@{ num = 1786 }
            $Result = Get-XKCDTestComicMetaText -Comic $Comic
        }

        It 'Falls back to just the hyperlink when year, month, or day is missing' {
            $Result | Should -Not -Match 'January|February|March|April|May|June|July|August|September|October|November|December'
            $Result | Should -Match 'https://xkcd\.com/1786'
        }
    }
}
