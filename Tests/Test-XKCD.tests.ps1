if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Unit Tests PS$PSVersion" {

    BeforeAll {
        $Root = "$PSScriptRoot/../"
        $Module = 'xkcd'

        Get-Module $Module | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module "$Root/$Module" -Force
    }

    Context 'First Run Tests' {

        BeforeAll {
            Mock -ModuleName $Module Invoke-RestMethod { [pscustomobject]@{ num = 10 } }

            $StatePath = Join-Path $TestDrive 'missing-state.json'
        }

        It 'Returns $true when no local record of a previously viewed comic exists' {
            Test-XKCD -StatePath $StatePath -Quiet | Should -Be $true
        }

        It 'Does not create a state file' {
            $StatePath | Should -Not -Exist
        }
    }

    Context 'No New Comics Tests' {

        BeforeAll {
            Mock -ModuleName $Module Invoke-RestMethod { [pscustomobject]@{ num = 10 } }

            $StatePath = Join-Path $TestDrive 'current-state.json'
            [pscustomobject]@{ LastViewed = 10 } | ConvertTo-Json | Out-File $StatePath
        }

        It 'Returns $false when the last viewed comic matches the latest comic' {
            Test-XKCD -StatePath $StatePath -Quiet | Should -Be $false
        }
    }

    Context 'New Comics Tests' {

        BeforeAll {
            Mock -ModuleName $Module Invoke-RestMethod { [pscustomobject]@{ num = 15 } }

            $StatePath = Join-Path $TestDrive 'stale-state.json'
            [pscustomobject]@{ LastViewed = 10 } | ConvertTo-Json | Out-File $StatePath
        }

        It 'Returns $true when the latest comic is newer than the last viewed comic' {
            Test-XKCD -StatePath $StatePath -Quiet | Should -Be $true
        }
    }

    Context 'Default Message Tests' {

        BeforeAll {
            Mock -ModuleName $Module Invoke-RestMethod { [pscustomobject]@{ num = 15; year = 2024; month = 6; day = 10 } }
        }

        It 'Writes a friendly message including the new comic count, latest comic number and date' {
            $StatePath = Join-Path $TestDrive 'message-new-state.json'
            [pscustomobject]@{ LastViewed = 10 } | ConvertTo-Json | Out-File $StatePath

            $Message = Test-XKCD -StatePath $StatePath

            $Message | Should -Match '5 new XKCD comics'
            $Message | Should -Match '#15'
            $Message | Should -Match '10 June 2024'
        }

        It 'Uses singular wording when only one new comic is available' {
            $StatePath = Join-Path $TestDrive 'message-single-state.json'
            [pscustomobject]@{ LastViewed = 14 } | ConvertTo-Json | Out-File $StatePath

            $Message = Test-XKCD -StatePath $StatePath

            $Message | Should -Match '1 new XKCD comic '
        }

        It 'Writes a friendly message stating there are no new comics when up to date' {
            $StatePath = Join-Path $TestDrive 'message-none-state.json'
            [pscustomobject]@{ LastViewed = 15 } | ConvertTo-Json | Out-File $StatePath

            $Message = Test-XKCD -StatePath $StatePath

            $Message | Should -Match 'No new XKCD comics'
            $Message | Should -Match '#15'
        }
    }

    Context 'Default Message Without a Determinable Date' {

        BeforeAll {
            Mock -ModuleName $Module Invoke-RestMethod { [pscustomobject]@{ num = 15 } }
        }

        It 'Still writes a friendly message when the latest comic has no date fields' {
            $StatePath = Join-Path $TestDrive 'message-nodate-state.json'
            [pscustomobject]@{ LastViewed = 10 } | ConvertTo-Json | Out-File $StatePath

            $Message = Test-XKCD -StatePath $StatePath

            $Message | Should -Match '5 new XKCD comics'
            $Message | Should -Not -Match 'published'
        }
    }

    Context 'Detailed Output Tests' {

        BeforeAll {
            Mock -ModuleName $Module Invoke-RestMethod { [pscustomobject]@{ num = 15 } }

            $StatePath = Join-Path $TestDrive 'detailed-state.json'
            [pscustomobject]@{ LastViewed = 10 } | ConvertTo-Json | Out-File $StatePath

            $Result = Test-XKCD -StatePath $StatePath -Detailed
        }

        It 'Returns a PSCustomObject' {
            $Result | Should -BeOfType 'System.Management.Automation.PSCustomObject'
        }

        It 'Reports whether new comics are available' {
            $Result.HasNewComics | Should -Be $true
        }

        It 'Reports the number of new comics available' {
            $Result.NewComicCount | Should -Be 5
        }

        It 'Reports the previously last viewed comic number' {
            $Result.LastViewed | Should -Be 10
        }

        It 'Reports the latest comic number' {
            $Result.LatestComic | Should -Be 15
        }
    }

    Context 'Num Tests' {

        It 'Returns $true when the specified comic exists' {
            Mock -ModuleName $Module Invoke-RestMethod { [pscustomobject]@{ num = 42 } }

            Test-XKCD -Num 42 | Should -Be $true
        }

        It 'Returns $false when the specified comic does not exist' {
            Mock -ModuleName $Module Invoke-RestMethod { throw 'Response status code does not indicate success: 404 (Not Found).' }

            Test-XKCD -Num 999999 | Should -Be $false
        }

        It 'Does not allow -Num to be used with -Quiet' {
            { Test-XKCD -Num 1 -Quiet } | Should -Throw
        }

        It 'Does not allow -Num to be used with -Detailed' {
            { Test-XKCD -Num 1 -Detailed } | Should -Throw
        }
    }

    Context 'Read-Only Tests' {

        BeforeAll {
            Mock -ModuleName $Module Invoke-RestMethod { [pscustomobject]@{ num = 15 } }

            $StatePath = Join-Path $TestDrive 'readonly-state.json'
            [pscustomobject]@{ LastViewed = 10 } | ConvertTo-Json | Out-File $StatePath
        }

        It 'Does not update the state file, even when new comics are found' {
            Test-XKCD -StatePath $StatePath -Quiet | Out-Null

            (Get-Content $StatePath | ConvertFrom-Json).LastViewed | Should -Be 10
        }
    }
}


Describe "Integration Tests PS$PSVersion" -tag 'Integration' {

    BeforeAll {
        $Root = "$PSScriptRoot/../"
        $Module = 'xkcd'

        Get-Module $Module | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module "$Root/$Module" -Force
    }

    Context 'Module Tests' {

        It "Module '$Module' imports cleanly" {
            { Import-Module "$Root/$Module" -force } | Should -Not -Throw
        }
    }

    Context 'Default State Path Tests' {

        It 'Uses the module-relative state path when -StatePath is not specified' {
            { Test-XKCD -Quiet } | Should -Not -Throw
        }
    }
}
