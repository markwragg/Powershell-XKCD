if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major
$Root = "$PSScriptRoot/../"
$Module = 'xkcd'

Get-Module $Module | Remove-Module -Force
Import-Module "$Root/$Module" -Force

Describe "Integration Tests PS$PSVersion" -tag 'Integration' {
    
    Context 'Default Comic Tests' {
    
        $Default = Find-XKCD -Query 'Spiders'

        It 'Find-XKCD returns a PSCustomObject' {
            $Default | Should BeOfType 'System.Management.Automation.PSCustomObject'
        }

        It "Find-XKCD returns 4 comics" {
            $Default.count | Should Be 4
        }
    }
}
