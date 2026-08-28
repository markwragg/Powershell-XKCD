if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major
$Root = "$PSScriptRoot/../"
$Module = 'xkcd'

Get-Module $Module | Remove-Module -Force
Import-Module "$Root/$Module" -Force

Function Get-XKCDCapturedOutput {
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

Describe "Unit Tests PS$PSVersion" {

    Context 'Parameter Input Tests' {

        It 'Show-XKCDExplanation -Num rejects string input' {
            { Show-XKCDExplanation -Num Five } | Should -Throw
        }
    }

    Context 'Comic Display Tests' {

        # Mocks isolate Show-XKCDExplanation from the live network, so these tests can assert on
        # exactly when the comic image is (and isn't) fetched and displayed.

        Mock -ModuleName $Module Get-XKCDExplanation {
            [pscustomobject]@{
                Num         = 1000
                Title       = 'A Test Comic'
                Url         = 'https://www.explainxkcd.com/wiki/index.php/1000'
                Explanation = 'The explanation text.'
                Transcript  = 'The transcript text.'
                Discussion  = 'The discussion text.'
            }
        }
        Mock -ModuleName $Module Get-XKCD {
            [pscustomobject]@{
                num   = 1000
                title = 'A Test Comic'
                img   = 'https://imgs.xkcd.com/comics/test.png'
                alt   = 'Some alt text for the test comic.'
            }
        }
        Mock -ModuleName $Module Invoke-WebRequest { [pscustomobject]@{ Content = [byte[]](1..10) } }
        Mock -ModuleName $Module Show-XKCDImage { }

        It 'Fetches and displays the comic image by default' {
            $Output = Get-XKCDCapturedOutput { Show-XKCDExplanation -Num 1000 }

            $Output | Should -Match 'https://xkcd\.com/1000'
            $Output | Should -Match 'Some alt text for the test comic\.'
            Should -Invoke -CommandName Get-XKCD -ModuleName $Module -Times 1 -Exactly -Scope It
            Should -Invoke -CommandName Show-XKCDImage -ModuleName $Module -Times 1 -Exactly -Scope It
        }

        It '-Explanation does not fetch or display the comic image' {
            $Output = Get-XKCDCapturedOutput { Show-XKCDExplanation -Num 1000 -Explanation }

            $Output | Should -Not -Match 'https://xkcd\.com/1000'
            Should -Invoke -CommandName Get-XKCD -ModuleName $Module -Times 0 -Exactly -Scope It
            Should -Invoke -CommandName Show-XKCDImage -ModuleName $Module -Times 0 -Exactly -Scope It
        }

        It '-Transcript does not fetch or display the comic image' {
            $Output = Get-XKCDCapturedOutput { Show-XKCDExplanation -Num 1000 -Transcript }

            $Output | Should -Not -Match 'https://xkcd\.com/1000'
            Should -Invoke -CommandName Get-XKCD -ModuleName $Module -Times 0 -Exactly -Scope It
        }

        It '-Discussion does not fetch or display the comic image' {
            $Output = Get-XKCDCapturedOutput { Show-XKCDExplanation -Num 1000 -Discussion }

            $Output | Should -Not -Match 'https://xkcd\.com/1000'
            Should -Invoke -CommandName Get-XKCD -ModuleName $Module -Times 0 -Exactly -Scope It
        }

        It '-Full still fetches and displays the comic image' {
            $Output = Get-XKCDCapturedOutput { Show-XKCDExplanation -Num 1000 -Full }

            $Output | Should -Match 'https://xkcd\.com/1000'
            Should -Invoke -CommandName Get-XKCD -ModuleName $Module -Times 1 -Exactly -Scope It
            Should -Invoke -CommandName Show-XKCDImage -ModuleName $Module -Times 1 -Exactly -Scope It
        }

        It '-Full with -Transcript and -Discussion still fetches and displays the comic image' {
            $Output = Get-XKCDCapturedOutput { Show-XKCDExplanation -Num 1000 -Transcript -Discussion -Full }

            $Output | Should -Match 'https://xkcd\.com/1000'
            Should -Invoke -CommandName Get-XKCD -ModuleName $Module -Times 1 -Exactly -Scope It
        }
    }

    Context 'Section Selection Tests' {

        Mock -ModuleName $Module Get-XKCDExplanation {
            [pscustomobject]@{
                Num         = 1000
                Title       = 'A Test Comic'
                Url         = 'https://www.explainxkcd.com/wiki/index.php/1000'
                Explanation = 'The explanation text.'
                Transcript  = 'The transcript text.'
                Discussion  = 'The discussion text.'
            }
        }
        Mock -ModuleName $Module Get-XKCD {
            [pscustomobject]@{
                num   = 1000
                title = 'A Test Comic'
                img   = 'https://imgs.xkcd.com/comics/test.png'
                alt   = 'Some alt text for the test comic.'
            }
        }
        Mock -ModuleName $Module Invoke-WebRequest { [pscustomobject]@{ Content = [byte[]](1..10) } }
        Mock -ModuleName $Module Show-XKCDImage { }

        It 'By default, displays only the explanation' {
            $Output = Get-XKCDCapturedOutput { Show-XKCDExplanation -Num 1000 }

            $Output | Should -Match 'The explanation text\.'
            $Output | Should -Not -Match 'The transcript text\.'
            $Output | Should -Not -Match 'The discussion text\.'
        }

        It '-Transcript on its own displays only the transcript, not the explanation' {
            $Output = Get-XKCDCapturedOutput { Show-XKCDExplanation -Num 1000 -Transcript }

            $Output | Should -Match 'The transcript text\.'
            $Output | Should -Not -Match 'The explanation text\.'
            $Output | Should -Not -Match 'The discussion text\.'
            $Output | Should -Not -Match 'No explanation is available yet\.'
        }

        It '-Discussion on its own displays only the discussion, not the explanation' {
            $Output = Get-XKCDCapturedOutput { Show-XKCDExplanation -Num 1000 -Discussion }

            $Output | Should -Match 'The discussion text\.'
            $Output | Should -Not -Match 'The explanation text\.'
            $Output | Should -Not -Match 'The transcript text\.'
            $Output | Should -Not -Match 'No explanation is available yet\.'
        }

        It '-Transcript and -Discussion together display both, but not the explanation' {
            $Output = Get-XKCDCapturedOutput { Show-XKCDExplanation -Num 1000 -Transcript -Discussion }

            $Output | Should -Match 'The transcript text\.'
            $Output | Should -Match 'The discussion text\.'
            $Output | Should -Not -Match 'The explanation text\.'
        }

        It '-Explanation and -Discussion together display both, but not the transcript' {
            $Output = Get-XKCDCapturedOutput { Show-XKCDExplanation -Num 1000 -Explanation -Discussion }

            $Output | Should -Match 'The explanation text\.'
            $Output | Should -Match 'The discussion text\.'
            $Output | Should -Not -Match 'The transcript text\.'
        }

        It '-Full displays all three sections' {
            $Output = Get-XKCDCapturedOutput { Show-XKCDExplanation -Num 1000 -Full }

            $Output | Should -Match 'The explanation text\.'
            $Output | Should -Match 'The transcript text\.'
            $Output | Should -Match 'The discussion text\.'
        }
    }
}


Describe "Integration Tests PS$PSVersion" -tag 'Integration' {

    Context 'Module Tests' {

        It "Module '$Module' imports cleanly" {
            { Import-Module "$Root/$Module" -force } | Should -Not -Throw
        }
    }

    Context 'Default Comic Tests' {

        It 'Show-XKCDExplanation displays the latest comic without throwing' {
            { Show-XKCDExplanation } | Should -Not -Throw
        }

        It 'Show-XKCDExplanation does not return an object to the pipeline' {
            Show-XKCDExplanation | Should -BeNullOrEmpty
        }
    }

    Context 'Specific Comic Tests' {

        It 'Show-XKCDExplanation -Num displays a specific comic without throwing' {
            { Show-XKCDExplanation -Num 2000 } | Should -Not -Throw
        }

        It 'Show-XKCDExplanation accepts pipeline input of comic numbers' {
            { 1, 2000 | Show-XKCDExplanation } | Should -Not -Throw
        }

        It 'Show-XKCDExplanation accepts a comic object from Get-XKCD via the pipeline' {
            { Get-XKCD -Num 1 | Show-XKCDExplanation } | Should -Not -Throw
        }
    }

    Context 'High Quality Tests' {

        # Comic 3290 is known to have a higher resolution (_2x) version available
        It 'Show-XKCDExplanation -HighQuality displays the larger _2x image when available' {
            { Show-XKCDExplanation -Num 3290 -HighQuality } | Should -Not -Throw
        }

        # Comic 1 does not have a higher resolution version available, so should fall back to standard quality
        It 'Show-XKCDExplanation -HighQuality falls back to standard quality when no _2x image is available' {
            { Show-XKCDExplanation -Num 1 -HighQuality -WarningAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context 'Section Tests' {

        It 'Show-XKCDExplanation -Transcript does not throw' {
            { Show-XKCDExplanation -Num 2000 -Transcript } | Should -Not -Throw
        }

        It 'Show-XKCDExplanation -Discussion does not throw' {
            { Show-XKCDExplanation -Num 2000 -Discussion } | Should -Not -Throw
        }

        It 'Show-XKCDExplanation -Full does not throw' {
            { Show-XKCDExplanation -Num 2000 -Full } | Should -Not -Throw
        }
    }

    Context 'Missing Page Tests' {

        It 'Show-XKCDExplanation warns and displays nothing for a comic with no explainxkcd page' {
            $Result = Show-XKCDExplanation -Num 99999999 -WarningAction SilentlyContinue -WarningVariable Warnings

            $Result | Should -BeNullOrEmpty
            $Warnings | Should -Not -BeNullOrEmpty
        }
    }
}
