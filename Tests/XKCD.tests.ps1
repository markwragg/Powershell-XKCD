$projectRoot = Resolve-Path "$PSScriptRoot\.."
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psm1")
$moduleName = Split-Path $moduleRoot -Leaf

Describe 'Basic Tests' {

    It "Module '$moduleName' can import cleanly" {
        {Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force } | Should Not Throw
    }

    $Latest = Get-XKCD

    Context 'Latest Comic Tests' {

        It 'Get-XKCD should return a PSCustomObject' {
            $Latest | Should BeOfType 'System.Management.Automation.PSCustomObject'
        }

        It 'Get-XKCD should return an integer' {
            $Latest.num | Should BeOfType [int]
        }

        It "Get-XKCD should return a comic from $((get-date).Year)" {
            ($Latest).year | Should Be (get-date).Year
        }
    }
}
