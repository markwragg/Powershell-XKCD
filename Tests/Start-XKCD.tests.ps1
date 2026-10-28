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

        # Redirects the per-user data directory (~/.xkcd) that Start-XKCD falls back to for -StatePath (used
        # to track the most recently read/viewed comic) whenever a test below doesn't pass its own -StatePath
        # explicitly -- without this, those tests would read/write the real file on whatever machine runs
        # them, silently clobbering the actual comic you were last reading.
        Mock -ModuleName $Module Get-XKCDUserDataPath { Param($FileName, $LegacyDirectory) [void]$LegacyDirectory; Join-Path $TestDrive $FileName }

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

        # Like New-XKCDTestKey, but with the Shift modifier set -- used to test Shift+Left/Right's 10-comic jump.
        function New-XKCDTestShiftKey ([System.ConsoleKey]$Key) {
            [System.ConsoleKeyInfo]::new([char]0, $Key, $true, $false, $false)
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

        It 'Right arrow shows a message instead of redrawing once the latest comic is reached' {
            $RecordedNums = [System.Collections.Generic.List[int]]::new()
            Mock -ModuleName $Module Show-XKCDTuiFrame { $RecordedNums.Add($Comic.num) }
            Set-XKCDTestKeySequence 'RightArrow', 'RightArrow', 'Escape'

            $Output = Get-XKCDCapturedOutput {
                Start-XKCD -Number 3 -Offline -CachePath $CachePath -DownloadPath $DownloadPath -WarningAction SilentlyContinue
            }

            $RecordedNums | Should -Be @(3)
            $Output | Should -Match 'already viewing the latest comic'
        }

        It 'Left arrow shows a message instead of redrawing once comic #1 is reached' {
            $RecordedNums = [System.Collections.Generic.List[int]]::new()
            Mock -ModuleName $Module Show-XKCDTuiFrame { $RecordedNums.Add($Comic.num) }
            Set-XKCDTestKeySequence 'LeftArrow', 'LeftArrow', 'Escape'

            $Output = Get-XKCDCapturedOutput {
                Start-XKCD -Number 1 -Offline -CachePath $CachePath -DownloadPath $DownloadPath -WarningAction SilentlyContinue
            }

            $RecordedNums | Should -Be @(1)
            $Output | Should -Match 'already viewing the first comic'
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

        It 'F shows a message instead of redrawing when already on the first comic' {
            $RecordedNums = [System.Collections.Generic.List[int]]::new()
            Mock -ModuleName $Module Show-XKCDTuiFrame { $RecordedNums.Add($Comic.num) }
            Set-XKCDTestKeySequence 'F', 'Escape'

            $Output = Get-XKCDCapturedOutput {
                Start-XKCD -Number 1 -Offline -CachePath $CachePath -DownloadPath $DownloadPath -WarningAction SilentlyContinue
            }

            $RecordedNums | Should -Be @(1)
            $Output | Should -Match 'already viewing the first comic'
        }

        It 'L shows a message instead of redrawing when already on the latest comic' {
            $RecordedNums = [System.Collections.Generic.List[int]]::new()
            Mock -ModuleName $Module Show-XKCDTuiFrame { $RecordedNums.Add($Comic.num) }
            Set-XKCDTestKeySequence 'L', 'Escape'

            $Output = Get-XKCDCapturedOutput {
                Start-XKCD -Number 3 -Offline -CachePath $CachePath -DownloadPath $DownloadPath -WarningAction SilentlyContinue
            }

            $RecordedNums | Should -Be @(3)
            $Output | Should -Match 'already viewing the latest comic'
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

        It 'G shows a message instead of redrawing when the typed number is invalid' {
            $RecordedNums = [System.Collections.Generic.List[int]]::new()
            Mock -ModuleName $Module Show-XKCDTuiFrame { $RecordedNums.Add($Comic.num) }
            Mock -ModuleName $Module Read-XKCDConsoleLine { '999' }
            Set-XKCDTestKeySequence 'G', 'Escape'

            $Output = Get-XKCDCapturedOutput {
                Start-XKCD -Number 1 -Offline -CachePath $CachePath -DownloadPath $DownloadPath -WarningAction SilentlyContinue
            }

            $RecordedNums | Should -Be @(1)
            $Output | Should -Match "not a valid comic number"
        }

        It 'G shows a message instead of redrawing when the typed number is in range but does not exist' {
            $RecordedNums = [System.Collections.Generic.List[int]]::new()
            Mock -ModuleName $Module Show-XKCDTuiFrame { $RecordedNums.Add($Comic.num) }
            # The cache here only has comics #1 and #3 -- #2 is a gap, so $Latest (the highest cached number)
            # is still 3, making '2' a syntactically valid, in-range request that nonetheless doesn't exist.
            Mock -ModuleName $Module Get-XKCDOfflineComic {
                Param($CachePath, $Number)
                $ExistingComics = @(1, 3) | ForEach-Object {
                    [pscustomobject]@{ num = $_; title = "Comic $_"; img = "https://imgs.xkcd.com/comics/comic$_.jpg"; alt = "Alt $_"; year = '2006'; month = '1'; day = "$_" }
                }
                if ($Number) { $ExistingComics | Where-Object { $_.num -in $Number } } else { $ExistingComics }
            }
            Mock -ModuleName $Module Read-XKCDConsoleLine { '2' }
            Set-XKCDTestKeySequence 'G', 'Escape'

            $Output = Get-XKCDCapturedOutput {
                Start-XKCD -Number 1 -Offline -CachePath $CachePath -DownloadPath $DownloadPath -WarningAction SilentlyContinue
            }

            $RecordedNums | Should -Be @(1)
            $Output | Should -Match "Comic #2 doesn't exist"
        }

        It 'G re-prompts one line above a still-visible message when the previous attempt was also invalid' {
            $RecordedNums = [System.Collections.Generic.List[int]]::new()
            Mock -ModuleName $Module Show-XKCDTuiFrame { $RecordedNums.Add($Comic.num) }
            $LineQueue = [System.Collections.Generic.Queue[string]]::new([string[]]@('999', '998'))
            Mock -ModuleName $Module Read-XKCDConsoleLine { $LineQueue.Dequeue() }
            Set-XKCDTestKeySequence 'G', 'G', 'Escape'

            $Output = Get-XKCDCapturedOutput {
                Start-XKCD -Number 1 -Offline -CachePath $CachePath -DownloadPath $DownloadPath -WarningAction SilentlyContinue
            }

            $Esc = [char]27
            $RecordedNums | Should -Be @(1)
            # Only the second attempt's re-prompt should move up a line -- there's no message yet to preserve
            # the first time around.
            ([regex]::Matches($Output, [regex]::Escape("$Esc[1A"))).Count | Should -Be 1
        }
    }

    Context 'Shift+Arrow Navigation Tests' {

        BeforeAll {
            # A bigger cache than the other contexts' (1..20 rather than 1..3) so a 10-comic jump, and its
            # clamping at either end, is distinguishable from simply landing on the first/last comic.
            $CachePath = Join-Path $TestDrive 'start-xkcd-shift-cache.json'
            1..20 | ForEach-Object {
                [pscustomobject]@{ num = $_; title = "Comic $_"; img = "https://imgs.xkcd.com/comics/comic$_.jpg"; alt = "Alt $_"; year = '2006'; month = '1'; day = "$_" }
            } | ConvertTo-Json | Out-File $CachePath

            $DownloadPath = Join-Path $TestDrive 'start-xkcd-shift-downloads'
            New-Item -ItemType Directory -Path $DownloadPath -Force | Out-Null

            Mock -ModuleName $Module Read-XKCDConsoleKey { $script:XKCDTestKeyQueue.Dequeue() }
        }

        It 'Shift+Right jumps ahead 10 comics instead of 1' {
            $RecordedNums = [System.Collections.Generic.List[int]]::new()
            Mock -ModuleName $Module Show-XKCDTuiFrame { $RecordedNums.Add($Comic.num) }
            $script:XKCDTestKeyQueue = [System.Collections.Generic.Queue[System.ConsoleKeyInfo]]::new(
                [System.ConsoleKeyInfo[]]@((New-XKCDTestShiftKey 'RightArrow'), (New-XKCDTestKey 'Escape'))
            )

            Get-XKCDCapturedOutput {
                Start-XKCD -Number 1 -Offline -CachePath $CachePath -DownloadPath $DownloadPath -WarningAction SilentlyContinue
            } | Out-Null

            $RecordedNums | Should -Be @(1, 11)
        }

        It 'Shift+Left jumps back 10 comics instead of 1' {
            $RecordedNums = [System.Collections.Generic.List[int]]::new()
            Mock -ModuleName $Module Show-XKCDTuiFrame { $RecordedNums.Add($Comic.num) }
            $script:XKCDTestKeyQueue = [System.Collections.Generic.Queue[System.ConsoleKeyInfo]]::new(
                [System.ConsoleKeyInfo[]]@((New-XKCDTestShiftKey 'LeftArrow'), (New-XKCDTestKey 'Escape'))
            )

            Get-XKCDCapturedOutput {
                Start-XKCD -Number 15 -Offline -CachePath $CachePath -DownloadPath $DownloadPath -WarningAction SilentlyContinue
            } | Out-Null

            $RecordedNums | Should -Be @(15, 5)
        }

        It 'Shift+Right clamps to the latest comic rather than overshooting it' {
            $RecordedNums = [System.Collections.Generic.List[int]]::new()
            Mock -ModuleName $Module Show-XKCDTuiFrame { $RecordedNums.Add($Comic.num) }
            $script:XKCDTestKeyQueue = [System.Collections.Generic.Queue[System.ConsoleKeyInfo]]::new(
                [System.ConsoleKeyInfo[]]@((New-XKCDTestShiftKey 'RightArrow'), (New-XKCDTestKey 'Escape'))
            )

            Get-XKCDCapturedOutput {
                Start-XKCD -Number 15 -Offline -CachePath $CachePath -DownloadPath $DownloadPath -WarningAction SilentlyContinue
            } | Out-Null

            $RecordedNums | Should -Be @(15, 20)
        }

        It 'Shift+Left clamps to the first comic rather than undershooting it' {
            $RecordedNums = [System.Collections.Generic.List[int]]::new()
            Mock -ModuleName $Module Show-XKCDTuiFrame { $RecordedNums.Add($Comic.num) }
            $script:XKCDTestKeyQueue = [System.Collections.Generic.Queue[System.ConsoleKeyInfo]]::new(
                [System.ConsoleKeyInfo[]]@((New-XKCDTestShiftKey 'LeftArrow'), (New-XKCDTestKey 'Escape'))
            )

            Get-XKCDCapturedOutput {
                Start-XKCD -Number 5 -Offline -CachePath $CachePath -DownloadPath $DownloadPath -WarningAction SilentlyContinue
            } | Out-Null

            $RecordedNums | Should -Be @(5, 1)
        }

        It 'Shift+P (a plain upper-case P) still moves only 1 comic, unlike Shift+Left' {
            $RecordedNums = [System.Collections.Generic.List[int]]::new()
            Mock -ModuleName $Module Show-XKCDTuiFrame { $RecordedNums.Add($Comic.num) }
            $script:XKCDTestKeyQueue = [System.Collections.Generic.Queue[System.ConsoleKeyInfo]]::new(
                [System.ConsoleKeyInfo[]]@((New-XKCDTestShiftKey 'P'), (New-XKCDTestKey 'Escape'))
            )

            Get-XKCDCapturedOutput {
                Start-XKCD -Number 15 -Offline -CachePath $CachePath -DownloadPath $DownloadPath -WarningAction SilentlyContinue
            } | Out-Null

            $RecordedNums | Should -Be @(15, 14)
        }
    }

    Context 'Admin Console Tests' {

        BeforeAll {
            $CachePath = Join-Path $TestDrive 'start-xkcd-admin-cache.json'
            @(
                [pscustomobject]@{ num = 1; title = 'Comic 1'; img = 'https://imgs.xkcd.com/comics/comic1.jpg'; alt = 'Alt 1'; year = '2006'; month = '1'; day = '1' }
                [pscustomobject]@{ num = 2; title = 'Comic 2'; img = 'https://imgs.xkcd.com/comics/comic2.png'; alt = 'Alt 2'; year = '2006'; month = '1'; day = '2' }
                [pscustomobject]@{ num = 3; title = 'Comic 3'; img = 'https://imgs.xkcd.com/comics/comic3.jpg'; alt = 'Alt 3'; year = '2006'; month = '1'; day = '3' }
            ) | ConvertTo-Json | Out-File $CachePath

            $DownloadPath = Join-Path $TestDrive 'start-xkcd-admin-downloads'
            New-Item -ItemType Directory -Path $DownloadPath -Force | Out-Null

            Mock -ModuleName $Module Read-XKCDConsoleKey { $script:XKCDTestKeyQueue.Dequeue() }

            # Not a named ConsoleKey the existing New-XKCDTestKey helper can produce (its KeyChar is always
            # [char]0) -- backtick's ConsoleKey is Oem3 on a US keyboard, so it's built directly here instead.
            function New-XKCDBacktickKey {
                [System.ConsoleKeyInfo]::new('`', [System.ConsoleKey]::Oem3, $false, $false, $false)
            }
        }

        It 'Backtick drops into the admin console, and "exit" returns to the same comic' {
            $RecordedNums = [System.Collections.Generic.List[int]]::new()
            Mock -ModuleName $Module Show-XKCDTuiFrame { $RecordedNums.Add($Comic.num) }
            Mock -ModuleName $Module Read-XKCDConsoleLine { 'exit' }
            $script:XKCDTestKeyQueue = [System.Collections.Generic.Queue[System.ConsoleKeyInfo]]::new(
                [System.ConsoleKeyInfo[]]@((New-XKCDBacktickKey), (New-XKCDTestKey 'Escape'))
            )

            $Output = Get-XKCDCapturedOutput {
                Start-XKCD -Number 1 -Offline -CachePath $CachePath -DownloadPath $DownloadPath -WarningAction SilentlyContinue
            }

            $RecordedNums | Should -Be @(1, 1)
            $Output | Should -Match 'secret XKCD admin console'
        }

        It '"open" jumps straight to the requested comic and exits the console' {
            $RecordedNums = [System.Collections.Generic.List[int]]::new()
            Mock -ModuleName $Module Show-XKCDTuiFrame { $RecordedNums.Add($Comic.num) }
            $LineQueue = [System.Collections.Generic.Queue[string]]::new([string[]]@('cd 2006/01', 'open 3'))
            Mock -ModuleName $Module Read-XKCDConsoleLine { $LineQueue.Dequeue() }
            $script:XKCDTestKeyQueue = [System.Collections.Generic.Queue[System.ConsoleKeyInfo]]::new(
                [System.ConsoleKeyInfo[]]@((New-XKCDBacktickKey), (New-XKCDTestKey 'Escape'))
            )

            Get-XKCDCapturedOutput {
                Start-XKCD -Number 1 -Offline -CachePath $CachePath -DownloadPath $DownloadPath -WarningAction SilentlyContinue
            } | Out-Null

            $RecordedNums | Should -Be @(1, 3)
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
