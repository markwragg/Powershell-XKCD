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

        It 'Import-XKCDTerminalImage -Path requires an input' {
            { Import-XKCDTerminalImage -Path } | Should -Throw
        }
    }
}


Describe "Integration Tests PS$PSVersion" -tag 'Integration' {

    BeforeAll {
        $Root = "$PSScriptRoot/../"
        $Module = 'xkcd'

        Get-Module $Module | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module "$Root/$Module" -Force

        # Import-XKCDTerminalImage writes the saved image straight to the console; running it here would
        # otherwise spam the real terminal with escape sequences every time these tests run.
        function Get-XKCDCapturedOutput {
            Param(
                [scriptblock]$ScriptBlock
            )

            $OriginalOut = [Console]::Out
            $Writer = [System.IO.StringWriter]::new()

            try {
                [Console]::SetOut($Writer)
                & $ScriptBlock
            }
            finally {
                [Console]::SetOut($OriginalOut)
            }

            $Writer.ToString()
        }
    }

    Context 'Module Tests' {

        It "Module '$Module' imports cleanly" {
            { Import-Module "$Root/$Module" -force } | Should -Not -Throw
        }
    }

    Context 'Missing File Tests' {

        It 'Warns and does not throw when the file does not exist' {
            $MissingPath = Join-Path $TestDrive 'missing.xkcdterm.json'

            { $script:Output = Get-XKCDCapturedOutput { Import-XKCDTerminalImage -Path $MissingPath -WarningAction SilentlyContinue } } | Should -Not -Throw
            $script:Output | Should -BeNullOrEmpty
        }
    }

    Context 'Replay Tests' {

        BeforeAll {
            $SavedPath = Join-Path $TestDrive 'replay.xkcdterm.json'
            [pscustomobject]@{ Num = 1; Protocol = 'Kitty'; Image = 'FAKE-KITTY-DATA' } | ConvertTo-Json | Out-File $SavedPath

            Mock -ModuleName $Module Get-XKCDTerminalGraphicsProtocol { 'Kitty' }
        }

        It 'Writes the saved image data to the console' {
            $Output = Get-XKCDCapturedOutput { Import-XKCDTerminalImage -Path $SavedPath }

            $Output | Should -Match 'FAKE-KITTY-DATA'
        }

        It 'Accepts the saved file path via the pipeline' {
            $Output = Get-XKCDCapturedOutput { $SavedPath | Import-XKCDTerminalImage }

            $Output | Should -Match 'FAKE-KITTY-DATA'
        }

        It 'Accepts a FileInfo object via the pipeline (e.g. from Get-ChildItem)' {
            $Output = Get-XKCDCapturedOutput { Get-Item $SavedPath | Import-XKCDTerminalImage }

            $Output | Should -Match 'FAKE-KITTY-DATA'
        }
    }

    Context 'Protocol Mismatch Tests' {

        BeforeAll {
            $SavedPath = Join-Path $TestDrive 'mismatch.xkcdterm.json'
            [pscustomobject]@{ Num = 1; Protocol = 'Sixel'; Image = 'FAKE-SIXEL-DATA' } | ConvertTo-Json | Out-File $SavedPath

            Mock -ModuleName $Module Get-XKCDTerminalGraphicsProtocol { 'Kitty' }
        }

        It 'Warns but still displays the image when the saved protocol does not match the current terminal' {
            { $script:Output = Get-XKCDCapturedOutput { Import-XKCDTerminalImage -Path $SavedPath -WarningAction SilentlyContinue } } | Should -Not -Throw
            $script:Output | Should -Match 'FAKE-SIXEL-DATA'
        }
    }

    Context 'Export then Import Round Trip Tests' {

        BeforeAll {
            Mock -ModuleName $Module Get-XKCDTerminalGraphicsProtocol { 'Kitty' }
        }

        It 'Displays the image exported by Export-XKCDTerminalImage without throwing' {
            {
                Get-XKCDCapturedOutput {
                    Export-XKCDTerminalImage -Num 353 -Path $TestDrive -Force -PassThru | Import-XKCDTerminalImage
                }
            } | Should -Not -Throw
        }
    }
}
