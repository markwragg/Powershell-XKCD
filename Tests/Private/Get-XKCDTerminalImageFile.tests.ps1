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

    Context 'Missing File Tests' {

        It 'Warns and returns nothing when the file does not exist' {
            $MissingPath = Join-Path $TestDrive 'missing.xkcdterm.json'

            $Result = & $ModuleObj {
                Param($Path)
                Get-XKCDTerminalImageFile -Path $Path -WarningAction SilentlyContinue
            } $MissingPath

            $Result | Should -BeNullOrEmpty
        }
    }

    Context 'Unreadable File Tests' {

        BeforeAll {
            $BadPath = Join-Path $TestDrive 'bad.xkcdterm.json'
            'not valid json {{{' | Out-File $BadPath

            Mock -ModuleName $Module Get-XKCDTerminalGraphicsProtocol { 'Kitty' }
        }

        It 'Warns and returns nothing when the file cannot be parsed' {
            $Result = & $ModuleObj {
                Param($Path)
                Get-XKCDTerminalImageFile -Path $Path -WarningAction SilentlyContinue
            } $BadPath

            $Result | Should -BeNullOrEmpty
        }
    }

    Context 'Matching Protocol Tests' {

        BeforeAll {
            $SavedPath = Join-Path $TestDrive 'match.xkcdterm.json'
            [pscustomobject]@{ Num = 1; Protocol = 'Kitty'; Image = 'FAKE-KITTY-DATA' } | ConvertTo-Json | Out-File $SavedPath

            Mock -ModuleName $Module Get-XKCDTerminalGraphicsProtocol { 'Kitty' }
        }

        It 'Returns the saved object' {
            $Result = & $ModuleObj {
                Param($Path)
                Get-XKCDTerminalImageFile -Path $Path -WarningAction SilentlyContinue
            } $SavedPath

            $Result.Image | Should -Be 'FAKE-KITTY-DATA'
        }
    }

    Context 'Mismatched Protocol Tests' {

        BeforeAll {
            $SavedPath = Join-Path $TestDrive 'mismatch.xkcdterm.json'
            [pscustomobject]@{ Num = 1; Protocol = 'Sixel'; Image = 'FAKE-SIXEL-DATA' } | ConvertTo-Json | Out-File $SavedPath

            Mock -ModuleName $Module Get-XKCDTerminalGraphicsProtocol { 'Kitty' }
        }

        It 'Still returns the saved object when the protocol does not match' {
            $Result = & $ModuleObj {
                Param($Path)
                Get-XKCDTerminalImageFile -Path $Path -WarningAction SilentlyContinue
            } $SavedPath

            $Result.Image | Should -Be 'FAKE-SIXEL-DATA'
        }
    }

    Context 'No Protocol Detected Tests' {

        BeforeAll {
            $SavedPath = Join-Path $TestDrive 'no-protocol.xkcdterm.json'
            [pscustomobject]@{ Num = 1; Protocol = 'Sixel'; Image = 'FAKE-SIXEL-DATA' } | ConvertTo-Json | Out-File $SavedPath

            Mock -ModuleName $Module Get-XKCDTerminalGraphicsProtocol { $null }
        }

        It 'Still returns the saved object when the current terminal has no detected protocol' {
            $Result = & $ModuleObj {
                Param($Path)
                Get-XKCDTerminalImageFile -Path $Path -WarningAction SilentlyContinue
            } $SavedPath

            $Result.Image | Should -Be 'FAKE-SIXEL-DATA'
        }
    }
}
