$moduleName = 'XKCD'
$projectRoot = Resolve-Path "$PSScriptRoot\.."
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\$moduleName\$moduleName.psm1")

Import-Module "$(Resolve-Path "$projectRoot\$moduleName\$moduleName.psm1")"

Describe 'Unit Tests' {

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


Describe 'Integration Tests' {

    Context 'Module Tests' {
        
        It "Module '$moduleName' imports cleanly" {
            {Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force } | Should Not Throw
        }

    }
    
    Context 'Default Comic Tests' {
    
        $Default = Get-XKCD

        It 'Get-XKCD returns a PSCustomObject' {
            $Default | Should BeOfType 'System.Management.Automation.PSCustomObject'
        }

        It 'Get-XKCD returns an integer for num' {
            $Default.num | Should BeOfType [int]
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
            $Random.num | Should BeOfType [int]
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
            $Newest.num | Should BeOfType [int]
        }

        It "Get-XKCD -Newest 5 returns a string for img" {
            $Newest.img | Should BeOfType [string]
        }

        It "Get-XKCD -Newest 5 returns five results" {
            $Newest.Count | Should Be 5
        }
    }
}
