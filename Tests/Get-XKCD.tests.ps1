if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major
$Root = "$PSScriptRoot/../"
$Module = 'xkcd'

Get-Module $Module | Remove-Module -Force
Import-Module "$Root/$Module" -Force

Describe "Unit Tests PS$PSVersion" {

    Context 'Parameter Input Tests' {

        It 'Get-XKCD -Newest requires an input' {
            { Get-XKCD -Newest } | Should -Throw
        }
        It 'Get-XKCD -Newest rejects string input' {
            { Get-XKCD -Newest Ten } | Should -Throw
        }        
        It 'Get-XKCD -Num requires an input' {
            { Get-XKCD -Num } | Should -Throw
        }
        It 'Get-XKCD -Num rejects string input' {
            { Get-XKCD -Num Five } | Should -Throw
        }

        It 'Get-XKCD -Min requires an input' {
            { Get-XKCD -Min } | Should -Throw
        }
        It 'Get-XKCD -Min rejects string input' {
            { Get-XKCD -Min Seven } | Should -Throw
        }

        It 'Get-XKCD -Max requires an input' {
            { Get-XKCD -Max } | Should -Throw
        }
        It 'Get-XKCD -Max rejects string input' {
            { Get-XKCD -Max Twelve } | Should -Throw
        }
    
    }
    
    Context 'Parameter Set Tests' {

        It 'Get-XKCD does not allow -Random and -Newest to be used together' {
            { Get-XKCD -Random -Newest 10 } | Should -Throw
        }
        It 'Get-XKCD does not allow -Random and -Num to be used together' {
            { Get-XKCD -Random -Num 123 } | Should -Throw
        }
        It 'Get-XKCD does not allow -Random and -Num and -Newest to be used together' {
            { Get-XKCD -Random -Num 456 -Newest 5 } | Should -Throw
        }
        
    }
}


Describe "Integration Tests PS$PSVersion" -tag 'Integration' {

    BeforeAll {
        $Root = "$PSScriptRoot/../"
        $Module = 'xkcd'

        Get-Module $Module | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module "$Root/$Module" -Force
    }

    Context 'Module Tests' {
        
        It "Module '$Module' imports cleanly" {
            { Import-Module "$Root/$Module" -force } | Should -Not -Throw
        }

    }
    
    Context 'Default Comic Tests' {

        BeforeAll {
            $Default = Get-XKCD -Download -Path $TestDrive
        }

        It 'Get-XKCD returns a PSCustomObject' {
            $Default | Should -BeOfType 'System.Management.Automation.PSCustomObject'
        }

        It "Get-XKCD returns a string for img" {
            $Default.img | Should -BeOfType [string]
        }

        It "Get-XKCD -Download saves the file using the extension from img" {
            $Extension = [System.IO.Path]::GetExtension(([uri]$Default.img).AbsolutePath)
            Join-Path $TestDrive "$($Default.num)$Extension" | Should -Exist
        }
    }

    Context 'Download Extension Tests' {

        BeforeAll {
            # Comic 2000 is known to have a .png image, rather than the default .jpg
            $PngComic = Get-XKCD -Num 2000 -Download -Path $TestDrive
        }

        It "Get-XKCD -Download saves a non-jpg image using its actual extension" {
            $PngComic.img | Should -Match '\.png$'
            Join-Path $TestDrive "2000.png" | Should -Exist
        }
    }

    Context 'High Quality Download Tests' {

        BeforeAll {
            # Comic 3290 is known to have a higher resolution (_2x) version available
            Get-XKCD -Num 3290 -Download -HighQuality -Path $TestDrive
            $StandardPath = Join-Path $TestDrive 'standard.png'
            Invoke-WebRequest 'https://imgs.xkcd.com/comics/trade.png' -OutFile $StandardPath -UseBasicParsing
        }

        It "Get-XKCD -HighQuality downloads the larger _2x image when available" {
            (Get-Item (Join-Path $TestDrive '3290.png')).Length | Should -BeGreaterThan (Get-Item $StandardPath).Length
        }

        # Comic 1 does not have a higher resolution version available, so should fall back to standard quality
        It "Get-XKCD -HighQuality falls back to standard quality when no _2x image is available" {
            { Get-XKCD -Num 1 -Download -HighQuality -Path $TestDrive } | Should -Not -Throw
            Join-Path $TestDrive '1.jpg' | Should -Exist
        }
    }

    Context 'Random Comic Tests' {

        BeforeAll {
            $Random = Get-XKCD -Random
        }

        It 'Get-XKCD -Random returns a PSCustomObject' {
            $Random | Should -BeOfType 'System.Management.Automation.PSCustomObject'
        }

        It "Get-XKCD -Random returns a string for img" {
            $Random.img | Should -BeOfType [string]
        }
    }

    Context 'Newest Comic Tests' {

        BeforeAll {
            $Newest = Get-XKCD -Newest 5
        }

        It 'Get-XKCD -Newest 5 returns a PSCustomObject' {
            $Newest | Should -BeOfType 'System.Management.Automation.PSCustomObject'
        }

        It "Get-XKCD -Newest 5 returns a string for img" {
            $Newest.img | Should -BeOfType [string]
        }

        It "Get-XKCD -Newest 5 returns five results" {
            $Newest.Count | Should -Be 5
        }
    }

    Context 'Show Tests' {

        It 'Get-XKCD -Show does not throw' {
            { Get-XKCD -Num 1 -Show } | Should -Not -Throw
        }

        It 'Get-XKCD -Show does not return the comic object' {
            Get-XKCD -Num 1 -Show | Should -BeNullOrEmpty
        }

        It 'Get-XKCD -Show records the displayed comic as the most recently viewed' {
            $StatePath = Join-Path $TestDrive 'get-show-state.json'

            Get-XKCD -Num 200 -Show -StatePath $StatePath

            $StatePath | Should -Exist
            (Get-Content $StatePath | ConvertFrom-Json).LastViewed | Should -Be 200
        }
    }

    Context 'Random Range Tests' {

        It 'Get-XKCD -Random -Min -Max returns a comic within the specified range' {
            $RandomInRange = Get-XKCD -Random -Min 100 -Max 150
            $RandomInRange.num | Should -BeGreaterThan 99
            $RandomInRange.num | Should -BeLessThan 151
        }
    }

    Context 'Open Tests' {

        # -Scope It keeps each assertion's call count limited to its own test, since mock call
        # history otherwise accumulates for the duration of the Context.

        It 'Get-XKCD -Open -Force opens the comic without prompting for confirmation' {
            Mock -ModuleName $Module Start-Process { }

            { Get-XKCD -Num 1 -Open -Force } | Should -Not -Throw
            Should -Invoke -CommandName Start-Process -ModuleName $Module -Times 1 -Exactly -Scope It -ParameterFilter { $FilePath -eq 'https://xkcd.com/1' }
        }

        It 'Get-XKCD -Open opens fewer than 10 comics without prompting for confirmation' {
            Mock -ModuleName $Module Start-Process { }

            { Get-XKCD -Num 2 -Open } | Should -Not -Throw
            Should -Invoke -CommandName Start-Process -ModuleName $Module -Times 1 -Exactly -Scope It -ParameterFilter { $FilePath -eq 'https://xkcd.com/2' }
        }

        It 'Get-XKCD -Open prompts for confirmation and opens comics when 10 or more are requested and confirmed' {
            Mock -ModuleName $Module Read-Host { 'y' }
            Mock -ModuleName $Module Start-Process { }

            { Get-XKCD -Num (11..20) -Open } | Should -Not -Throw
            Should -Invoke -CommandName Read-Host -ModuleName $Module -Times 1 -Exactly -Scope It
            Should -Invoke -CommandName Start-Process -ModuleName $Module -Times 10 -Exactly -Scope It -ParameterFilter { $FilePath -match '^https://xkcd\.com/1[1-9]$|^https://xkcd\.com/20$' }
        }

        It 'Get-XKCD -Open prompts for confirmation and does not open comics when declined' {
            Mock -ModuleName $Module Read-Host { 'n' }
            Mock -ModuleName $Module Start-Process { }

            { Get-XKCD -Num (21..30) -Open } | Should -Not -Throw
            Should -Invoke -CommandName Read-Host -ModuleName $Module -Times 1 -Exactly -Scope It
            Should -Invoke -CommandName Start-Process -ModuleName $Module -Times 0 -Exactly -Scope It -ParameterFilter { $FilePath -match '^https://xkcd\.com/2[1-9]$|^https://xkcd\.com/30$' }
        }
    }
}
