if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Unit Tests PS$PSVersion" {

    BeforeAll {
        $Root = "$PSScriptRoot/../.."
        $Module = 'xkcd'

        Get-Module $Module | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module "$Root/$Module" -Force

        $ModuleObj = Get-Module $Module

        $Comic = @(
            [pscustomobject]@{ num = 1; title = 'Comic 1'; year = '2006'; month = '1'; day = '1' }
            [pscustomobject]@{ num = 2; title = 'Comic 2'; year = '2006'; month = '1'; day = '2' }
        )

        function Invoke-XKCDTestAdminCommand ([object[]]$Comic, [string[]]$Path, [string]$Line) {
            & $ModuleObj { Param($Comic, $Path, $Line) Invoke-XKCDAdminCommand -Comic $Comic -Path $Path -Line $Line } $Comic $Path $Line
        }
    }

    Context 'ls/dir Tests' {

        It 'Lists directories with a trailing slash' {
            $Result = Invoke-XKCDTestAdminCommand -Comic $Comic -Path @() -Line 'ls'

            $Result.Output | Should -Be '2006/'
        }

        It 'Lists files with their title alongside' {
            $Result = Invoke-XKCDTestAdminCommand -Comic $Comic -Path @('2006', '01') -Line 'ls'

            $Result.Output | Should -Be @("1.json`tComic 1", "2.json`tComic 2")
        }

        It 'dir is an alias for ls' {
            $Result = Invoke-XKCDTestAdminCommand -Comic $Comic -Path @() -Line 'dir'

            $Result.Output | Should -Be '2006/'
        }

        It 'Reports an empty directory rather than nothing' {
            $Result = Invoke-XKCDTestAdminCommand -Comic @() -Path @() -Line 'ls'

            $Result.Output | Should -Be '(empty)'
        }
    }

    Context 'cd Tests' {

        It 'Changes into an existing directory' {
            $Result = Invoke-XKCDTestAdminCommand -Comic $Comic -Path @() -Line 'cd 2006'

            $Result.Path | Should -Be @('2006')
            $Result.Output | Should -BeNullOrEmpty
        }

        It 'Reports an error and leaves the path unchanged for a directory that does not exist' {
            $Result = Invoke-XKCDTestAdminCommand -Comic $Comic -Path @('2006') -Line 'cd 1999'

            $Result.Path | Should -Be @('2006')
            $Result.Output | Should -Be 'cd: 1999: No such file or directory'
        }

        It 'Returns to the root when called with no argument' {
            $Result = Invoke-XKCDTestAdminCommand -Comic $Comic -Path @('2006', '01') -Line 'cd'

            $Result.Path | Should -BeNullOrEmpty
        }
    }

    Context 'pwd Tests' {

        It 'Prints "/" at the root' {
            $Result = Invoke-XKCDTestAdminCommand -Comic $Comic -Path @() -Line 'pwd'

            $Result.Output | Should -Be '/'
        }

        It 'Prints the full current path' {
            $Result = Invoke-XKCDTestAdminCommand -Comic $Comic -Path @('2006', '01') -Line 'pwd'

            $Result.Output | Should -Be '/2006/01'
        }
    }

    Context 'cat Tests' {

        It 'Prints the comic data as JSON for an existing file' {
            $Result = Invoke-XKCDTestAdminCommand -Comic $Comic -Path @('2006', '01') -Line 'cat 1.json'

            ($Result.Output -join "`n") | Should -Match '"num": 1'
            ($Result.Output -join "`n") | Should -Match '"title": "Comic 1"'
        }

        It 'Allows the ".json" extension to be omitted' {
            $Result = Invoke-XKCDTestAdminCommand -Comic $Comic -Path @('2006', '01') -Line 'cat 1'

            ($Result.Output -join "`n") | Should -Match '"num": 1'
        }

        It 'Reports an error for a file that does not exist' {
            $Result = Invoke-XKCDTestAdminCommand -Comic $Comic -Path @('2006', '01') -Line 'cat 99.json'

            $Result.Output | Should -Be 'cat: 99.json: No such file or directory'
        }

        It 'Reports a missing operand when no file is given' {
            $Result = Invoke-XKCDTestAdminCommand -Comic $Comic -Path @('2006', '01') -Line 'cat'

            $Result.Output | Should -Be 'cat: missing file operand'
        }
    }

    Context 'open/view Tests' {

        It 'Returns the comic number to jump to and signals exit' {
            $Result = Invoke-XKCDTestAdminCommand -Comic $Comic -Path @('2006', '01') -Line 'open 2'

            $Result.Jump | Should -Be 2
            $Result.Exit | Should -BeTrue
        }

        It 'view is an alias for open' {
            $Result = Invoke-XKCDTestAdminCommand -Comic $Comic -Path @('2006', '01') -Line 'view 1'

            $Result.Jump | Should -Be 1
            $Result.Exit | Should -BeTrue
        }

        It 'Reports an error and does not exit for a file that does not exist' {
            $Result = Invoke-XKCDTestAdminCommand -Comic $Comic -Path @('2006', '01') -Line 'open 99'

            $Result.Jump | Should -BeNullOrEmpty
            $Result.Exit | Should -BeFalse
        }
    }

    Context 'exit Tests' {

        It 'exit signals exit without a jump' {
            $Result = Invoke-XKCDTestAdminCommand -Comic $Comic -Path @() -Line 'exit'

            $Result.Exit | Should -BeTrue
            $Result.Jump | Should -BeNullOrEmpty
        }

        It 'quit and q are also recognised' {
            (Invoke-XKCDTestAdminCommand -Comic $Comic -Path @() -Line 'quit').Exit | Should -BeTrue
            (Invoke-XKCDTestAdminCommand -Comic $Comic -Path @() -Line 'q').Exit | Should -BeTrue
        }
    }

    Context 'Miscellaneous Tests' {

        It 'whoami prints root' {
            $Result = Invoke-XKCDTestAdminCommand -Comic $Comic -Path @() -Line 'whoami'

            $Result.Output | Should -Be 'root'
        }

        It 'An unrecognised command is reported the way a real shell would report it' {
            $Result = Invoke-XKCDTestAdminCommand -Comic $Comic -Path @() -Line 'frobnicate'

            $Result.Output | Should -Be 'frobnicate: command not found'
        }

        It 'A blank line produces no output and does not exit' {
            $Result = Invoke-XKCDTestAdminCommand -Comic $Comic -Path @() -Line '   '

            $Result.Output | Should -BeNullOrEmpty
            $Result.Exit | Should -BeFalse
        }
    }
}
