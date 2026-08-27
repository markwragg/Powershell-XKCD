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

        # Restored after every test (not just once at the end) so that running these tests directly in an
        # interactive session -- where Invoke-Pester executes in-process against the real environment -- only
        # ever leaves the real terminal-detection variables cleared for the duration of a single test.
        AfterEach {
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

    Context 'VS Code Detection Tests' {

        # Preserve the real environment so detection of the terminal running these tests doesn't leak in/out
        $OriginalTerm = $env:TERM
        $OriginalKittyWindowId = $env:KITTY_WINDOW_ID
        $OriginalTermProgram = $env:TERM_PROGRAM
        $OriginalWtSession = $env:WT_SESSION

        BeforeEach {
            $env:TERM = $null
            $env:KITTY_WINDOW_ID = $null
            $env:TERM_PROGRAM = 'vscode'
            $env:WT_SESSION = $null

            # The "warn once" flag is module-scoped so it survives across calls within a session; reset it
            # before each test here so each test can rely on knowing whether it's the "first" call or not.
            InModuleScope $Module { $script:XKCDVSCodeImagesWarned = $null }
        }

        AfterEach {
            $env:TERM = $OriginalTerm
            $env:KITTY_WINDOW_ID = $OriginalKittyWindowId
            $env:TERM_PROGRAM = $OriginalTermProgram
            $env:WT_SESSION = $OriginalWtSession
        }

        It "Returns 'Sixel' when TERM_PROGRAM is 'vscode'" {
            InModuleScope $Module {
                Get-XKCDTerminalGraphicsProtocol -WarningAction SilentlyContinue | Should Be 'Sixel'
            }
        }

        It "Still warns when WT_SESSION is also set (e.g. inherited from launching VS Code inside Windows Terminal)" {
            $env:WT_SESSION = [guid]::NewGuid().ToString()
            InModuleScope $Module {
                Get-XKCDTerminalGraphicsProtocol -WarningVariable 'script:CapturedWarning' -WarningAction SilentlyContinue | Should Be 'Sixel'
                $script:CapturedWarning | Should Match 'terminal.integrated.enableImages'
            }
        }

        It 'Warns on the first call that VS Code images must be explicitly enabled' {
            InModuleScope $Module {
                Get-XKCDTerminalGraphicsProtocol -WarningVariable 'script:CapturedWarning' -WarningAction SilentlyContinue | Out-Null
                $script:CapturedWarning | Should Match 'terminal.integrated.enableImages'
            }
        }

        It 'Does not warn again on a subsequent call within the same session' {
            InModuleScope $Module {
                Get-XKCDTerminalGraphicsProtocol -WarningAction SilentlyContinue | Out-Null
                Get-XKCDTerminalGraphicsProtocol -WarningVariable 'script:CapturedWarning' -WarningAction SilentlyContinue | Out-Null
                $script:CapturedWarning | Should BeNullOrEmpty
            }
        }
    }
}
