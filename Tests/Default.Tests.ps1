#---------------------------------# 
# PSScriptAnalyzer tests          # 
#---------------------------------# 
$Scripts = Get-ChildItem “$PSScriptRoot\..\” -Filter ‘*.ps1’ -Recurse | Where-Object {$_.name -NotMatch ‘Tests.ps1’}
$Modules = Get-ChildItem “$PSScriptRoot\..\” -Filter ‘*.psm1’ -Recurse
$Rules   = Get-ScriptAnalyzerRule

if ($Modules.count -gt 0) {
  Describe ‘Testing all Modules against default PSScriptAnalyzer rule-set’ {
    foreach ($module in $modules) {
      Context “Testing Module '$($module.FullName)'” {
        foreach ($rule in $rules) {
          It “passes the PSScriptAnalyzer Rule $rule“ {
            (Invoke-ScriptAnalyzer -Path $module.FullName -IncludeRule $rule.RuleName ).Count | Should Be 0
          }
        }
      }
    }
  }
}
if ($Scripts.count -gt 0) {
  Describe ‘Testing all Script against default PSScriptAnalyzer rule-set’ {
    foreach ($Script in $scripts) {
      Context “Testing Script '$($script.FullName)'” {
        foreach ($rule in $rules) {
          It “passes the PSScriptAnalyzer Rule $rule“ {
            if (-not ($module.BaseName -match 'AppVeyor') -and -not ($rule.Rulename -eq 'PSAvoidUsingWriteHost') ) {
              (Invoke-ScriptAnalyzer -Path $script.FullName -IncludeRule $rule.RuleName ).Count | Should Be 0
            }
          }
        }
      }
    }
  }
}

#---------------------------------# 
# Custom Pester tests (replace)   # 
#---------------------------------# 

$PSVersion    = $PSVersionTable.PSVersion.Major
$AppVeyorDemo = "$PSScriptRoot\..\AppVeyorDemo.psm1"

Describe "AppVeyorDemo PS$PSVersion" {
    Copy-Item $AppVeyorDemo TestDrive:\script.ps1 -Force
    Mock Export-ModuleMember {return $true}
    . 'TestDrive:\script.ps1'
    
    Context 'Strict mode' { 
        Set-StrictMode -Version latest

        It 'Get-SomeInt should return int' {
          Get-SomeInt | Should BeOfType System.Int32
        }     
    }
}