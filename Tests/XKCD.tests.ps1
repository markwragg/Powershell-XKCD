if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major
$Root = "$PSScriptRoot/../"
$Module = 'xkcd'

If (-not (Get-Module $Module)) { Import-Module "$Root/$Module" -Force }

Describe "Unit Tests PS$PSVersion" {

    Context 'Parameter Input Tests' {

        It 'Get-XKCD -Newest requires an input' {
            { Get-XKCD -Newest } | Should Throw
        }
        It 'Get-XKCD -Newest rejects string input' {
            { Get-XKCD -Newest Ten } | Should Throw
        }        
        It 'Get-XKCD -Num requires an input' {
            { Get-XKCD -Num } | Should Throw
        }
        It 'Get-XKCD -Num rejects string input' {
            { Get-XKCD -Num Five } | Should Throw
        }

        It 'Get-XKCD -Min requires an input' {
            { Get-XKCD -Min } | Should Throw
        }
        It 'Get-XKCD -Min rejects string input' {
            { Get-XKCD -Min Seven } | Should Throw
        }

        It 'Get-XKCD -Max requires an input' {
            { Get-XKCD -Max } | Should Throw
        }
        It 'Get-XKCD -Max rejects string input' {
            { Get-XKCD -Max Twelve } | Should Throw
        }
    
    }
    
    Context 'Parameter Set Tests' {

        It 'Get-XKCD does not allow -Random and -Newest to be used together' {
            { Get-XKCD -Random -Newest 10 } | Should Throw
        }
        It 'Get-XKCD does not allow -Random and -Num to be used together' {
            { Get-XKCD -Random -Num 123 } | Should Throw
        }
        It 'Get-XKCD does not allow -Random and -Num and -Newest to be used together' {
            { Get-XKCD -Random -Num 456 -Newest 5 } | Should Throw
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
    
        $Default = Get-XKCD

        It 'Get-XKCD returns a PSCustomObject' {
            $Default | Should BeOfType 'System.Management.Automation.PSCustomObject'
        }

        It 'Get-XKCD returns an integer for num' {
            $Default.num | Should BeOfType [long]
        }

        It "Get-XKCD returns a string for img" {
            $Default.img | Should BeOfType [string]
        }
    }

    Context 'Random Comic Tests' {
    
        $Random = Get-XKCD -Random

        It 'Get-XKCD -Random returns a PSCustomObject' {
            $Random | Should BeOfType 'System.Management.Automation.PSCustomObject'
        }

        It 'Get-XKCD -Random returns an integer for num' {
            $Random.num | Should BeOfType [long]
        }

        It "Get-XKCD -Random returns a string for img" {
            $Random.img | Should BeOfType [string]
        }
    }

    Context 'Newest Comic Tests' {
    
        $Newest = Get-XKCD -Newest 5

        It 'Get-XKCD -Newest 5 returns a PSCustomObject' {
            $Newest | Should BeOfType 'System.Management.Automation.PSCustomObject'
        }

        It 'Get-XKCD -Newest 5 returns an integer for num' {
            $Newest.num | Should BeOfType [long]
        }

        It "Get-XKCD -Newest 5 returns a string for img" {
            $Newest.img | Should BeOfType [string]
        }

        It "Get-XKCD -Newest 5 returns five results" {
            $Newest.Count | Should Be 5
        }
    }
}
