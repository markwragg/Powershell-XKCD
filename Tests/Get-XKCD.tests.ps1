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

        It 'Get-XKCD -Newest requires an input' {
            { Get-XKCD -Newest } | Should -Throw
        }
        It 'Get-XKCD -Newest rejects string input' {
            { Get-XKCD -Newest Ten } | Should -Throw
        }
        It 'Get-XKCD -Num requires an input' {
            { Get-XKCD -Num } | Should -Throw
        }
        It 'Get-XKCD -Num rejects string input' {
            { Get-XKCD -Num Five } | Should -Throw
        }

        It 'Get-XKCD -Min requires an input' {
            { Get-XKCD -Min } | Should -Throw
        }
        It 'Get-XKCD -Min rejects string input' {
            { Get-XKCD -Min Seven } | Should -Throw
        }

        It 'Get-XKCD -Max requires an input' {
            { Get-XKCD -Max } | Should -Throw
        }
        It 'Get-XKCD -Max rejects string input' {
            { Get-XKCD -Max Twelve } | Should -Throw
        }
    }

    Context 'Parameter Set Tests' {

        It 'Get-XKCD does not allow -Random and -Newest to be used together' {
            { Get-XKCD -Random -Newest 10 } | Should -Throw
        }
        It 'Get-XKCD does not allow -Random and -Num to be used together' {
            { Get-XKCD -Random -Num 123 } | Should -Throw
        }
        It 'Get-XKCD does not allow -Random and -Num and -Newest to be used together' {
            { Get-XKCD -Random -Num 456 -Newest 5 } | Should -Throw
        }
        It 'Get-XKCD does not allow -Next and -Previous to be used together' {
            { Get-XKCD -Next -Previous } | Should -Throw
        }
        It 'Get-XKCD does not allow -Next and -Num to be used together' {
            { Get-XKCD -Next -Num 1 } | Should -Throw
        }
        It 'Get-XKCD does not allow -Previous and -Num to be used together' {
            { Get-XKCD -Previous -Num 1 } | Should -Throw
        }
    }

    Context 'Offline Tests' {

        BeforeAll {
            $CachePath = Join-Path $TestDrive 'offline-get-cache.json'
            @(
                [pscustomobject]@{ num = 1; title = 'Comic 1'; img = 'https://imgs.xkcd.com/comics/comic1.jpg'; alt = 'Alt 1'; year = '2006'; month = '1'; day = '1' }
                [pscustomobject]@{ num = 2; title = 'Comic 2'; img = 'https://imgs.xkcd.com/comics/comic2.png'; alt = 'Alt 2'; year = '2006'; month = '1'; day = '2' }
            ) | ConvertTo-Json | Out-File $CachePath
        }

        It 'Get-XKCD -Offline returns comic data from the local cache without contacting the API' {
            Mock -ModuleName $Module Invoke-RestMethod { throw 'Invoke-RestMethod should not be called in -Offline mode' }

            $Comic = Get-XKCD -Num 1 -Offline -CachePath $CachePath -NoStateUpdate

            $Comic.num | Should -Be 1
            $Comic.title | Should -Be 'Comic 1'
        }

        It 'Get-XKCD -Offline without -Number returns the highest-numbered cached comic' {
            Mock -ModuleName $Module Invoke-RestMethod { throw 'Invoke-RestMethod should not be called in -Offline mode' }

            $Comic = Get-XKCD -Offline -CachePath $CachePath -NoStateUpdate

            $Comic.num | Should -Be 2
        }

        It 'Get-XKCD -Offline throws when the local cache does not exist' {
            $MissingCachePath = Join-Path $TestDrive 'offline-missing-cache.json'

            { Get-XKCD -Offline -CachePath $MissingCachePath -NoStateUpdate } | Should -Throw '*Update-XKCDCache*'
        }

        It 'Get-XKCD -Offline warns and skips comics that are not in the local cache' {
            Mock -ModuleName $Module Invoke-RestMethod { throw 'Invoke-RestMethod should not be called in -Offline mode' }

            $Result = Get-XKCD -Num 999 -Offline -CachePath $CachePath -NoStateUpdate -WarningVariable OfflineWarning -WarningAction SilentlyContinue

            $Result | Should -BeNullOrEmpty
            $OfflineWarning | Should -Match 'was not found in the local cache'
        }

        It 'Get-XKCD -Offline does not update the state file for a comic skipped as uncached' {
            $StatePath = Join-Path $TestDrive 'offline-get-skip-state.json'
            Mock -ModuleName $Module Invoke-RestMethod { throw 'Invoke-RestMethod should not be called in -Offline mode' }

            Get-XKCD -Num 999 -Offline -CachePath $CachePath -StatePath $StatePath -WarningAction SilentlyContinue | Out-Null

            $StatePath | Should -Not -Exist
        }
    }
}


Describe "Integration Tests PS$PSVersion" -tag 'Integration' {

    BeforeAll {
        $Root = "$PSScriptRoot/../"
        $Module = 'xkcd'

        Get-Module $Module | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module "$Root/$Module" -Force

        # Get-XKCD -Show renders the comic straight to the console; running it here would otherwise spam
        # the real terminal with comic art every time these tests run.
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

    Context 'Default Comic Tests' {

        BeforeAll {
            $Default = Get-XKCD -Download -Path $TestDrive
        }

        It 'Get-XKCD returns a PSCustomObject' {
            $Default | Should -BeOfType 'System.Management.Automation.PSCustomObject'
        }

        It "Get-XKCD returns a string for img" {
            $Default.img | Should -BeOfType [string]
        }

        It "Get-XKCD -Download saves the file using the extension from img" {
            $Extension = [System.IO.Path]::GetExtension(([uri]$Default.img).AbsolutePath)
            Join-Path $TestDrive "$($Default.num)$Extension" | Should -Exist
        }
    }

    Context 'Number Alias Tests' {

        It 'Get-XKCD -Num is an alias for -Number' {
            $ViaNum = Get-XKCD -Num 1 -NoStateUpdate
            $ViaNumber = Get-XKCD -Number 1 -NoStateUpdate

            $ViaNumber.num | Should -Be $ViaNum.num
        }
    }

    Context 'Download Extension Tests' {

        BeforeAll {
            # Comic 2000 is known to have a .png image, rather than the default .jpg
            $PngComic = Get-XKCD -Num 2000 -Download -Path $TestDrive
        }

        It "Get-XKCD -Download saves a non-jpg image using its actual extension" {
            $PngComic.img | Should -Match '\.png$'
            Join-Path $TestDrive "2000.png" | Should -Exist
        }
    }

    Context 'High Quality Download Tests' {

        BeforeAll {
            # Comic 3290 is known to have a higher resolution (_2x) version available
            Get-XKCD -Num 3290 -Download -HighQuality -Path $TestDrive
            $StandardPath = Join-Path $TestDrive 'standard.png'
            Invoke-WebRequest 'https://imgs.xkcd.com/comics/trade.png' -OutFile $StandardPath -UseBasicParsing
        }

        It "Get-XKCD -HighQuality downloads the larger _2x image when available" {
            (Get-Item (Join-Path $TestDrive '3290.png')).Length | Should -BeGreaterThan (Get-Item $StandardPath).Length
        }

        # Comic 1 does not have a higher resolution version available, so should fall back to standard quality
        It "Get-XKCD -HighQuality falls back to standard quality when no _2x image is available" {
            { Get-XKCD -Num 1 -Download -HighQuality -Path $TestDrive -WarningAction SilentlyContinue } | Should -Not -Throw
            Join-Path $TestDrive '1.jpg' | Should -Exist
        }
    }

    Context 'Random Comic Tests' {

        BeforeAll {
            $Random = Get-XKCD -Random
        }

        It 'Get-XKCD -Random returns a PSCustomObject' {
            $Random | Should -BeOfType 'System.Management.Automation.PSCustomObject'
        }

        It "Get-XKCD -Random returns a string for img" {
            $Random.img | Should -BeOfType [string]
        }
    }

    Context 'Newest Comic Tests' {

        BeforeAll {
            $Newest = Get-XKCD -Newest 5
        }

        It 'Get-XKCD -Newest 5 returns a PSCustomObject' {
            $Newest | Should -BeOfType 'System.Management.Automation.PSCustomObject'
        }

        It "Get-XKCD -Newest 5 returns a string for img" {
            $Newest.img | Should -BeOfType [string]
        }

        It "Get-XKCD -Newest 5 returns five results" {
            $Newest.Count | Should -Be 5
        }
    }

    Context 'Show Tests' {

        It 'Get-XKCD -Show does not throw' {
            { Get-XKCDCapturedOutput { Get-XKCD -Num 1 -Show } } | Should -Not -Throw
        }

        It 'Get-XKCD -Show does not return the comic object' {
            Get-XKCDCapturedOutput { $script:Result = Get-XKCD -Num 1 -Show } | Out-Null
            $script:Result | Should -BeNullOrEmpty
        }

        It 'Get-XKCD -Show records the displayed comic as the most recently viewed' {
            $StatePath = Join-Path $TestDrive 'get-show-state.json'

            Get-XKCDCapturedOutput { Get-XKCD -Num 200 -Show -StatePath $StatePath } | Out-Null

            $StatePath | Should -Exist
            (Get-Content $StatePath | ConvertFrom-Json).LastViewed | Should -Be 200
        }
    }

    Context 'Explain Tests' {

        It 'Get-XKCD -Explain does not throw' {
            { Get-XKCDCapturedOutput { Get-XKCD -Num 1 -Explain } } | Should -Not -Throw
        }

        It 'Get-XKCD -Explain does not return the comic object' {
            Get-XKCDCapturedOutput { $script:Result = Get-XKCD -Num 1 -Explain } | Out-Null
            $script:Result | Should -BeNullOrEmpty
        }

        It 'Get-XKCD -Explain does not update the state file' {
            $StatePath = Join-Path $TestDrive 'get-explain-state.json'

            Get-XKCDCapturedOutput { Get-XKCD -Num 200 -Explain -StatePath $StatePath } | Out-Null

            $StatePath | Should -Not -Exist
        }
    }

    Context 'State Tracking Tests' {

        It 'Get-XKCD records a plain retrieval as the most recently read/viewed comic' {
            $StatePath = Join-Path $TestDrive 'get-plain-state.json'

            Get-XKCD -Num 42 -StatePath $StatePath | Out-Null

            $StatePath | Should -Exist
            $State = Get-Content $StatePath | ConvertFrom-Json
            $State.LastRead | Should -Be 42
            $State.LastViewed | Should -Be 42
        }

        It 'Get-XKCD records the last comic returned when multiple are requested' {
            $StatePath = Join-Path $TestDrive 'get-multi-state.json'

            Get-XKCD -Num (10, 20, 30) -StatePath $StatePath | Out-Null

            (Get-Content $StatePath | ConvertFrom-Json).LastRead | Should -Be 30
        }

        It 'Get-XKCD does not lower LastViewed when retrieving an earlier comic' {
            $StatePath = Join-Path $TestDrive 'get-plain-noregress-state.json'
            [pscustomobject]@{ LastViewed = 500; LastRead = 500 } | ConvertTo-Json | Out-File $StatePath

            Get-XKCD -Num 42 -StatePath $StatePath | Out-Null

            $State = Get-Content $StatePath | ConvertFrom-Json
            $State.LastRead | Should -Be 42
            $State.LastViewed | Should -Be 500
        }

        It 'Get-XKCD -NoStateUpdate does not update the state file' {
            $StatePath = Join-Path $TestDrive 'get-nostateupdate-state.json'

            Get-XKCD -Num 42 -StatePath $StatePath -NoStateUpdate | Out-Null

            $StatePath | Should -Not -Exist
        }
    }

    Context 'Next and Previous Comic Tests' {

        It 'Get-XKCD -Next returns the comic after the last viewed comic' {
            $StatePath = Join-Path $TestDrive 'next-state.json'
            [pscustomobject]@{ LastViewed = 100 } | ConvertTo-Json | Out-File $StatePath

            (Get-XKCD -Next -StatePath $StatePath).num | Should -Be 101
        }

        It 'Get-XKCD -Previous returns the comic before the last viewed comic' {
            $StatePath = Join-Path $TestDrive 'previous-state.json'
            [pscustomobject]@{ LastViewed = 100 } | ConvertTo-Json | Out-File $StatePath

            (Get-XKCD -Previous -StatePath $StatePath).num | Should -Be 99
        }

        It 'Get-XKCD -Previous returns nothing when there is no comic before the last viewed comic' {
            $StatePath = Join-Path $TestDrive 'previous-state-none.json'
            [pscustomobject]@{ LastViewed = 1 } | ConvertTo-Json | Out-File $StatePath

            { Get-XKCD -Previous -StatePath $StatePath } | Should -Not -Throw
            Get-XKCD -Previous -StatePath $StatePath | Should -BeNullOrEmpty
        }

        It 'Get-XKCD -Previous returns nothing when no comic has been previously viewed' {
            $StatePath = Join-Path $TestDrive 'previous-state-missing.json'

            { Get-XKCD -Previous -StatePath $StatePath } | Should -Not -Throw
            Get-XKCD -Previous -StatePath $StatePath | Should -BeNullOrEmpty
        }

        It 'Get-XKCD -Next returns nothing when already at the latest comic' {
            $StatePath = Join-Path $TestDrive 'next-state-latest.json'
            $Latest = (Get-XKCD).num
            [pscustomobject]@{ LastViewed = $Latest } | ConvertTo-Json | Out-File $StatePath

            { Get-XKCD -Next -StatePath $StatePath } | Should -Not -Throw
            Get-XKCD -Next -StatePath $StatePath | Should -BeNullOrEmpty
        }

        It 'Get-XKCD -Next records the returned comic so a subsequent -Next moves on further' {
            $StatePath = Join-Path $TestDrive 'next-state-progress.json'
            [pscustomobject]@{ LastViewed = 100 } | ConvertTo-Json | Out-File $StatePath

            (Get-XKCD -Next -StatePath $StatePath).num | Should -Be 101
            (Get-XKCD -Next -StatePath $StatePath).num | Should -Be 102
        }

        It 'Get-XKCD -Previous records the returned comic so a subsequent -Previous steps back further' {
            $StatePath = Join-Path $TestDrive 'previous-state-progress.json'
            [pscustomobject]@{ LastViewed = 100 } | ConvertTo-Json | Out-File $StatePath

            (Get-XKCD -Previous -StatePath $StatePath).num | Should -Be 99
            (Get-XKCD -Previous -StatePath $StatePath).num | Should -Be 98
        }

        It 'Get-XKCD -Previous then -Next returns to the comic last displayed before paging back' {
            $StatePath = Join-Path $TestDrive 'previous-then-next-state.json'
            [pscustomobject]@{ LastViewed = 100 } | ConvertTo-Json | Out-File $StatePath

            (Get-XKCD -Previous -StatePath $StatePath).num | Should -Be 99
            (Get-XKCD -Next -StatePath $StatePath).num | Should -Be 100
        }
    }

    Context 'Html Property Tests' {

        It 'Get-XKCD returns a html_img property containing just an img tag for the comic' {
            $Comic = Get-XKCD -Num 1
            $ExpectedImgTag = [regex]::Escape("<img src=`"$($Comic.img)`"")

            $Comic.html_img | Should -Not -Match '<a '
            $Comic.html_img | Should -Match $ExpectedImgTag
        }

        It 'Get-XKCD returns a html property wrapping the same img tag in a link to the comic' {
            $Comic = Get-XKCD -Num 1

            $Comic.html | Should -Match '^<a href="https://xkcd\.com/1">'
            $Comic.html | Should -Be "<a href=`"https://xkcd.com/1`">$($Comic.html_img)</a>"
        }

        It 'Get-XKCD HTML-encodes special characters in the alt text' {
            # Comic 353's alt text contains an apostrophe ("Perl, I'm leaving you.")
            $Comic = Get-XKCD -Num 353
            $Comic.html_img | Should -Not -Match "I'm leaving you"
            $Comic.html_img | Should -Match 'I&#39;m leaving you'
            $Comic.html | Should -Match 'I&#39;m leaving you'
        }
    }

    Context 'Date Property Tests' {

        It 'Get-XKCD returns a date property matching the comic''s day/month/year' {
            $Comic = Get-XKCD -Num 1

            $Comic.date | Should -BeOfType 'datetime'
            $Comic.date | Should -Be ([datetime]::new($Comic.year, $Comic.month, $Comic.day))
        }

        It 'Get-XKCD results can be sorted by date' {
            $Comics = Get-XKCD -Newest 5 | Sort-Object date

            # Comic numbers increase monotonically with publish date, so a date sort should match a num sort
            @($Comics.num) | Should -Be @($Comics.num | Sort-Object)
        }

        It 'Get-XKCD results can be filtered by date' {
            $Comics = Get-XKCD -Newest 5 | Where-Object date -gt ([datetime]'2000-01-01')

            @($Comics).Count | Should -Be 5
        }
    }

    Context 'Raw Parameter Tests' {

        It 'Get-XKCD -Raw does not add the date, html_img or html properties' {
            $Comic = Get-XKCD -Num 1 -Raw

            $Comic.PSObject.Properties.Name | Should -Not -Contain 'date'
            $Comic.PSObject.Properties.Name | Should -Not -Contain 'html_img'
            $Comic.PSObject.Properties.Name | Should -Not -Contain 'html'
        }

        It 'Get-XKCD -Raw does not tag the object with the XKCD.Comic type name' {
            $Comic = Get-XKCD -Num 1 -Raw

            $Comic.PSObject.TypeNames | Should -Not -Contain 'XKCD.Comic'
        }

        It 'Get-XKCD -Raw still returns the comic''s own API properties' {
            $Comic = Get-XKCD -Num 1 -Raw

            $Comic.num | Should -Be 1
            $Comic.title | Should -Be 'Barrel - Part 1'
        }

        It 'Get-XKCD without -Raw still adds the date, html_img and html properties' {
            $Comic = Get-XKCD -Num 1

            $Comic.PSObject.Properties.Name | Should -Contain 'date'
            $Comic.PSObject.Properties.Name | Should -Contain 'html_img'
            $Comic.PSObject.Properties.Name | Should -Contain 'html'
        }
    }

    Context 'Random Range Tests' {

        It 'Get-XKCD -Random -Min -Max returns a comic within the specified range' {
            $RandomInRange = Get-XKCD -Random -Min 100 -Max 150
            $RandomInRange.num | Should -BeGreaterThan 99
            $RandomInRange.num | Should -BeLessThan 151
        }
    }

    Context 'Open Tests' {

        # -Scope It keeps each assertion's call count limited to its own test, since mock call
        # history otherwise accumulates for the duration of the Context.

        It 'Get-XKCD -Open -Force opens the comic without prompting for confirmation' {
            Mock -ModuleName $Module Start-Process { }

            { Get-XKCD -Num 1 -Open -Force } | Should -Not -Throw
            Should -Invoke -CommandName Start-Process -ModuleName $Module -Times 1 -Exactly -Scope It -ParameterFilter { $FilePath -eq 'https://xkcd.com/1' }
        }

        It 'Get-XKCD -Open opens fewer than 10 comics without prompting for confirmation' {
            Mock -ModuleName $Module Start-Process { }

            { Get-XKCD -Num 2 -Open } | Should -Not -Throw
            Should -Invoke -CommandName Start-Process -ModuleName $Module -Times 1 -Exactly -Scope It -ParameterFilter { $FilePath -eq 'https://xkcd.com/2' }
        }

        It 'Get-XKCD -Open prompts for confirmation and opens comics when 10 or more are requested and confirmed' {
            Mock -ModuleName $Module Read-Host { 'y' }
            Mock -ModuleName $Module Start-Process { }

            { Get-XKCD -Num (11..20) -Open } | Should -Not -Throw
            Should -Invoke -CommandName Read-Host -ModuleName $Module -Times 1 -Exactly -Scope It
            Should -Invoke -CommandName Start-Process -ModuleName $Module -Times 10 -Exactly -Scope It -ParameterFilter { $FilePath -match '^https://xkcd\.com/1[1-9]$|^https://xkcd\.com/20$' }
        }

        It 'Get-XKCD -Open prompts for confirmation and does not open comics when declined' {
            Mock -ModuleName $Module Read-Host { 'n' }
            Mock -ModuleName $Module Start-Process { }

            { Get-XKCD -Num (21..30) -Open } | Should -Not -Throw
            Should -Invoke -CommandName Read-Host -ModuleName $Module -Times 1 -Exactly -Scope It
            Should -Invoke -CommandName Start-Process -ModuleName $Module -Times 0 -Exactly -Scope It -ParameterFilter { $FilePath -match '^https://xkcd\.com/2[1-9]$|^https://xkcd\.com/30$' }
        }
    }
}
