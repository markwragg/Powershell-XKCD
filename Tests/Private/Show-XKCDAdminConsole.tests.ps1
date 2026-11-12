if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Unit Tests PS$PSVersion" {

    BeforeAll {
        $Root = "$PSScriptRoot/../.."
        $Module = 'xkcd'

        Get-Module $Module | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module "$Root/$Module" -Force

        $ModuleObj = Get-Module $Module

        # Prevents every test here from making a real network call on entry (Show-XKCDAdminConsole refreshes
        # the cache via Update-XKCDCache as soon as it's entered) -- individual tests override this where the
        # call itself, or its failure handling, is what's under test.
        Mock -ModuleName $Module Update-XKCDCache {}

        # Show-XKCDAdminConsole returns a value (the comic number to jump to, or $null), which would
        # otherwise leak into Get-XKCDCapturedOutput's own return alongside the captured text -- piped to
        # Out-Null here so $Output stays a plain string wherever only the captured text is under test.
        function Get-XKCDCapturedAdminConsoleOutput ([string]$CachePath, [int]$Width = 80) {
            $OriginalOut = [Console]::Out
            $Writer = [System.IO.StringWriter]::new()

            try {
                [Console]::SetOut($Writer)
                & $ModuleObj { Param($CachePath, $Width) Show-XKCDAdminConsole -CachePath $CachePath -Width $Width } $CachePath $Width | Out-Null
            }
            finally {
                [Console]::SetOut($OriginalOut)
            }

            $Writer.ToString()
        }

        function Invoke-XKCDTestAdminConsole ([string]$CachePath) {
            # Unlike the helper above, the return value (what "open"/"view" jumps to) is what's under test
            # here, so console output is merely silenced rather than captured.
            $OriginalOut = [Console]::Out
            try {
                [Console]::SetOut([System.IO.StringWriter]::new())
                & $ModuleObj { Param($CachePath) Show-XKCDAdminConsole -CachePath $CachePath } $CachePath
            }
            finally {
                [Console]::SetOut($OriginalOut)
            }
        }
    }

    Context 'Banner Tests' {

        BeforeAll {
            $CachePath = Join-Path $TestDrive 'banner-cache.json'
            @([pscustomobject]@{ num = 1; title = 'Comic 1'; year = '2006'; month = '1'; day = '1' }) | ConvertTo-Json | Out-File $CachePath

            $LineQueue = [System.Collections.Generic.Queue[string]]::new([string[]]@('exit'))
            Mock -ModuleName $Module Read-XKCDConsoleLine { $LineQueue.Dequeue() }

            $Output = Get-XKCDCapturedAdminConsoleOutput -CachePath $CachePath
        }

        It 'Prints the xkcd ASCII art banner' {
            $Output | Should -Match 'X88K'
        }

        It 'Prints the banner tagline' {
            $Output | Should -Match 'A webcomic of romance, sarcasm, math, and language\.'
        }

        It 'Explains that the archive is navigable like a filesystem' {
            $Output | Should -Match '/<year>/<month>/<num>\.json'
        }

        It 'Centers the banner within the given width, same as the main viewer' {
            # The outer BeforeAll's queue was already drained by the $Output call above -- a fresh one is
            # needed here since this test drives its own separate invocation (with a non-default -Width).
            $WidthLineQueue = [System.Collections.Generic.Queue[string]]::new([string[]]@('exit'))
            Mock -ModuleName $Module Read-XKCDConsoleLine { $WidthLineQueue.Dequeue() }

            $CenteredOutput = Get-XKCDCapturedAdminConsoleOutput -CachePath $CachePath -Width 100

            # The raw (uncolored) banner line is 35 characters wide: floor((100 - 35) / 2) == 32 leading spaces.
            $CenteredOutput | Should -Match "(?m)^ {32}.*X88K"
        }
    }

    Context 'Cache Refresh Tests' {

        BeforeAll {
            $CachePath = Join-Path $TestDrive 'refresh-cache.json'
            @([pscustomobject]@{ num = 1; title = 'Comic 1'; year = '2006'; month = '1'; day = '1' }) | ConvertTo-Json | Out-File $CachePath
        }

        It 'Refreshes the cache on entry so the filesystem reflects the latest comics' {
            $LineQueue = [System.Collections.Generic.Queue[string]]::new([string[]]@('exit'))
            Mock -ModuleName $Module Read-XKCDConsoleLine { $LineQueue.Dequeue() }
            Mock -ModuleName $Module Update-XKCDCache {}

            Get-XKCDCapturedAdminConsoleOutput -CachePath $CachePath | Out-Null

            Should -Invoke Update-XKCDCache -ModuleName $Module -Times 1 -Exactly -ParameterFilter { $CachePath -eq $CachePath }
        }

        It 'Reports that it is updating the local comic cache' {
            $LineQueue = [System.Collections.Generic.Queue[string]]::new([string[]]@('exit'))
            Mock -ModuleName $Module Read-XKCDConsoleLine { $LineQueue.Dequeue() }
            Mock -ModuleName $Module Update-XKCDCache {}

            $Output = Get-XKCDCapturedAdminConsoleOutput -CachePath $CachePath

            $Output | Should -Match 'Updating local comic cache\.\.\.'
        }

        It 'Still comes up and browses the existing cache if the refresh fails (e.g. no network)' {
            $LineQueue = [System.Collections.Generic.Queue[string]]::new([string[]]@('exit'))
            Mock -ModuleName $Module Read-XKCDConsoleLine { $LineQueue.Dequeue() }
            Mock -ModuleName $Module Update-XKCDCache { throw 'No network connectivity' }

            $Output = Get-XKCDCapturedAdminConsoleOutput -CachePath $CachePath

            $Output | Should -Match 'Access granted\.'
            $Output | Should -Not -Match 'No such file or directory'
        }
    }

    Context 'Missing Cache Tests' {

        BeforeAll {
            $CachePath = Join-Path $TestDrive 'does-not-exist.json'

            $LineQueue = [System.Collections.Generic.Queue[string]]::new([string[]]@('exit'))
            Mock -ModuleName $Module Read-XKCDConsoleLine { $LineQueue.Dequeue() }

            $Output = Get-XKCDCapturedAdminConsoleOutput -CachePath $CachePath
        }

        It 'Reports that the archive could not be mounted, without throwing' {
            $Output | Should -Match 'No such file or directory'
        }

        It 'Still drops into the prompt so "exit" can be typed' {
            $Output | Should -Match 'root@xkcd.*?:.*?/.*?#'
        }
    }

    Context 'Navigation Tests' {

        BeforeAll {
            $CachePath = Join-Path $TestDrive 'nav-cache.json'
            @(
                [pscustomobject]@{ num = 1; title = 'Comic 1'; year = '2006'; month = '1'; day = '1' }
                [pscustomobject]@{ num = 2; title = 'Comic 2'; year = '2006'; month = '1'; day = '2' }
            ) | ConvertTo-Json | Out-File $CachePath

            $LineQueue = [System.Collections.Generic.Queue[string]]::new([string[]]@('cd 2006/01', 'ls', 'exit'))
            Mock -ModuleName $Module Read-XKCDConsoleLine { $LineQueue.Dequeue() }

            $Output = Get-XKCDCapturedAdminConsoleOutput -CachePath $CachePath
        }

        It 'Reflects the current path in the prompt after cd' {
            $Output | Should -Match 'root@xkcd.*?:.*?/2006/01.*?#'
        }

        It 'Lists the comics in that directory' {
            $Output | Should -Match '1\.json'
            $Output | Should -Match '2\.json'
        }
    }

    Context 'Jump Tests' {

        BeforeAll {
            $CachePath = Join-Path $TestDrive 'jump-cache.json'
            @(
                [pscustomobject]@{ num = 1; title = 'Comic 1'; year = '2006'; month = '1'; day = '1' }
                [pscustomobject]@{ num = 2; title = 'Comic 2'; year = '2006'; month = '1'; day = '2' }
            ) | ConvertTo-Json | Out-File $CachePath
        }

        It 'Returns the requested comic number after "open"' {
            $LineQueue = [System.Collections.Generic.Queue[string]]::new([string[]]@('cd 2006/01', 'open 2'))
            Mock -ModuleName $Module Read-XKCDConsoleLine { $LineQueue.Dequeue() }

            $Result = Invoke-XKCDTestAdminConsole -CachePath $CachePath

            $Result | Should -Be 2
        }

        It 'Returns $null after "exit" without ever using open/view' {
            $LineQueue = [System.Collections.Generic.Queue[string]]::new([string[]]@('exit'))
            Mock -ModuleName $Module Read-XKCDConsoleLine { $LineQueue.Dequeue() }

            $Result = Invoke-XKCDTestAdminConsole -CachePath $CachePath

            $Result | Should -BeNullOrEmpty
        }
    }
}
