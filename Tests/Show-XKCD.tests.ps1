if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major
$Root = "$PSScriptRoot/../"
$Module = 'xkcd'

Get-Module $Module | Remove-Module -Force
Import-Module "$Root/$Module" -Force

Describe "Unit Tests PS$PSVersion" {

    Context 'Parameter Input Tests' {

        It 'Show-XKCD -Num rejects string input' {
            { Show-XKCD -Num Five } | Should Throw
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

        It 'Show-XKCD displays the latest comic without throwing' {
            { Show-XKCD } | Should Not Throw
        }

        It 'Show-XKCD does not return an object to the pipeline' {
            Show-XKCD | Should BeNullOrEmpty
        }
    }

    Context 'Specific Comic Tests' {

        It 'Show-XKCD -Num displays a specific comic without throwing' {
            { Show-XKCD -Num 2000 } | Should Not Throw
        }

        It 'Show-XKCD accepts pipeline input of comic numbers' {
            { 1, 4 | Show-XKCD } | Should Not Throw
        }

        It 'Show-XKCD accepts a comic object from Get-XKCD via the pipeline' {
            { Get-XKCD -Num 5 | Show-XKCD } | Should Not Throw
        }
    }

    Context 'High Quality Tests' {

        # Comic 3290 is known to have a higher resolution (_2x) version available
        It 'Show-XKCD -HighQuality displays the larger _2x image when available' {
            { Show-XKCD -Num 3290 -HighQuality } | Should Not Throw
        }

        # Comic 1 does not have a higher resolution version available, so should fall back to standard quality
        It 'Show-XKCD -HighQuality falls back to standard quality when no _2x image is available' {
            { Show-XKCD -Num 1 -HighQuality -WarningAction SilentlyContinue } | Should Not Throw
        }
    }
}
