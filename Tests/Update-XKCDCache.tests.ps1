if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Unit Tests PS$PSVersion" {

    BeforeAll {
        $Root = "$PSScriptRoot/../"
        $Module = 'xkcd'

        Get-Module $Module | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module "$Root/$Module" -Force
    }

    Context 'Cache Creation Tests' {

        BeforeAll {
            Mock -ModuleName $Module Invoke-RestMethod {
                [pscustomobject]@{ num = 3 }
            } -ParameterFilter { $Uri -eq 'https://xkcd.com/info.0.json' }

            Mock -ModuleName $Module Invoke-RestMethod {
                $Num = [int][regex]::Match($Uri, '/(\d+)/info\.0\.json$').Groups[1].Value
                [pscustomobject]@{ num = $Num; title = "Comic $Num" }
            } -ParameterFilter { $Uri -match '^https://xkcd\.com/\d+/info\.0\.json$' }

            $CachePath = Join-Path $TestDrive 'new-cache.json'
        }

        It 'Creates a new cache file with every comic when none exists' {
            { Update-XKCDCache -CachePath $CachePath -WarningAction SilentlyContinue } | Should -Not -Throw

            $CachePath | Should -Exist

            $Cache = Get-Content $CachePath | ConvertFrom-Json
            $Cache.Count | Should -Be 3
            ($Cache | Sort-Object num).num | Should -Be @(1, 2, 3)
        }
    }

    Context 'Default CachePath Tests' {

        It 'Uses the module-relative cache path when -CachePath is not specified' {
            { Update-XKCDCache } | Should -Not -Throw
        }
    }

    Context 'Cache Already Up To Date Tests' {

        BeforeAll {
            Mock -ModuleName $Module Invoke-RestMethod {
                [pscustomobject]@{ num = 3 }
            } -ParameterFilter { $Uri -eq 'https://xkcd.com/info.0.json' }

            Mock -ModuleName $Module Invoke-RestMethod {
                throw "Should not fetch individual comics when the cache is already up to date: $Uri"
            } -ParameterFilter { $Uri -match '^https://xkcd\.com/\d+/info\.0\.json$' }

            $CachePath = Join-Path $TestDrive 'current-cache.json'
            @(
                [pscustomobject]@{ num = 1; title = 'Comic 1' }
                [pscustomobject]@{ num = 2; title = 'Comic 2' }
                [pscustomobject]@{ num = 3; title = 'Comic 3' }
            ) | ConvertTo-Json | Out-File $CachePath
        }

        It 'Does not query individual comics when the cache already contains the latest comic' {
            { Update-XKCDCache -CachePath $CachePath } | Should -Not -Throw

            $Cache = Get-Content $CachePath | ConvertFrom-Json
            $Cache.Count | Should -Be 3
        }
    }

    Context 'Cache Refresh Tests' {

        BeforeAll {
            Mock -ModuleName $Module Invoke-RestMethod {
                [pscustomobject]@{ num = 5 }
            } -ParameterFilter { $Uri -eq 'https://xkcd.com/info.0.json' }

            Mock -ModuleName $Module Invoke-RestMethod {
                $Num = [int][regex]::Match($Uri, '/(\d+)/info\.0\.json$').Groups[1].Value
                [pscustomobject]@{ num = $Num; title = "Comic $Num" }
            } -ParameterFilter { $Uri -match '^https://xkcd\.com/\d+/info\.0\.json$' }

            $CachePath = Join-Path $TestDrive 'stale-cache.json'
            @(
                [pscustomobject]@{ num = 1; title = 'Comic 1' }
                [pscustomobject]@{ num = 2; title = 'Comic 2' }
                [pscustomobject]@{ num = 3; title = 'Comic 3' }
            ) | ConvertTo-Json | Out-File $CachePath
        }

        It 'Refreshes the cache with newer comics when the server has newer comics than the cache' {
            { Update-XKCDCache -CachePath $CachePath -Verbose 4>$null } | Should -Not -Throw

            $Cache = Get-Content $CachePath | ConvertFrom-Json
            ($Cache | Where-Object num -eq 5) | Should -Not -BeNullOrEmpty
            ($Cache | Where-Object num -eq 4) | Should -Not -BeNullOrEmpty
            ($Cache | Measure-Object).Count | Should -BeGreaterThan 3
        }
    }
}
