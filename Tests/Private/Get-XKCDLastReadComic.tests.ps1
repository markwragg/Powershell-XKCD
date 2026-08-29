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

    Context 'Get-XKCDLastReadComic Tests' {

        It 'Returns 0 when the state file does not exist' {
            $StatePath = Join-Path $TestDrive 'missing-state.json'

            $Result = & $ModuleObj { Param($StatePath) Get-XKCDLastReadComic -StatePath $StatePath } $StatePath

            $Result | Should -Be 0
        }

        It 'Returns the recorded LastRead value when present' {
            $StatePath = Join-Path $TestDrive 'lastread-state.json'
            [pscustomobject]@{ LastViewed = 42; LastRead = 30 } | ConvertTo-Json | Out-File $StatePath

            $Result = & $ModuleObj { Param($StatePath) Get-XKCDLastReadComic -StatePath $StatePath } $StatePath

            $Result | Should -Be 30
        }

        It 'Falls back to the LastViewed value when no LastRead value is present' {
            $StatePath = Join-Path $TestDrive 'legacy-state.json'
            [pscustomobject]@{ LastViewed = 42 } | ConvertTo-Json | Out-File $StatePath

            $Result = & $ModuleObj { Param($StatePath) Get-XKCDLastReadComic -StatePath $StatePath } $StatePath

            $Result | Should -Be 42
        }
    }
}
