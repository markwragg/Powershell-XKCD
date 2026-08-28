if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major
$Root = "$PSScriptRoot/../.."
$Module = 'xkcd'

Get-Module $Module | Remove-Module -Force
Import-Module "$Root/$Module" -Force

$ModuleObj = Get-Module $Module

Describe "Unit Tests PS$PSVersion" {

    Context 'Get-XKCDDefaultValue Tests' {

        It 'Returns the fallback value when no default has been saved' {
            Mock -ModuleName $Module Get-XKCDDefault { [pscustomobject]@{} }

            $Result = & $ModuleObj { Get-XKCDDefaultValue -Name 'HighQuality' -Value 'FALLBACK' }

            $Result | Should -Be 'FALLBACK'
        }

        It 'Returns the saved default value when one exists' {
            Mock -ModuleName $Module Get-XKCDDefault { [pscustomobject]@{ HighQuality = $true } }

            $Result = & $ModuleObj { Get-XKCDDefaultValue -Name 'HighQuality' -Value $false }

            $Result | Should -Be $true
        }

        It 'Returns a saved default of $false rather than the fallback' {
            Mock -ModuleName $Module Get-XKCDDefault { [pscustomobject]@{ HighQuality = $false } }

            $Result = & $ModuleObj { Get-XKCDDefaultValue -Name 'HighQuality' -Value $true }

            $Result | Should -Be $false
        }
    }
}
