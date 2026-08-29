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

        It 'Get-XKCDExplanation -Num rejects string input' {
            { Get-XKCDExplanation -Num Five } | Should -Throw
        }

        It 'Get-XKCDExplanation -Newest requires an input' {
            { Get-XKCDExplanation -Newest } | Should -Throw
        }
        It 'Get-XKCDExplanation -Newest rejects string input' {
            { Get-XKCDExplanation -Newest Ten } | Should -Throw
        }

        It 'Get-XKCDExplanation -Min requires an input' {
            { Get-XKCDExplanation -Min } | Should -Throw
        }
        It 'Get-XKCDExplanation -Min rejects string input' {
            { Get-XKCDExplanation -Min Seven } | Should -Throw
        }

        It 'Get-XKCDExplanation -Max requires an input' {
            { Get-XKCDExplanation -Max } | Should -Throw
        }
        It 'Get-XKCDExplanation -Max rejects string input' {
            { Get-XKCDExplanation -Max Twelve } | Should -Throw
        }
    }

    Context 'Parameter Set Tests' {

        It 'Get-XKCDExplanation does not allow -Random and -Newest to be used together' {
            { Get-XKCDExplanation -Random -Newest 10 } | Should -Throw
        }
        It 'Get-XKCDExplanation does not allow -Random and -Num to be used together' {
            { Get-XKCDExplanation -Random -Num 123 } | Should -Throw
        }
        It 'Get-XKCDExplanation does not allow -Random and -Num and -Newest to be used together' {
            { Get-XKCDExplanation -Random -Num 456 -Newest 5 } | Should -Throw
        }
    }
}


Describe "Integration Tests PS$PSVersion" -tag 'Integration' {

    BeforeAll {
        $Root = "$PSScriptRoot/../"
        $Module = 'xkcd'

        Get-Module $Module | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module "$Root/$Module" -Force

        # Get-XKCDExplanation -Show renders the explanation straight to the console; running it here
        # would otherwise spam the real terminal with comic art and explanation text every time these run.
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
            $Default = Get-XKCDExplanation
        }

        It 'Get-XKCDExplanation returns a PSCustomObject' {
            $Default | Should -BeOfType 'System.Management.Automation.PSCustomObject'
        }

        It 'Get-XKCDExplanation returns a string for Explanation' {
            $Default.Explanation | Should -BeOfType [string]
        }

        It 'Get-XKCDExplanation returns non-empty explanation text' {
            $Default.Explanation | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Specific Comic Tests' {

        BeforeAll {
            # Comic 2000 is a known, stable page on explainxkcd
            $Comic = Get-XKCDExplanation -Num 2000
        }

        It 'Get-XKCDExplanation returns the requested comic number' {
            $Comic.Num | Should -Be 2000
        }

        It 'Get-XKCDExplanation returns the comic title without the leading number prefix' {
            $Comic.Title | Should -Be 'xkcd Phone 2000'
        }

        It 'Get-XKCDExplanation returns the explainxkcd URL for the comic' {
            $Comic.Url | Should -Be 'https://www.explainxkcd.com/wiki/index.php/2000'
        }

        It 'Get-XKCDExplanation returns the explanation text without wiki markup' {
            $Comic.Explanation | Should -Match 'xkcd Phone series'
            $Comic.Explanation | Should -Not -Match '\{\{|\}\}|\[\['
        }
    }

    Context 'Transcript and Discussion Tests' {

        It 'Get-XKCDExplanation without -Transcript/-Discussion/-Full omits the Transcript and Discussion properties' {
            $Comic = Get-XKCDExplanation -Num 2000

            $Comic.PSObject.Properties.Name | Should -Not -Contain 'Transcript'
            $Comic.PSObject.Properties.Name | Should -Not -Contain 'Discussion'
        }

        It 'Get-XKCDExplanation -Transcript retrieves the Transcript but not the Discussion' {
            $Comic = Get-XKCDExplanation -Num 2000 -Transcript

            $Comic.Transcript | Should -Match 'Dockless'
            $Comic.Transcript | Should -Not -Match '\{\{|\}\}|\[\['
            $Comic.PSObject.Properties.Name | Should -Not -Contain 'Discussion'
        }

        It 'Get-XKCDExplanation -Discussion retrieves the Discussion but not the Transcript' {
            $Comic = Get-XKCDExplanation -Num 2000 -Discussion

            $Comic.Discussion | Should -Not -BeNullOrEmpty
            $Comic.Discussion | Should -Not -Match '\{\{|\}\}|\[\['
            $Comic.PSObject.Properties.Name | Should -Not -Contain 'Transcript'
        }

        It 'Get-XKCDExplanation -Full retrieves both the Transcript and the Discussion' {
            $Comic = Get-XKCDExplanation -Num 2000 -Full

            $Comic.Transcript | Should -Match 'Dockless'
            $Comic.Discussion | Should -Not -BeNullOrEmpty
        }

        It 'Get-XKCDExplanation -Explanation without -Show only returns the Explanation property' {
            $Result = Get-XKCDExplanation -Num 2000 -Explanation
            $Result.PSObject.Properties.Name | Should -Contain 'Explanation'
            $Result.PSObject.Properties.Name | Should -Not -Contain 'Transcript'
            $Result.PSObject.Properties.Name | Should -Not -Contain 'Discussion'
            $Result.Explanation | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Random Comic Tests' {

        BeforeAll {
            $Random = Get-XKCDExplanation -Random
        }

        It 'Get-XKCDExplanation -Random returns a PSCustomObject' {
            $Random | Should -BeOfType 'System.Management.Automation.PSCustomObject'
        }

        It 'Get-XKCDExplanation -Random returns non-empty explanation text' {
            $Random.Explanation | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Random Range Tests' {

        It 'Get-XKCDExplanation -Random -Min -Max returns a comic within the specified range' {
            $RandomInRange = Get-XKCDExplanation -Random -Min 100 -Max 150
            $RandomInRange.Num | Should -BeGreaterThan 99
            $RandomInRange.Num | Should -BeLessThan 151
        }
    }

    Context 'Newest Comic Tests' {

        BeforeAll {
            $Newest = Get-XKCDExplanation -Newest 3
        }

        It 'Get-XKCDExplanation -Newest 3 returns a PSCustomObject' {
            $Newest | Should -BeOfType 'System.Management.Automation.PSCustomObject'
        }

        It 'Get-XKCDExplanation -Newest 3 returns three results' {
            $Newest.Count | Should -Be 3
        }
    }

    Context 'Pipeline Input Tests' {

        It 'Get-XKCDExplanation accepts pipeline input of comic numbers' {
            { 1, 2000 | Get-XKCDExplanation } | Should -Not -Throw
        }

        It 'Get-XKCDExplanation accepts a comic object from Get-XKCD via the pipeline' {
            { Get-XKCD -Num 1 | Get-XKCDExplanation } | Should -Not -Throw
        }
    }

    Context 'Missing Page Tests' {

        It 'Get-XKCDExplanation warns and returns nothing for a comic with no explainxkcd page' {
            $Result = Get-XKCDExplanation -Num 99999999 -WarningAction SilentlyContinue -WarningVariable Warnings

            $Result | Should -BeNullOrEmpty
            $Warnings | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Show Tests' {

        It 'Get-XKCDExplanation -Show does not throw' {
            { Get-XKCDCapturedOutput { Get-XKCDExplanation -Num 1 -Show } } | Should -Not -Throw
        }

        It 'Get-XKCDExplanation -Show does not return the explanation object' {
            Get-XKCDCapturedOutput { $script:Result = Get-XKCDExplanation -Num 1 -Show } | Out-Null
            $script:Result | Should -BeNullOrEmpty
        }

        It 'Get-XKCDExplanation -Show -Full does not throw' {
            { Get-XKCDCapturedOutput { Get-XKCDExplanation -Num 1 -Show -Full } } | Should -Not -Throw
        }

        It 'Get-XKCDExplanation -Show -Explanation does not throw' {
            { Get-XKCDCapturedOutput { Get-XKCDExplanation -Num 1 -Show -Explanation } } | Should -Not -Throw
        }
    }

    Context 'Open Tests' {

        # -Scope It keeps each assertion's call count limited to its own test, since mock call
        # history otherwise accumulates for the duration of the Context.

        It 'Get-XKCDExplanation -Open -Force opens the comic without prompting for confirmation' {
            Mock -ModuleName $Module Start-Process { }

            { Get-XKCDExplanation -Num 1 -Open -Force } | Should -Not -Throw
            Should -Invoke -CommandName Start-Process -ModuleName $Module -Times 1 -Exactly -Scope It -ParameterFilter { $FilePath -eq 'https://xkcd.com/1' }
        }

        It 'Get-XKCDExplanation -Open opens fewer than 10 comics without prompting for confirmation' {
            Mock -ModuleName $Module Start-Process { }

            { Get-XKCDExplanation -Num 2 -Open } | Should -Not -Throw
            Should -Invoke -CommandName Start-Process -ModuleName $Module -Times 1 -Exactly -Scope It -ParameterFilter { $FilePath -eq 'https://xkcd.com/2' }
        }

        It 'Get-XKCDExplanation -Open prompts for confirmation and opens comics when 10 or more are requested and confirmed' {
            Mock -ModuleName $Module Read-Host { 'y' }
            Mock -ModuleName $Module Start-Process { }

            { Get-XKCDExplanation -Num (11..20) -Open } | Should -Not -Throw
            Should -Invoke -CommandName Read-Host -ModuleName $Module -Times 1 -Exactly -Scope It
            Should -Invoke -CommandName Start-Process -ModuleName $Module -Times 10 -Exactly -Scope It -ParameterFilter { $FilePath -match '^https://xkcd\.com/1[1-9]$|^https://xkcd\.com/20$' }
        }

        It 'Get-XKCDExplanation -Open prompts for confirmation and does not open comics when declined' {
            Mock -ModuleName $Module Read-Host { 'n' }
            Mock -ModuleName $Module Start-Process { }

            { Get-XKCDExplanation -Num (21..30) -Open } | Should -Not -Throw
            Should -Invoke -CommandName Read-Host -ModuleName $Module -Times 1 -Exactly -Scope It
            Should -Invoke -CommandName Start-Process -ModuleName $Module -Times 0 -Exactly -Scope It -ParameterFilter { $FilePath -match '^https://xkcd\.com/2[1-9]$|^https://xkcd\.com/30$' }
        }
    }
}
