if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major
$Root = "$PSScriptRoot/../"
$Module = 'xkcd'

Get-Module $Module | Remove-Module -Force
Import-Module "$Root/$Module" -Force

Describe "Unit Tests PS$PSVersion" {

    Context 'Parameter Input Tests' {

        It 'Get-XKCDCache -Num rejects string input' {
            { Get-XKCDCache -Num Five } | Should Throw
        }
    }

    Context 'Cache Freshness Tests' {

        It 'Warns and returns nothing when no cache file exists' {
            $CachePath = Join-Path $TestDrive 'missing-cache.json'
            Mock -ModuleName $Module Invoke-RestMethod { [pscustomobject]@{ num = 100 } }

            $Result = Get-XKCDCache -CachePath $CachePath -WarningVariable CacheWarning -WarningAction SilentlyContinue

            $Result | Should BeNullOrEmpty
            $CacheWarning | Should Match 'No local cache was found'
        }

        It 'Warns but still returns the existing data when the cache is out of date' {
            $CachePath = Join-Path $TestDrive 'stale-cache.json'
            @(
                [pscustomobject]@{ num = 1; title = 'Comic 1' }
                [pscustomobject]@{ num = 2; title = 'Comic 2' }
            ) | ConvertTo-Json | Out-File $CachePath

            Mock -ModuleName $Module Invoke-RestMethod { [pscustomobject]@{ num = 5 } }

            $Result = Get-XKCDCache -CachePath $CachePath -WarningVariable CacheWarning -WarningAction SilentlyContinue

            @($Result).Count | Should Be 2
            $CacheWarning | Should Match 'out of date'
        }

        It 'Does not warn when the cache is already up to date' {
            $CachePath = Join-Path $TestDrive 'current-cache.json'
            @(
                [pscustomobject]@{ num = 1; title = 'Comic 1' }
                [pscustomobject]@{ num = 2; title = 'Comic 2' }
            ) | ConvertTo-Json | Out-File $CachePath

            Mock -ModuleName $Module Invoke-RestMethod { [pscustomobject]@{ num = 2 } }

            $Result = Get-XKCDCache -CachePath $CachePath -WarningVariable CacheWarning -WarningAction SilentlyContinue

            @($Result).Count | Should Be 2
            $CacheWarning | Should BeNullOrEmpty
        }

        It 'Does not modify the cache file when it is out of date' {
            $CachePath = Join-Path $TestDrive 'not-refreshed-cache.json'
            @(
                [pscustomobject]@{ num = 1; title = 'Comic 1' }
            ) | ConvertTo-Json | Out-File $CachePath

            Mock -ModuleName $Module Invoke-RestMethod { [pscustomobject]@{ num = 99 } }

            Get-XKCDCache -CachePath $CachePath -WarningAction SilentlyContinue | Out-Null

            $Cache = Get-Content $CachePath | ConvertFrom-Json
            @($Cache).Count | Should Be 1
        }
    }
}


Describe "Integration Tests PS$PSVersion" -tag 'Integration' {

    Context 'Module Tests' {

        It "Module '$Module' imports cleanly" {
            { Import-Module "$Root/$Module" -force } | Should Not Throw
        }
    }

    Context 'Default Cache Tests' {

        $All = Get-XKCDCache

        It 'Get-XKCDCache returns a PSCustomObject' {
            $All | Should BeOfType 'System.Management.Automation.PSCustomObject'
        }

        It 'Get-XKCDCache returns every cached comic' {
            @($All).Count | Should BeGreaterThan 3000
        }

        It 'Get-XKCDCache results have a num and title property' {
            $All | Select-Object -First 1 | ForEach-Object {
                $_.num | Should Not BeNullOrEmpty
                $_.title | Should Not BeNullOrEmpty
            }
        }
    }

    Context 'Num Filter Tests' {

        $Filtered = Get-XKCDCache -Num 4, 5, 6

        It 'Get-XKCDCache -Num returns only the specified comics' {
            @($Filtered).Count | Should Be 3
            @($Filtered.num | Sort-Object) | Should Be @(4, 5, 6)
        }

        It 'Get-XKCDCache -Num with a single number returns that comic' {
            $Single = Get-XKCDCache -Num 4
            @($Single).Count | Should Be 1
            $Single.num | Should Be 4
        }
    }

    Context 'Pipeline Input Tests' {

        It 'Get-XKCDCache accepts comic numbers via the pipeline' {
            $Piped = 4, 5, 6 | Get-XKCDCache
            @($Piped).Count | Should Be 3
            @($Piped.num | Sort-Object) | Should Be @(4, 5, 6)
        }
    }
}
