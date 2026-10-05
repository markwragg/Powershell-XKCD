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

    Context 'Number Tests' {

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

        It 'Test-XKCD -Num is an alias for -Number' {
            Mock -ModuleName $Module Invoke-RestMethod { [pscustomobject]@{ num = 42 } }

            Test-XKCD -Num 42 | Should -Be $true
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

    Context 'AddToProfile Tests' {

        BeforeEach {
            $script:OriginalProfile = $global:PROFILE
            $script:FakeProfile = Join-Path $TestDrive 'profile.ps1'
            Remove-Item $script:FakeProfile -Force -ErrorAction SilentlyContinue
            $global:PROFILE = $script:FakeProfile
        }

        AfterEach {
            $global:PROFILE = $script:OriginalProfile
        }

        It 'Creates the profile file if it does not already exist' {
            Test-XKCD -AddToProfile | Out-Null

            $script:FakeProfile | Should -Exist
        }

        It 'Creates the containing directory if it does not already exist' {
            $NestedProfile = Join-Path $TestDrive 'nested/sub/profile.ps1'
            $global:PROFILE = $NestedProfile

            Test-XKCD -AddToProfile | Out-Null

            $NestedProfile | Should -Exist
        }

        It 'Adds the line to the profile' {
            Test-XKCD -AddToProfile | Out-Null

            Get-Content $script:FakeProfile -Raw | Should -Match ([regex]::Escape('if (Test-XKCD -Quiet) { Test-XKCD }'))
        }

        It 'Does not add the line again on a second call' {
            Test-XKCD -AddToProfile | Out-Null
            Test-XKCD -AddToProfile | Out-Null

            @(Get-Content $script:FakeProfile | Select-String -SimpleMatch 'if (Test-XKCD -Quiet) { Test-XKCD }').Count | Should -Be 1
        }

        It 'Does not add the line again if it was already present some other way' {
            Set-Content -Path $script:FakeProfile -Value 'if (Test-XKCD -Quiet) { Test-XKCD }'

            Test-XKCD -AddToProfile | Out-Null

            @(Get-Content $script:FakeProfile | Select-String -SimpleMatch 'if (Test-XKCD -Quiet) { Test-XKCD }').Count | Should -Be 1
        }

        It 'Does not create the profile file when -WhatIf is specified' {
            Test-XKCD -AddToProfile -WhatIf | Out-Null

            $script:FakeProfile | Should -Not -Exist
        }

        It 'Returns a confirmation message including the profile path' {
            $Message = Test-XKCD -AddToProfile

            $Message | Should -Match 'Added'
            $Message | Should -Match ([regex]::Escape($script:FakeProfile))
        }

        It 'Returns a message stating the line is already present, on a second call' {
            Test-XKCD -AddToProfile | Out-Null
            $Message = Test-XKCD -AddToProfile

            $Message | Should -Match 'already present'
        }
    }

    Context 'RemoveFromProfile Tests' {

        BeforeEach {
            $script:OriginalProfile = $global:PROFILE
            $script:FakeProfile = Join-Path $TestDrive 'profile.ps1'
            Remove-Item $script:FakeProfile -Force -ErrorAction SilentlyContinue
            $global:PROFILE = $script:FakeProfile
        }

        AfterEach {
            $global:PROFILE = $script:OriginalProfile
        }

        It 'Does nothing and returns a message when the profile does not exist' {
            $Message = Test-XKCD -RemoveFromProfile

            $script:FakeProfile | Should -Not -Exist
            $Message | Should -Match 'not found'
        }

        It 'Does nothing and returns a message when the profile exists but does not contain the line' {
            Set-Content -Path $script:FakeProfile -Value 'Write-Host "hello"'

            $Message = Test-XKCD -RemoveFromProfile

            Get-Content $script:FakeProfile -Raw | Should -Match 'hello'
            $Message | Should -Match 'not found'
        }

        It 'Removes a line added by -AddToProfile, along with its comment and blank line' {
            Test-XKCD -AddToProfile | Out-Null

            Test-XKCD -RemoveFromProfile | Out-Null

            Get-Content $script:FakeProfile -Raw | Should -BeNullOrEmpty
        }

        It 'Removes a line that was added some other way, without touching surrounding content' {
            Set-Content -Path $script:FakeProfile -Value @(
                'Write-Host "hello"'
                'if (Test-XKCD -Quiet) { Test-XKCD }'
                'Write-Host "world"'
            )

            Test-XKCD -RemoveFromProfile | Out-Null

            $Remaining = Get-Content $script:FakeProfile
            $Remaining | Should -Not -Contain 'if (Test-XKCD -Quiet) { Test-XKCD }'
            $Remaining | Should -Contain 'Write-Host "hello"'
            $Remaining | Should -Contain 'Write-Host "world"'
        }

        It 'Removes every occurrence if the line appears more than once' {
            Set-Content -Path $script:FakeProfile -Value @(
                'if (Test-XKCD -Quiet) { Test-XKCD }'
                'if (Test-XKCD -Quiet) { Test-XKCD }'
            )

            Test-XKCD -RemoveFromProfile | Out-Null

            @(Get-Content $script:FakeProfile | Select-String -SimpleMatch 'if (Test-XKCD -Quiet) { Test-XKCD }').Count | Should -Be 0
        }

        It 'Does not modify the file when -WhatIf is specified' {
            Set-Content -Path $script:FakeProfile -Value 'if (Test-XKCD -Quiet) { Test-XKCD }'

            Test-XKCD -RemoveFromProfile -WhatIf | Out-Null

            Get-Content $script:FakeProfile -Raw | Should -Match ([regex]::Escape('if (Test-XKCD -Quiet) { Test-XKCD }'))
        }

        It 'Returns a confirmation message including the profile path when removed' {
            Set-Content -Path $script:FakeProfile -Value 'if (Test-XKCD -Quiet) { Test-XKCD }'

            $Message = Test-XKCD -RemoveFromProfile

            $Message | Should -Match 'Removed'
            $Message | Should -Match ([regex]::Escape($script:FakeProfile))
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
