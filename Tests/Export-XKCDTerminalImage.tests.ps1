if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Unit Tests PS$PSVersion" {

    BeforeAll {
        $Root = "$PSScriptRoot/../"
        $Module = 'xkcd'

        Get-Module $Module | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module "$Root/$Module" -Force
    }

    Context 'Parameter Input Tests' {

        It 'Export-XKCDTerminalImage -Num rejects string input' {
            { Export-XKCDTerminalImage -Num Five } | Should -Throw
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

    Context 'Unsupported Terminal Tests' {

        BeforeAll {
            Mock -ModuleName $Module Get-XKCDTerminalGraphicsProtocol { $null }
        }

        It 'Warns and saves nothing when no graphics protocol is detected' {
            { Export-XKCDTerminalImage -Num 1 -Path $TestDrive -WarningAction SilentlyContinue } | Should -Not -Throw
            Join-Path $TestDrive '1.xkcdterm.json' | Should -Not -Exist
        }
    }

    Context 'Export Tests' {

        BeforeAll {
            Mock -ModuleName $Module Get-XKCDTerminalGraphicsProtocol { 'Kitty' }

            $OutFile = Export-XKCDTerminalImage -Num 353 -Path $TestDrive -PassThru
        }

        It 'Saves a file named after the comic number' {
            $OutFile.FullName | Should -Be (Join-Path $TestDrive '353.xkcdterm.json')
        }

        It 'Saves the detected protocol and the rendered escape sequence' {
            $Saved = Get-Content $OutFile.FullName -Raw | ConvertFrom-Json

            $Saved.Num | Should -Be 353
            $Saved.Protocol | Should -Be 'Kitty'
            $Saved.Image | Should -Match ([regex]::Escape([char]27) + '_Ga=T,f=100,m=')
        }

        It 'Saves the other fields returned by Get-XKCD alongside the rendered image' {
            $Saved = Get-Content $OutFile.FullName -Raw | ConvertFrom-Json
            $Comic = Get-XKCD -Num 353

            $Saved.title | Should -Be $Comic.title
            $Saved.alt | Should -Be $Comic.alt
            $Saved.img | Should -Be $Comic.img
            $Saved.year | Should -Be $Comic.year
        }
    }

    Context 'PassThru Tests' {

        BeforeAll {
            Mock -ModuleName $Module Get-XKCDTerminalGraphicsProtocol { 'Kitty' }
        }

        It 'Does not return an object without -PassThru' {
            Export-XKCDTerminalImage -Num 353 -Path $TestDrive -Force | Should -BeNullOrEmpty
        }

        It 'Returns a FileInfo object with -PassThru' {
            $Result = Export-XKCDTerminalImage -Num 353 -Path $TestDrive -Force -PassThru
            $Result | Should -BeOfType [System.IO.FileInfo]
        }
    }

    Context 'WhatIf Tests' {

        BeforeAll {
            Mock -ModuleName $Module Get-XKCDTerminalGraphicsProtocol { 'Kitty' }
        }

        It 'Does not save a file when -WhatIf is specified' {
            Export-XKCDTerminalImage -Num 999 -Path $TestDrive -WhatIf
            Join-Path $TestDrive '999.xkcdterm.json' | Should -Not -Exist
        }
    }

    Context 'High Quality Tests' {

        BeforeAll {
            Mock -ModuleName $Module Get-XKCDTerminalGraphicsProtocol { 'Kitty' }
        }

        # Comic 1 does not have a higher resolution version available, so should fall back to standard quality
        It 'Falls back to standard quality when no _2x image is available' {
            { Export-XKCDTerminalImage -Num 1 -Path $TestDrive -HighQuality -Force -WarningAction SilentlyContinue } | Should -Not -Throw
            Join-Path $TestDrive '1.xkcdterm.json' | Should -Exist
        }
    }

    Context 'Overwrite Protection Tests' {

        BeforeAll {
            Mock -ModuleName $Module Get-XKCDTerminalGraphicsProtocol { 'Kitty' }

            Export-XKCDTerminalImage -Num 970 -Path $TestDrive | Out-Null
        }

        It 'Throws when the destination file already exists and -Force is not specified' {
            { Export-XKCDTerminalImage -Num 970 -Path $TestDrive } | Should -Throw
        }

        It 'Overwrites the destination file when -Force is specified' {
            { Export-XKCDTerminalImage -Num 970 -Path $TestDrive -Force } | Should -Not -Throw
        }
    }
}
