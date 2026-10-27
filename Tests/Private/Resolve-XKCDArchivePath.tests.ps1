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
            [pscustomobject]@{ num = 3; title = 'Comic 3'; year = '2007'; month = '1'; day = '1' }
        )

        function Resolve-XKCDTestArchivePath ([object[]]$Comic, [string[]]$CurrentPath, [string]$Target) {
            & $ModuleObj { Param($Comic, $CurrentPath, $Target) Resolve-XKCDArchivePath -Comic $Comic -CurrentPath $CurrentPath -Target $Target } $Comic $CurrentPath $Target
        }
    }

    Context 'Relative Path Tests' {

        It 'Resolves a single existing directory name from the root' {
            $Result = Resolve-XKCDTestArchivePath -Comic $Comic -CurrentPath @() -Target '2006'

            $Result.Path | Should -Be @('2006')
        }

        It 'Resolves a multi-segment relative path in one call' {
            $Result = Resolve-XKCDTestArchivePath -Comic $Comic -CurrentPath @() -Target '2006/01'

            $Result.Path | Should -Be @('2006', '01')
        }

        It 'Matches a month segment numerically, so "1" resolves the same as "01"' {
            $Result = Resolve-XKCDTestArchivePath -Comic $Comic -CurrentPath @('2006') -Target '1'

            $Result.Path | Should -Be @('2006', '01')
        }

        It 'Returns $null when a segment does not exist' {
            $Result = Resolve-XKCDTestArchivePath -Comic $Comic -CurrentPath @() -Target '1999'

            $Result | Should -BeNullOrEmpty
        }

        It 'Returns $null without changing path when only part of a multi-segment path exists' {
            $Result = Resolve-XKCDTestArchivePath -Comic $Comic -CurrentPath @() -Target '2006/99'

            $Result | Should -BeNullOrEmpty
        }
    }

    Context 'Absolute Path Tests' {

        It 'Resolves from the root regardless of the current path when the target starts with "/"' {
            $Result = Resolve-XKCDTestArchivePath -Comic $Comic -CurrentPath @('2007', '01') -Target '/2006'

            $Result.Path | Should -Be @('2006')
        }
    }

    Context 'Parent Directory Tests' {

        It 'Moves up one level for ".."' {
            $Result = Resolve-XKCDTestArchivePath -Comic $Comic -CurrentPath @('2006', '01') -Target '..'

            $Result.Path | Should -Be @('2006')
        }

        It 'Clamps at the root rather than erroring when ".." is used beyond it' {
            $Result = Resolve-XKCDTestArchivePath -Comic $Comic -CurrentPath @() -Target '..'

            $Result.Path | Should -BeNullOrEmpty
        }

        It 'Supports ".." combined with a further segment, e.g. "../2007"' {
            $Result = Resolve-XKCDTestArchivePath -Comic $Comic -CurrentPath @('2006', '01') -Target '../../2007'

            $Result.Path | Should -Be @('2007')
        }
    }
}
