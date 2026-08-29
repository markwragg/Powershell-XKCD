if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Unit Tests PS$PSVersion" {

    BeforeAll {
        $Root = "$PSScriptRoot/../.."
        $Module = 'xkcd'

        Get-Module $Module | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module "$Root/$Module" -Force

        $ModuleObj = Get-Module $Module
    }

    Context 'Get-XKCDLastViewedComic Tests' {

        It 'Returns 0 when the state file does not exist' {
            $StatePath = Join-Path $TestDrive 'missing-state.json'

            $Result = & $ModuleObj { Param($StatePath) Get-XKCDLastViewedComic -StatePath $StatePath } $StatePath

            $Result | Should -Be 0
        }

        It 'Returns the recorded value when the state file exists' {
            $StatePath = Join-Path $TestDrive 'existing-state.json'
            [pscustomobject]@{ LastViewed = 42 } | ConvertTo-Json | Out-File $StatePath

            $Result = & $ModuleObj { Param($StatePath) Get-XKCDLastViewedComic -StatePath $StatePath } $StatePath

            $Result | Should -Be 42
        }
    }
}
