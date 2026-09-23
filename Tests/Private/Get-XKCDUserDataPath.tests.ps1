if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Unit Tests PS$PSVersion" {

    BeforeAll {
        $Root = "$PSScriptRoot/../.."
        $Module = 'xkcd'

        Get-Module $Module | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module "$Root/$Module" -Force

        $ModuleObj = Get-Module $Module

        # A random file name per test run, so tests never collide with a real file a user might already have
        # in their actual per-user data directory, and cleanup only ever removes files these tests created.
        $TestFileName = "XKCD.test.$([guid]::NewGuid()).json"
        $ExpectedDirectory = Join-Path $HOME '.xkcd'
        $ExpectedPath = Join-Path $ExpectedDirectory $TestFileName
    }

    AfterAll {
        Remove-Item $ExpectedPath -Force -ErrorAction SilentlyContinue
    }

    Context 'Get-XKCDUserDataPath Tests' {

        It 'Returns a path for the given file name under a ''.xkcd'' folder in the user''s home directory' {
            $Result = & $ModuleObj { Param($FileName) Get-XKCDUserDataPath -FileName $FileName } $TestFileName

            $Result | Should -Be $ExpectedPath
        }

        It 'Creates the ''.xkcd'' directory if it does not already exist' {
            & $ModuleObj { Param($FileName) Get-XKCDUserDataPath -FileName $FileName } $TestFileName | Out-Null

            $ExpectedDirectory | Should -Exist
        }

        It 'Does not create the file itself, only the directory' {
            & $ModuleObj { Param($FileName) Get-XKCDUserDataPath -FileName $FileName } $TestFileName | Out-Null

            $ExpectedPath | Should -Not -Exist
        }
    }

    Context 'Get-XKCDUserDataPath Migration Tests' {

        BeforeAll {
            $LegacyDirectory = $TestDrive
            $LegacyPath = Join-Path $LegacyDirectory $TestFileName

            'legacy content' | Out-File $LegacyPath
        }

        AfterEach {
            Remove-Item $ExpectedPath -Force -ErrorAction SilentlyContinue
        }

        It 'Copies a file found in -LegacyDirectory over to the new location, if the new location has no file yet' {
            & $ModuleObj { Param($FileName, $Legacy) Get-XKCDUserDataPath -FileName $FileName -LegacyDirectory $Legacy } $TestFileName $LegacyDirectory | Out-Null

            $ExpectedPath | Should -Exist
            Get-Content $ExpectedPath | Should -Be 'legacy content'
        }

        It 'Does not overwrite a file already present at the new location' {
            'new content' | Out-File $ExpectedPath

            & $ModuleObj { Param($FileName, $Legacy) Get-XKCDUserDataPath -FileName $FileName -LegacyDirectory $Legacy } $TestFileName $LegacyDirectory | Out-Null

            Get-Content $ExpectedPath | Should -Be 'new content'
        }

        It 'Does nothing extra when no -LegacyDirectory is given and the file does not exist yet in the new location' {
            { & $ModuleObj { Param($FileName) Get-XKCDUserDataPath -FileName $FileName } $TestFileName } | Should -Not -Throw
            $ExpectedPath | Should -Not -Exist
        }
    }
}
