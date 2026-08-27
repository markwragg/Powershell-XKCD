if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major
$Root = "$PSScriptRoot/../"
$Module = 'xkcd'

Get-Module $Module | Remove-Module -Force
Import-Module "$Root/$Module" -Force

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
    
        $Default = Get-XKCD -Download -Path $TestDrive

        It 'Get-XKCD returns a PSCustomObject' {
            $Default | Should BeOfType 'System.Management.Automation.PSCustomObject'
        }

        It "Get-XKCD returns a string for img" {
            $Default.img | Should BeOfType [string]
        }

        It "Get-XKCD -Download saves the file using the extension from img" {
            $Extension = [System.IO.Path]::GetExtension(([uri]$Default.img).AbsolutePath)
            Join-Path $TestDrive "$($Default.num)$Extension" | Should Exist
        }
    }

    Context 'Download Extension Tests' {

        # Comic 2000 is known to have a .png image, rather than the default .jpg
        $PngComic = Get-XKCD -Num 2000 -Download -Path $TestDrive

        It "Get-XKCD -Download saves a non-jpg image using its actual extension" {
            $PngComic.img | Should Match '\.png$'
            Join-Path $TestDrive "2000.png" | Should Exist
        }
    }

    Context 'High Quality Download Tests' {

        # Comic 3290 is known to have a higher resolution (_2x) version available
        Get-XKCD -Num 3290 -Download -HighQuality -Path $TestDrive
        $StandardPath = Join-Path $TestDrive 'standard.png'
        Invoke-WebRequest 'https://imgs.xkcd.com/comics/trade.png' -OutFile $StandardPath

        It "Get-XKCD -HighQuality downloads the larger _2x image when available" {
            (Get-Item (Join-Path $TestDrive '3290.png')).Length | Should BeGreaterThan (Get-Item $StandardPath).Length
        }

        # Comic 1 does not have a higher resolution version available, so should fall back to standard quality
        It "Get-XKCD -HighQuality falls back to standard quality when no _2x image is available" {
            { Get-XKCD -Num 1 -Download -HighQuality -Path $TestDrive } | Should Not Throw
            Join-Path $TestDrive '1.jpg' | Should Exist
        }
    }

    Context 'Random Comic Tests' {
    
        $Random = Get-XKCD -Random

        It 'Get-XKCD -Random returns a PSCustomObject' {
            $Random | Should BeOfType 'System.Management.Automation.PSCustomObject'
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

        It "Get-XKCD -Newest 5 returns a string for img" {
            $Newest.img | Should BeOfType [string]
        }

        It "Get-XKCD -Newest 5 returns five results" {
            $Newest.Count | Should Be 5
        }
    }

    Context 'Show Tests' {

        It 'Get-XKCD -Show does not throw' {
            { Get-XKCD -Num 1 -Show } | Should Not Throw
        }

        It 'Get-XKCD -Show does not return the comic object' {
            Get-XKCD -Num 1 -Show | Should BeNullOrEmpty
        }
    }
}
