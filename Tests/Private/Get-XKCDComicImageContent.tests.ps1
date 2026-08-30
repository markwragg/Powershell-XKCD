if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Integration Tests PS$PSVersion" -tag 'Integration' {

    BeforeAll {
        $Root = "$PSScriptRoot/../.."
        $Module = 'xkcd'

        Get-Module $Module | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module "$Root/$Module" -Force

        $ModuleObj = Get-Module $Module
    }

    Context 'Get-XKCDComicImageContent Tests' {

        BeforeAll {
            $Comic = Get-XKCD -Num 353
        }

        It 'Returns the image bytes for the comic' {
            $Result = & $ModuleObj { Param($Comic) Get-XKCDComicImageContent -Comic $Comic } $Comic

            $Result.Count | Should -BeGreaterThan 0
        }
    }

    Context 'Get-XKCDComicImageContent High Quality Tests' {

        BeforeAll {
            # Comic 3290 is known to have a higher resolution (_2x) version available
            $Comic = Get-XKCD -Num 3290
        }

        It 'Returns a larger image when -HighQuality is specified and a _2x version is available' {
            $Standard = & $ModuleObj { Param($Comic) Get-XKCDComicImageContent -Comic $Comic } $Comic
            $HighQuality = & $ModuleObj { Param($Comic) Get-XKCDComicImageContent -Comic $Comic -HighQuality } $Comic

            $HighQuality.Length | Should -BeGreaterThan $Standard.Length
        }
    }

    Context 'Get-XKCDComicImageContent High Quality Fallback Tests' {

        BeforeAll {
            # Comic 1 does not have a higher resolution version available, so should fall back to standard quality
            $Comic = Get-XKCD -Num 1
        }

        It 'Falls back to standard quality without throwing when no _2x image is available' {
            {
                & $ModuleObj {
                    Param($Comic)
                    Get-XKCDComicImageContent -Comic $Comic -HighQuality -WarningAction SilentlyContinue
                } $Comic
            } | Should -Not -Throw
        }
    }
}
