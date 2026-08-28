if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major
$Root = "$PSScriptRoot/../"
$Module = 'xkcd'

Get-Module $Module | Remove-Module -Force
Import-Module "$Root/$Module" -Force

Describe "Unit Tests PS$PSVersion" {

    Context 'Parameter Input Tests' {

        It 'Show-XKCDExplanation -Num rejects string input' {
            { Show-XKCDExplanation -Num Five } | Should Throw
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

        It 'Show-XKCDExplanation displays the latest comic without throwing' {
            { Show-XKCDExplanation } | Should Not Throw
        }

        It 'Show-XKCDExplanation does not return an object to the pipeline' {
            Show-XKCDExplanation | Should BeNullOrEmpty
        }
    }

    Context 'Specific Comic Tests' {

        It 'Show-XKCDExplanation -Num displays a specific comic without throwing' {
            { Show-XKCDExplanation -Num 2000 } | Should Not Throw
        }

        It 'Show-XKCDExplanation accepts pipeline input of comic numbers' {
            { 1, 2000 | Show-XKCDExplanation } | Should Not Throw
        }

        It 'Show-XKCDExplanation accepts a comic object from Get-XKCD via the pipeline' {
            { Get-XKCD -Num 1 | Show-XKCDExplanation } | Should Not Throw
        }
    }

    Context 'High Quality Tests' {

        # Comic 3290 is known to have a higher resolution (_2x) version available
        It 'Show-XKCDExplanation -HighQuality displays the larger _2x image when available' {
            { Show-XKCDExplanation -Num 3290 -HighQuality } | Should Not Throw
        }

        # Comic 1 does not have a higher resolution version available, so should fall back to standard quality
        It 'Show-XKCDExplanation -HighQuality falls back to standard quality when no _2x image is available' {
            { Show-XKCDExplanation -Num 1 -HighQuality -WarningAction SilentlyContinue } | Should Not Throw
        }
    }

    Context 'Section Tests' {

        It 'Show-XKCDExplanation -Transcript does not throw' {
            { Show-XKCDExplanation -Num 2000 -Transcript } | Should Not Throw
        }

        It 'Show-XKCDExplanation -Discussion does not throw' {
            { Show-XKCDExplanation -Num 2000 -Discussion } | Should Not Throw
        }

        It 'Show-XKCDExplanation -Full does not throw' {
            { Show-XKCDExplanation -Num 2000 -Full } | Should Not Throw
        }
    }

    Context 'Missing Page Tests' {

        It 'Show-XKCDExplanation warns and displays nothing for a comic with no explainxkcd page' {
            $Result = Show-XKCDExplanation -Num 99999999 -WarningAction SilentlyContinue -WarningVariable Warnings

            $Result | Should BeNullOrEmpty
            $Warnings | Should Not BeNullOrEmpty
        }
    }
}
