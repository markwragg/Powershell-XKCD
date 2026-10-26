if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Unit Tests PS$PSVersion" {

    BeforeAll {
        $Root = "$PSScriptRoot/../.."
        $Module = 'xkcd'

        Get-Module $Module | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module "$Root/$Module" -Force

        $ModuleObj = Get-Module $Module

        function Get-XKCDCapturedOutput {
            Param(
                [scriptblock]$ScriptBlock
            )

            $OriginalOut = [Console]::Out
            $Writer = [System.IO.StringWriter]::new()

            try {
                [Console]::SetOut($Writer)
                & $ScriptBlock
            }
            finally {
                [Console]::SetOut($OriginalOut)
            }

            $Writer.ToString()
        }
    }

    Context 'Read-XKCDComicNumberPrompt Tests' {

        It 'Returns the typed number when it is within range' {
            Mock -ModuleName $Module Read-XKCDConsoleLine { '353' }

            $Result = & $ModuleObj { Param($Latest) Read-XKCDComicNumberPrompt -Latest $Latest } 500

            $Result | Should -Be 353
        }

        It 'Writes a prompt showing the valid range' {
            Mock -ModuleName $Module Read-XKCDConsoleLine { '1' }

            $Output = Get-XKCDCapturedOutput {
                & $ModuleObj { Param($Latest) Read-XKCDComicNumberPrompt -Latest $Latest } 500 | Out-Null
            }

            $Output | Should -Match '1-500'
        }

        It 'Returns $null when the typed number is above -Latest' {
            Mock -ModuleName $Module Read-XKCDConsoleLine { '501' }

            $Result = & $ModuleObj { Param($Latest) Read-XKCDComicNumberPrompt -Latest $Latest } 500

            $Result | Should -BeNullOrEmpty
        }

        It 'Returns $null when the typed number is below 1' {
            Mock -ModuleName $Module Read-XKCDConsoleLine { '0' }

            $Result = & $ModuleObj { Param($Latest) Read-XKCDComicNumberPrompt -Latest $Latest } 500

            $Result | Should -BeNullOrEmpty
        }

        It 'Returns $null when the input is not a number' {
            Mock -ModuleName $Module Read-XKCDConsoleLine { 'banana' }

            $Result = & $ModuleObj { Param($Latest) Read-XKCDComicNumberPrompt -Latest $Latest } 500

            $Result | Should -BeNullOrEmpty
        }

        It 'Returns $null when the input is blank' {
            Mock -ModuleName $Module Read-XKCDConsoleLine { '' }

            $Result = & $ModuleObj { Param($Latest) Read-XKCDComicNumberPrompt -Latest $Latest } 500

            $Result | Should -BeNullOrEmpty
        }
    }
}
