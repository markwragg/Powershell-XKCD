if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major
$Root = "$PSScriptRoot/../.."
$Module = 'xkcd'

Get-Module $Module | Remove-Module -Force
Import-Module "$Root/$Module" -Force

Describe "Unit Tests PS$PSVersion" {

    Context 'Get-XKCDTerminalGraphicsProtocol Tests' {

        # Preserve the real environment so detection of the terminal running these tests doesn't leak in/out
        $OriginalTerm = $env:TERM
        $OriginalKittyWindowId = $env:KITTY_WINDOW_ID
        $OriginalTermProgram = $env:TERM_PROGRAM
        $OriginalWtSession = $env:WT_SESSION

        BeforeEach {
            $env:TERM = $null
            $env:KITTY_WINDOW_ID = $null
            $env:TERM_PROGRAM = $null
            $env:WT_SESSION = $null
        }

        AfterAll {
            $env:TERM = $OriginalTerm
            $env:KITTY_WINDOW_ID = $OriginalKittyWindowId
            $env:TERM_PROGRAM = $OriginalTermProgram
            $env:WT_SESSION = $OriginalWtSession
        }

        It 'Returns $null when no known terminal environment variables are set' {
            InModuleScope $Module {
                Get-XKCDTerminalGraphicsProtocol | Should BeNullOrEmpty
            }
        }

        It "Returns 'Kitty' when TERM is 'xterm-kitty'" {
            $env:TERM = 'xterm-kitty'
            InModuleScope $Module {
                Get-XKCDTerminalGraphicsProtocol | Should Be 'Kitty'
            }
        }

        It "Returns 'Kitty' when KITTY_WINDOW_ID is set" {
            $env:KITTY_WINDOW_ID = '1'
            InModuleScope $Module {
                Get-XKCDTerminalGraphicsProtocol | Should Be 'Kitty'
            }
        }

        It "Returns 'Kitty' when TERM_PROGRAM is 'WezTerm'" {
            $env:TERM_PROGRAM = 'WezTerm'
            InModuleScope $Module {
                Get-XKCDTerminalGraphicsProtocol | Should Be 'Kitty'
            }
        }

        It "Returns 'Kitty' when TERM_PROGRAM is 'ghostty'" {
            $env:TERM_PROGRAM = 'ghostty'
            InModuleScope $Module {
                Get-XKCDTerminalGraphicsProtocol | Should Be 'Kitty'
            }
        }

        It "Returns 'iTerm2' when TERM_PROGRAM is 'iTerm.app'" {
            $env:TERM_PROGRAM = 'iTerm.app'
            InModuleScope $Module {
                Get-XKCDTerminalGraphicsProtocol | Should Be 'iTerm2'
            }
        }

        It "Returns 'Sixel' when WT_SESSION is set" {
            $env:WT_SESSION = [guid]::NewGuid().ToString()
            InModuleScope $Module {
                Get-XKCDTerminalGraphicsProtocol | Should Be 'Sixel'
            }
        }

        It 'Prefers Kitty detection over Windows Terminal Sixel detection' {
            $env:TERM = 'xterm-kitty'
            $env:WT_SESSION = [guid]::NewGuid().ToString()
            InModuleScope $Module {
                Get-XKCDTerminalGraphicsProtocol | Should Be 'Kitty'
            }
        }
    }
}
