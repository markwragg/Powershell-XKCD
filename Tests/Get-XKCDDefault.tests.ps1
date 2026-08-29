if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major
$Root = "$PSScriptRoot/../"
$Module = 'xkcd'

Describe "Unit Tests PS$PSVersion" {

    BeforeAll {
        $Root = "$PSScriptRoot/../"
        $Module = 'xkcd'

        Get-Module $Module | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module "$Root/$Module" -Force
    }

    Context 'Missing Defaults File Tests' {

        It 'Returns an object rather than $null when no defaults have been saved' {
            $DefaultsPath = Join-Path $TestDrive 'missing-defaults.json'

            $Result = Get-XKCDDefault -DefaultsPath $DefaultsPath

            $Result | Should -Not -Be $null
            $Result.HighQuality | Should -BeNullOrEmpty
        }
    }

    Context 'Existing Defaults File Tests' {

        It 'Returns the saved preferences' {
            $DefaultsPath = Join-Path $TestDrive 'existing-defaults.json'
            [pscustomobject]@{ HighQuality = $true; Path = 'C:\XKCD' } | ConvertTo-Json | Out-File $DefaultsPath

            $Result = Get-XKCDDefault -DefaultsPath $DefaultsPath

            $Result.HighQuality | Should -Be $true
            $Result.Path | Should -Be 'C:\XKCD'
        }
    }
}
