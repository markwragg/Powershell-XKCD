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

        It 'Start-XKCD -Num rejects string input' {
            { Start-XKCD -Num Five } | Should -Throw
        }
        It 'Start-XKCD -Num is an alias for -Number' {
            (Get-Command Start-XKCD).Parameters['Number'].Aliases | Should -Contain 'Num'
        }
    }
}

Describe "Integration Tests PS$PSVersion" -tag 'Integration' {

    BeforeAll {
        $Root = "$PSScriptRoot/../"
        $Module = 'xkcd'

        Get-Module $Module | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module "$Root/$Module" -Force

        # Start-XKCD renders straight to the console and blocks on key input, so running it here would
        # otherwise spam the real terminal and hang waiting for a real keypress every time these tests run.
        # Start-XKCD itself is called directly throughout (it's exported, so it's always resolved against
        # whichever module instance is currently loaded) -- never via the "& (Get-Module $Module) { ... }"
        # indirection some other private-function tests use, since re-importing the module anywhere in this
        # file (e.g. the "Module Tests" context below) would silently invalidate a module reference captured
        # ahead of time, leaving later calls routed through it running against a stale, unmocked instance.
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

        function New-XKCDTestKey ([System.ConsoleKey]$Key) {
            [System.ConsoleKeyInfo]::new([char]0, $Key, $false, $false, $false)
        }

        # Queues a scripted sequence of keypresses for Read-XKCDConsoleKey (mocked per-test) to return one at
        # a time, so each test's navigation through Start-XKCD's loop is deterministic and never blocks.
        function Set-XKCDTestKeySequence ([System.ConsoleKey[]]$Keys) {
            $script:XKCDTestKeyQueue = [System.Collections.Generic.Queue[System.ConsoleKeyInfo]]::new([System.ConsoleKeyInfo[]]@($Keys | ForEach-Object { New-XKCDTestKey $_ }))
        }
    }

    Context 'Module Tests' {

        It "Module '$Module' imports cleanly" {
            { Import-Module "$Root/$Module" -force } | Should -Not -Throw
        }
    }

    Context 'Offline Navigation Tests' {

        BeforeAll {
            $CachePath = Join-Path $TestDrive 'start-xkcd-cache.json'
            @(
                [pscustomobject]@{ num = 1; title = 'Comic 1'; img = 'https://imgs.xkcd.com/comics/comic1.jpg'; alt = 'Alt 1'; year = '2006'; month = '1'; day = '1' }
                [pscustomobject]@{ num = 2; title = 'Comic 2'; img = 'https://imgs.xkcd.com/comics/comic2.png'; alt = 'Alt 2'; year = '2006'; month = '1'; day = '2' }
                [pscustomobject]@{ num = 3; title = 'Comic 3'; img = 'https://imgs.xkcd.com/comics/comic3.jpg'; alt = 'Alt 3'; year = '2006'; month = '1'; day = '3' }
            ) | ConvertTo-Json | Out-File $CachePath

            $DownloadPath = Join-Path $TestDrive 'start-xkcd-downloads'
            New-Item -ItemType Directory -Path $DownloadPath -Force | Out-Null

            Mock -ModuleName $Module Read-XKCDConsoleKey { $script:XKCDTestKeyQueue.Dequeue() }
        }

        It 'Opens on the latest cached comic by default' {
            Set-XKCDTestKeySequence 'Escape'

            $Output = Get-XKCDCapturedOutput {
                Start-XKCD -Offline -CachePath $CachePath -DownloadPath $DownloadPath -WarningAction SilentlyContinue
            }

            $Output | Should -Match 'Comic 3'
        }

        It 'Opens on the comic specified via -Number' {
            Set-XKCDTestKeySequence 'Escape'

            $Output = Get-XKCDCapturedOutput {
                Start-XKCD -Number 1 -Offline -CachePath $CachePath -DownloadPath $DownloadPath -WarningAction SilentlyContinue
            }

            $Output | Should -Match 'Comic 1'
            $Output | Should -Not -Match 'Comic 2|Comic 3'
        }

        It 'Q also exits the viewer' {
            Set-XKCDTestKeySequence 'Q'

            {
                Get-XKCDCapturedOutput {
                    Start-XKCD -Offline -CachePath $CachePath -DownloadPath $DownloadPath -WarningAction SilentlyContinue
                }
            } | Should -Not -Throw
        }

        It 'Right arrow advances to the next comic, left arrow returns to the previous one' {
            $RecordedNums = [System.Collections.Generic.List[int]]::new()
            Mock -ModuleName $Module Show-XKCDTuiFrame { $RecordedNums.Add($Comic.num) }
            Set-XKCDTestKeySequence 'RightArrow', 'LeftArrow', 'Escape'

            Get-XKCDCapturedOutput {
                Start-XKCD -Number 1 -Offline -CachePath $CachePath -DownloadPath $DownloadPath -WarningAction SilentlyContinue
            } | Out-Null

            $RecordedNums | Should -Be @(1, 2, 1)
        }

        It 'Right arrow does nothing once the latest comic is reached' {
            $RecordedNums = [System.Collections.Generic.List[int]]::new()
            Mock -ModuleName $Module Show-XKCDTuiFrame { $RecordedNums.Add($Comic.num) }
            Set-XKCDTestKeySequence 'RightArrow', 'RightArrow', 'Escape'

            Get-XKCDCapturedOutput {
                Start-XKCD -Number 3 -Offline -CachePath $CachePath -DownloadPath $DownloadPath -WarningAction SilentlyContinue
            } | Out-Null

            $RecordedNums | Should -Be @(3, 3, 3)
        }

        It 'Left arrow does nothing once comic #1 is reached' {
            $RecordedNums = [System.Collections.Generic.List[int]]::new()
            Mock -ModuleName $Module Show-XKCDTuiFrame { $RecordedNums.Add($Comic.num) }
            Set-XKCDTestKeySequence 'LeftArrow', 'LeftArrow', 'Escape'

            Get-XKCDCapturedOutput {
                Start-XKCD -Number 1 -Offline -CachePath $CachePath -DownloadPath $DownloadPath -WarningAction SilentlyContinue
            } | Out-Null

            $RecordedNums | Should -Be @(1, 1, 1)
        }

        It 'N and P are equivalent to the right/left arrow keys' {
            $RecordedNums = [System.Collections.Generic.List[int]]::new()
            Mock -ModuleName $Module Show-XKCDTuiFrame { $RecordedNums.Add($Comic.num) }
            Set-XKCDTestKeySequence 'N', 'P', 'Escape'

            Get-XKCDCapturedOutput {
                Start-XKCD -Number 1 -Offline -CachePath $CachePath -DownloadPath $DownloadPath -WarningAction SilentlyContinue
            } | Out-Null

            $RecordedNums | Should -Be @(1, 2, 1)
        }

        It 'R displays a random comic between 1 and the latest cached comic' {
            $RecordedNums = [System.Collections.Generic.List[int]]::new()
            Mock -ModuleName $Module Show-XKCDTuiFrame { $RecordedNums.Add($Comic.num) }
            Mock -ModuleName $Module Get-Random { 2 }
            Set-XKCDTestKeySequence 'R', 'Escape'

            Get-XKCDCapturedOutput {
                Start-XKCD -Number 1 -Offline -CachePath $CachePath -DownloadPath $DownloadPath -WarningAction SilentlyContinue
            } | Out-Null

            $RecordedNums | Should -Be @(1, 2)
            Should -Invoke -CommandName Get-Random -ModuleName $Module -Times 1 -Exactly -ParameterFilter {
                $Minimum -eq 1 -and $Maximum -eq 4
            }
        }

        It 'F jumps straight to the first comic' {
            $RecordedNums = [System.Collections.Generic.List[int]]::new()
            Mock -ModuleName $Module Show-XKCDTuiFrame { $RecordedNums.Add($Comic.num) }
            Set-XKCDTestKeySequence 'F', 'Escape'

            Get-XKCDCapturedOutput {
                Start-XKCD -Number 3 -Offline -CachePath $CachePath -DownloadPath $DownloadPath -WarningAction SilentlyContinue
            } | Out-Null

            $RecordedNums | Should -Be @(3, 1)
        }

        It 'L jumps straight to the latest comic' {
            $RecordedNums = [System.Collections.Generic.List[int]]::new()
            Mock -ModuleName $Module Show-XKCDTuiFrame { $RecordedNums.Add($Comic.num) }
            Set-XKCDTestKeySequence 'L', 'Escape'

            Get-XKCDCapturedOutput {
                Start-XKCD -Number 1 -Offline -CachePath $CachePath -DownloadPath $DownloadPath -WarningAction SilentlyContinue
            } | Out-Null

            $RecordedNums | Should -Be @(1, 3)
        }

        It 'G prompts for and jumps to a specific comic number' {
            $RecordedNums = [System.Collections.Generic.List[int]]::new()
            Mock -ModuleName $Module Show-XKCDTuiFrame { $RecordedNums.Add($Comic.num) }
            Mock -ModuleName $Module Read-XKCDConsoleLine { '2' }
            Set-XKCDTestKeySequence 'G', 'Escape'

            Get-XKCDCapturedOutput {
                Start-XKCD -Number 1 -Offline -CachePath $CachePath -DownloadPath $DownloadPath -WarningAction SilentlyContinue
            } | Out-Null

            $RecordedNums | Should -Be @(1, 2)
        }

        It 'G leaves the current comic unchanged when the typed number is invalid' {
            $RecordedNums = [System.Collections.Generic.List[int]]::new()
            Mock -ModuleName $Module Show-XKCDTuiFrame { $RecordedNums.Add($Comic.num) }
            Mock -ModuleName $Module Read-XKCDConsoleLine { '999' }
            Set-XKCDTestKeySequence 'G', 'Escape'

            Get-XKCDCapturedOutput {
                Start-XKCD -Number 1 -Offline -CachePath $CachePath -DownloadPath $DownloadPath -WarningAction SilentlyContinue
            } | Out-Null

            $RecordedNums | Should -Be @(1, 1)
        }
    }

    Context 'Offline State Tests' {

        BeforeAll {
            $CachePath = Join-Path $TestDrive 'start-xkcd-state-cache.json'
            @(
                [pscustomobject]@{ num = 1; title = 'Comic 1'; img = 'https://imgs.xkcd.com/comics/comic1.jpg'; alt = 'Alt 1'; year = '2006'; month = '1'; day = '1' }
                [pscustomobject]@{ num = 2; title = 'Comic 2'; img = 'https://imgs.xkcd.com/comics/comic2.png'; alt = 'Alt 2'; year = '2006'; month = '1'; day = '2' }
            ) | ConvertTo-Json | Out-File $CachePath

            $DownloadPath = Join-Path $TestDrive 'start-xkcd-state-downloads'
            New-Item -ItemType Directory -Path $DownloadPath -Force | Out-Null

            Mock -ModuleName $Module Read-XKCDConsoleKey { $script:XKCDTestKeyQueue.Dequeue() }
        }

        It 'Records the most recently displayed comic as the most recently viewed' {
            $StatePath = Join-Path $TestDrive 'start-xkcd-state.json'
            Set-XKCDTestKeySequence 'RightArrow', 'Escape'

            Get-XKCDCapturedOutput {
                Start-XKCD -Number 1 -Offline -CachePath $CachePath -DownloadPath $DownloadPath -StatePath $StatePath -WarningAction SilentlyContinue
            } | Out-Null

            (Get-Content $StatePath | ConvertFrom-Json).LastViewed | Should -Be 2
        }

        It 'Does not update the state file when -WhatIf is specified' {
            $StatePath = Join-Path $TestDrive 'start-xkcd-whatif-state.json'
            Set-XKCDTestKeySequence 'Escape'

            Get-XKCDCapturedOutput {
                Start-XKCD -Number 1 -Offline -CachePath $CachePath -DownloadPath $DownloadPath -StatePath $StatePath -WarningAction SilentlyContinue -WhatIf
            } | Out-Null

            $StatePath | Should -Not -Exist
        }
    }
}
