Import-Module $PSScriptRoot\XKCD.psm1 -Force

Describe 'Basic Tests' {
    $Latest = Get-XKCD

    It 'Get-XKCD should return a PSCustomObject' {
        $Latest | Should BeOfType 'System.Management.Automation.PSCustomObject'
    }

    It 'Get-XKCD should return an integer' {
        $Latest.num | Should BeOfType [int]
    }

    #Not a good test but just for fun
    It "Get-XKCD should return a comic from $((get-date).Year)" {
        ($Latest).year | Should Be (get-date).Year
    }
}
