if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Unit Tests PS$PSVersion" {

    BeforeAll {
        $Root = "$PSScriptRoot/../"
        $Module = 'xkcd'

        Get-Module $Module | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module "$Root/$Module" -Force
    }

    Context 'Saving Preferences Tests' {

        It 'Creates the defaults file and saves the specified preference' {
            $DefaultsPath = Join-Path $TestDrive 'new-defaults.json'

            Set-XKCDDefault -HighQuality -DefaultsPath $DefaultsPath | Out-Null

            $DefaultsPath | Should -Exist
            (Get-Content $DefaultsPath | ConvertFrom-Json).HighQuality | Should -Be $true
        }

        It 'Returns the resulting default preferences' {
            $DefaultsPath = Join-Path $TestDrive 'returned-defaults.json'

            $Result = Set-XKCDDefault -Path 'C:\XKCD' -DefaultsPath $DefaultsPath

            $Result.Path | Should -Be 'C:\XKCD'
        }

        It 'Only updates the specified preference, leaving others untouched' {
            $DefaultsPath = Join-Path $TestDrive 'merge-defaults.json'

            Set-XKCDDefault -HighQuality -DefaultsPath $DefaultsPath | Out-Null
            Set-XKCDDefault -Path 'C:\XKCD' -DefaultsPath $DefaultsPath | Out-Null

            $Saved = Get-Content $DefaultsPath | ConvertFrom-Json
            $Saved.HighQuality | Should -Be $true
            $Saved.Path | Should -Be 'C:\XKCD'
        }

        It 'Overwrites a previously saved preference when specified again' {
            $DefaultsPath = Join-Path $TestDrive 'overwrite-defaults.json'

            Set-XKCDDefault -CachePath 'C:\Old' -DefaultsPath $DefaultsPath | Out-Null
            Set-XKCDDefault -CachePath 'C:\New' -DefaultsPath $DefaultsPath | Out-Null

            (Get-Content $DefaultsPath | ConvertFrom-Json).CachePath | Should -Be 'C:\New'
        }

        It 'Explicitly saves -HighQuality:$false, overriding a previously saved true value' {
            $DefaultsPath = Join-Path $TestDrive 'false-default.json'

            Set-XKCDDefault -HighQuality -DefaultsPath $DefaultsPath | Out-Null
            Set-XKCDDefault -HighQuality:$false -DefaultsPath $DefaultsPath | Out-Null

            (Get-Content $DefaultsPath | ConvertFrom-Json).HighQuality | Should -Be $false
        }

        It 'Does not create a defaults file when no preference is specified' {
            $DefaultsPath = Join-Path $TestDrive 'untouched-defaults.json'

            Set-XKCDDefault -DefaultsPath $DefaultsPath | Out-Null

            $DefaultsPath | Should -Not -Exist
        }

        It 'Saves the Explanation, Transcript, Discussion and Full preferences used by Get-XKCDExplanation and Show-XKCDExplanation' {
            $DefaultsPath = Join-Path $TestDrive 'explanation-defaults.json'

            Set-XKCDDefault -Explanation -Transcript -Discussion -Full -DefaultsPath $DefaultsPath | Out-Null

            $Saved = Get-Content $DefaultsPath | ConvertFrom-Json
            $Saved.Explanation | Should -Be $true
            $Saved.Transcript | Should -Be $true
            $Saved.Discussion | Should -Be $true
            $Saved.Full | Should -Be $true
        }
    }

    Context 'Reset Tests' {

        It 'Removes the defaults file when -Reset is specified' {
            $DefaultsPath = Join-Path $TestDrive 'reset-defaults.json'
            Set-XKCDDefault -HighQuality -DefaultsPath $DefaultsPath | Out-Null

            Set-XKCDDefault -Reset -DefaultsPath $DefaultsPath | Out-Null

            $DefaultsPath | Should -Not -Exist
        }

        It 'Returns an empty object after resetting' {
            $DefaultsPath = Join-Path $TestDrive 'reset-return-defaults.json'
            Set-XKCDDefault -HighQuality -DefaultsPath $DefaultsPath | Out-Null

            $Result = Set-XKCDDefault -Reset -DefaultsPath $DefaultsPath

            $Result.HighQuality | Should -BeNullOrEmpty
        }

        It 'Does not throw when -Reset is specified and no defaults file exists' {
            $DefaultsPath = Join-Path $TestDrive 'reset-missing-defaults.json'

            { Set-XKCDDefault -Reset -DefaultsPath $DefaultsPath } | Should -Not -Throw
        }
    }

    Context 'WhatIf Tests' {

        It 'Does not save the preference when -WhatIf is specified' {
            $DefaultsPath = Join-Path $TestDrive 'whatif-defaults.json'

            Set-XKCDDefault -HighQuality -DefaultsPath $DefaultsPath -WhatIf | Out-Null

            $DefaultsPath | Should -Not -Exist
        }
    }
}
