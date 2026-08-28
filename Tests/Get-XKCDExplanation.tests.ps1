if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major
$Root = "$PSScriptRoot/../"
$Module = 'xkcd'

Get-Module $Module | Remove-Module -Force
Import-Module "$Root/$Module" -Force

Describe "Unit Tests PS$PSVersion" {

    Context 'Parameter Input Tests' {

        It 'Get-XKCDExplanation -Num rejects string input' {
            { Get-XKCDExplanation -Num Five } | Should Throw
        }
    }
}


Describe "Integration Tests PS$PSVersion" -tag 'Integration' {

    Context 'Module Tests' {

        It "Module '$Module' imports cleanly" {
            { Import-Module "$Root/$Module" -force } | Should Not Throw
        }
    }

    Context 'Default Comic Tests' {

        $Default = Get-XKCDExplanation

        It 'Get-XKCDExplanation returns a PSCustomObject' {
            $Default | Should BeOfType 'System.Management.Automation.PSCustomObject'
        }

        It 'Get-XKCDExplanation returns a string for Explanation' {
            $Default.Explanation | Should BeOfType [string]
        }

        It 'Get-XKCDExplanation returns non-empty explanation text' {
            $Default.Explanation | Should Not BeNullOrEmpty
        }
    }

    Context 'Specific Comic Tests' {

        # Comic 2000 is a known, stable page on explainxkcd
        $Comic = Get-XKCDExplanation -Num 2000

        It 'Get-XKCDExplanation returns the requested comic number' {
            $Comic.Num | Should Be 2000
        }

        It 'Get-XKCDExplanation returns the comic title without the leading number prefix' {
            $Comic.Title | Should Be 'xkcd Phone 2000'
        }

        It 'Get-XKCDExplanation returns the explainxkcd URL for the comic' {
            $Comic.Url | Should Be 'https://www.explainxkcd.com/wiki/index.php/2000'
        }

        It 'Get-XKCDExplanation returns the explanation text without wiki markup' {
            $Comic.Explanation | Should Match 'xkcd Phone series'
            $Comic.Explanation | Should Not Match '\{\{|\}\}|\[\['
        }
    }

    Context 'Transcript and Discussion Tests' {

        # No -Transcript/-Discussion/-Full switches: these properties are always populated
        $Comic = Get-XKCDExplanation -Num 2000

        It 'Get-XKCDExplanation always returns a Transcript property' {
            $Comic.PSObject.Properties.Name | Should Contain 'Transcript'
            $Comic.Transcript | Should Match 'Dockless'
            $Comic.Transcript | Should Not Match '\{\{|\}\}|\[\['
        }

        It 'Get-XKCDExplanation always returns a Discussion property' {
            $Comic.PSObject.Properties.Name | Should Contain 'Discussion'
            $Comic.Discussion | Should Not BeNullOrEmpty
            $Comic.Discussion | Should Not Match '\{\{|\}\}|\[\['
        }
    }

    Context 'Pipeline Input Tests' {

        It 'Get-XKCDExplanation accepts pipeline input of comic numbers' {
            { 1, 2000 | Get-XKCDExplanation } | Should Not Throw
        }

        It 'Get-XKCDExplanation accepts a comic object from Get-XKCD via the pipeline' {
            { Get-XKCD -Num 1 | Get-XKCDExplanation } | Should Not Throw
        }
    }

    Context 'Missing Page Tests' {

        It 'Get-XKCDExplanation warns and returns nothing for a comic with no explainxkcd page' {
            $Result = Get-XKCDExplanation -Num 99999999 -WarningAction SilentlyContinue -WarningVariable Warnings

            $Result | Should BeNullOrEmpty
            $Warnings | Should Not BeNullOrEmpty
        }
    }

    Context 'Show Tests' {

        It 'Get-XKCDExplanation -Show does not throw' {
            { Get-XKCDExplanation -Num 1 -Show } | Should Not Throw
        }

        It 'Get-XKCDExplanation -Show does not return the explanation object' {
            Get-XKCDExplanation -Num 1 -Show | Should BeNullOrEmpty
        }

        It 'Get-XKCDExplanation -Show -Full does not throw' {
            { Get-XKCDExplanation -Num 1 -Show -Full } | Should Not Throw
        }
    }
}
