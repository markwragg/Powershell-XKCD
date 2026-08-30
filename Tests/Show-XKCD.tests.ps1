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

        It 'Show-XKCD -Num rejects string input' {
            { Show-XKCD -Num Five } | Should -Throw
        }
        It 'Show-XKCD does not allow -Next and -Previous to be used together' {
            { Show-XKCD -Next -Previous } | Should -Throw
        }
        It 'Show-XKCD does not allow -Next and -Num to be used together' {
            { Show-XKCD -Next -Num 1 } | Should -Throw
        }
        It 'Show-XKCD does not allow -Previous and -Num to be used together' {
            { Show-XKCD -Previous -Num 1 } | Should -Throw
        }
        It 'Show-XKCD does not allow -Path and -Num to be used together' {
            { Show-XKCD -Path 'foo.xkcdterm.json' -Num 1 } | Should -Throw
        }
    }
}


Describe "Integration Tests PS$PSVersion" -tag 'Integration' {

    BeforeAll {
        $Root = "$PSScriptRoot/../"
        $Module = 'xkcd'

        Get-Module $Module | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module "$Root/$Module" -Force

        # Show-XKCD writes the rendered comic straight to the console; running it here would otherwise
        # spam the real terminal with comic art and text every time these tests run.
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

        It 'Show-XKCD displays the latest comic without throwing' {
            { Get-XKCDCapturedOutput { Show-XKCD } } | Should -Not -Throw
        }

        It 'Show-XKCD does not return an object to the pipeline' {
            Get-XKCDCapturedOutput { $script:Result = Show-XKCD } | Out-Null
            $script:Result | Should -BeNullOrEmpty
        }
    }

    Context 'Specific Comic Tests' {

        It 'Show-XKCD -Num displays a specific comic without throwing' {
            { Get-XKCDCapturedOutput { Show-XKCD -Num 2000 } } | Should -Not -Throw
        }

        It 'Show-XKCD accepts pipeline input of comic numbers' {
            { Get-XKCDCapturedOutput { 1, 4 | Show-XKCD } } | Should -Not -Throw
        }

        It 'Show-XKCD accepts a comic object from Get-XKCD via the pipeline' {
            { Get-XKCDCapturedOutput { Get-XKCD -Num 5 | Show-XKCD } } | Should -Not -Throw
        }
    }

    Context 'High Quality Tests' {

        # Comic 3290 is known to have a higher resolution (_2x) version available
        It 'Show-XKCD -HighQuality displays the larger _2x image when available' {
            { Get-XKCDCapturedOutput { Show-XKCD -Num 3290 -HighQuality } } | Should -Not -Throw
        }

        # Comic 1 does not have a higher resolution version available, so should fall back to standard quality
        It 'Show-XKCD -HighQuality falls back to standard quality when no _2x image is available' {
            { Get-XKCDCapturedOutput { Show-XKCD -Num 1 -HighQuality -WarningAction SilentlyContinue } } | Should -Not -Throw
        }
    }

    Context 'Last Viewed State Tests' {

        It 'Show-XKCD records the displayed comic as the most recently viewed' {
            $StatePath = Join-Path $TestDrive 'show-state.json'

            Get-XKCDCapturedOutput { Show-XKCD -Num 100 -StatePath $StatePath } | Out-Null

            $StatePath | Should -Exist
            (Get-Content $StatePath | ConvertFrom-Json).LastViewed | Should -Be 100
        }

        It 'Show-XKCD does not lower the recorded comic when displaying an earlier one' {
            $StatePath = Join-Path $TestDrive 'show-state-noregress.json'
            [pscustomobject]@{ LastViewed = 500 } | ConvertTo-Json | Out-File $StatePath

            Get-XKCDCapturedOutput { Show-XKCD -Num 100 -StatePath $StatePath } | Out-Null

            (Get-Content $StatePath | ConvertFrom-Json).LastViewed | Should -Be 500
        }

        It 'Show-XKCD -Next displays the comic after the last viewed comic and advances the state' {
            $StatePath = Join-Path $TestDrive 'show-state-next.json'
            [pscustomobject]@{ LastViewed = 100 } | ConvertTo-Json | Out-File $StatePath

            Get-XKCDCapturedOutput { Show-XKCD -Next -StatePath $StatePath } | Out-Null

            (Get-Content $StatePath | ConvertFrom-Json).LastViewed | Should -Be 101
        }

        It 'Show-XKCD -Previous displays the comic before the last viewed comic without regressing the state' {
            $StatePath = Join-Path $TestDrive 'show-state-previous.json'
            [pscustomobject]@{ LastViewed = 100 } | ConvertTo-Json | Out-File $StatePath

            Get-XKCDCapturedOutput { Show-XKCD -Previous -StatePath $StatePath } | Out-Null

            (Get-Content $StatePath | ConvertFrom-Json).LastViewed | Should -Be 100
        }

        It 'Show-XKCD -Previous displays nothing and does not throw when there is no comic before the last viewed comic' {
            $StatePath = Join-Path $TestDrive 'show-state-previous-none.json'
            [pscustomobject]@{ LastViewed = 1 } | ConvertTo-Json | Out-File $StatePath

            { $script:Output = Get-XKCDCapturedOutput { Show-XKCD -Previous -StatePath $StatePath } } | Should -Not -Throw

            $script:Output | Should -BeNullOrEmpty
            (Get-Content $StatePath | ConvertFrom-Json).LastViewed | Should -Be 1
        }

        It 'Show-XKCD -Next displays nothing and does not throw when already at the latest comic' {
            $StatePath = Join-Path $TestDrive 'show-state-next-latest.json'
            $Latest = (Get-XKCD).num
            [pscustomobject]@{ LastViewed = $Latest } | ConvertTo-Json | Out-File $StatePath

            { $script:Output = Get-XKCDCapturedOutput { Show-XKCD -Next -StatePath $StatePath } } | Should -Not -Throw

            $script:Output | Should -BeNullOrEmpty
            (Get-Content $StatePath | ConvertFrom-Json).LastViewed | Should -Be $Latest
        }

        It 'Show-XKCD -Previous can be called repeatedly to step back through comics sequentially' {
            $StatePath = Join-Path $TestDrive 'show-state-previous-sequential.json'
            [pscustomobject]@{ LastViewed = 100 } | ConvertTo-Json | Out-File $StatePath

            Get-XKCDCapturedOutput { Show-XKCD -Previous -StatePath $StatePath } | Out-Null
            (Get-Content $StatePath | ConvertFrom-Json).LastRead | Should -Be 99

            Get-XKCDCapturedOutput { Show-XKCD -Previous -StatePath $StatePath } | Out-Null
            (Get-Content $StatePath | ConvertFrom-Json).LastRead | Should -Be 98
        }

        It 'Show-XKCD -Next after -Previous resumes from the comic actually last displayed, not the high-water mark' {
            $StatePath = Join-Path $TestDrive 'show-state-next-after-previous.json'
            [pscustomobject]@{ LastViewed = 100 } | ConvertTo-Json | Out-File $StatePath

            Get-XKCDCapturedOutput { Show-XKCD -Previous -StatePath $StatePath } | Out-Null
            Get-XKCDCapturedOutput { Show-XKCD -Next -StatePath $StatePath } | Out-Null

            $State = Get-Content $StatePath | ConvertFrom-Json
            $State.LastRead | Should -Be 100
            $State.LastViewed | Should -Be 100
        }
    }

    Context 'File Tests' {

        BeforeAll {
            Mock -ModuleName $Module Get-XKCDTerminalGraphicsProtocol { 'Kitty' }

            $ExportedFile = Export-XKCDTerminalImage -Num 353 -Path $TestDrive -Force -PassThru
            $Comic = Get-XKCD -Num 353
        }

        It 'Show-XKCD -Path displays a comic exported by Export-XKCDTerminalImage without throwing' {
            { Get-XKCDCapturedOutput { Show-XKCD -Path $ExportedFile.FullName } } | Should -Not -Throw
        }

        It 'Show-XKCD -Path writes the comic title and alt text from the saved file' {
            $Output = Get-XKCDCapturedOutput { Show-XKCD -Path $ExportedFile.FullName }

            # Show-XKCDComicImage re-wraps the alt text word-by-word, collapsing any repeated whitespace in the
            # original onto single spaces, so both sides need the same normalization to compare reliably.
            $NormalizedOutput = (($Output -split '\r?\n') -join ' ') -replace '\s+', ' '
            $NormalizedAlt = $Comic.alt -replace '\s+', ' '

            $NormalizedOutput | Should -Match ([regex]::Escape($Comic.title))
            $NormalizedOutput | Should -Match ([regex]::Escape($NormalizedAlt))
        }

        It 'Show-XKCD -Path accepts a FileInfo object via the pipeline (e.g. from Export-XKCDTerminalImage -PassThru)' {
            { Get-XKCDCapturedOutput { Export-XKCDTerminalImage -Num 353 -Path $TestDrive -Force -PassThru | Show-XKCD } } | Should -Not -Throw
        }

        It 'Show-XKCD -Path warns and does not throw when the file does not exist' {
            $MissingPath = Join-Path $TestDrive 'show-path-missing.xkcdterm.json'

            { Get-XKCDCapturedOutput { Show-XKCD -Path $MissingPath -WarningAction SilentlyContinue } } | Should -Not -Throw
        }

        It 'Show-XKCD -Path records the displayed comic as the most recently viewed' {
            $StatePath = Join-Path $TestDrive 'show-path-state.json'

            Get-XKCDCapturedOutput { Show-XKCD -Path $ExportedFile.FullName -StatePath $StatePath } | Out-Null

            (Get-Content $StatePath | ConvertFrom-Json).LastViewed | Should -Be 353
        }
    }
}
