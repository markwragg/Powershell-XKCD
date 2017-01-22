Import-Module $PSScriptRoot\powershell-XKCD.psm1 -Force

Describe 'Basic Tests' {
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
