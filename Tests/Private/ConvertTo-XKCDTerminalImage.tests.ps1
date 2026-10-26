if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Unit Tests PS$PSVersion" {

    BeforeAll {
        $Root = "$PSScriptRoot/../.."
        $Module = 'xkcd'

        Get-Module $Module | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module "$Root/$Module" -Force

        $ModuleObj = Get-Module $Module
    }

    Context 'ConvertTo-XKCDTerminalImage Kitty Tests' {

        BeforeAll {
            $esc = [char]27
            $SmallImageBytes = [byte[]](1..10)
            $LargeImageBytes = [byte[]](1..4000 | ForEach-Object { $_ % 256 })
        }

        It 'Returns a single Kitty graphics escape sequence for small images' {
            $Result = & $ModuleObj { Param($ImageBytes) ConvertTo-XKCDTerminalImage -ImageBytes $ImageBytes -Protocol 'Kitty' } $SmallImageBytes

            $Result | Should -Match ([regex]::Escape("$esc") + '_Ga=T,f=100,m=0;')
            $Result | Should -Match ([regex]::Escape("$esc\"))
        }

        It 'Chunks large images across multiple Kitty escape sequences' {
            $Result = & $ModuleObj { Param($ImageBytes) ConvertTo-XKCDTerminalImage -ImageBytes $ImageBytes -Protocol 'Kitty' } $LargeImageBytes

            $Result | Should -Match ([regex]::Escape("$esc") + '_Ga=T,f=100,m=1;')
            $Result | Should -Match ([regex]::Escape("$esc") + '_Gm=0;')
        }

        It 'Does not request a specific column width by default' {
            $Result = & $ModuleObj { Param($ImageBytes) ConvertTo-XKCDTerminalImage -ImageBytes $ImageBytes -Protocol 'Kitty' } $SmallImageBytes

            $Result | Should -Not -Match ',c=\d+'
        }

        It 'Requests the specified column width when -Columns is specified' {
            $Result = & $ModuleObj { Param($ImageBytes) ConvertTo-XKCDTerminalImage -ImageBytes $ImageBytes -Protocol 'Kitty' -Columns 42 } $SmallImageBytes

            $Result | Should -Match 'a=T,f=100,m=0,c=42;'
        }

        It 'Only includes -Columns on the first chunk of a multi-chunk image' {
            $Result = & $ModuleObj { Param($ImageBytes) ConvertTo-XKCDTerminalImage -ImageBytes $ImageBytes -Protocol 'Kitty' -Columns 42 } $LargeImageBytes

            ([regex]::Matches($Result, 'c=42')).Count | Should -Be 1
        }
    }

    Context 'ConvertTo-XKCDTerminalImage iTerm2 Tests' {

        BeforeAll {
            $esc = [char]27
            $bel = [char]7
            $ImageBytes = [byte[]](1..10)

            $Result = & $ModuleObj { Param($ImageBytes) ConvertTo-XKCDTerminalImage -ImageBytes $ImageBytes -Protocol 'iTerm2' } $ImageBytes
        }

        It 'Returns an iTerm2 inline image escape sequence' {
            $Result | Should -Match ([regex]::Escape("$esc") + '\]1337;File=inline=1;size=10:')
            $Result | Should -Match ([regex]::Escape("$bel"))
        }

        It 'Does not request a specific cell width by default' {
            $Result | Should -Not -Match 'width=\d+'
        }

        It 'Requests the specified cell width when -Columns is specified' {
            $ColumnResult = & $ModuleObj { Param($ImageBytes) ConvertTo-XKCDTerminalImage -ImageBytes $ImageBytes -Protocol 'iTerm2' -Columns 42 } $ImageBytes

            $ColumnResult | Should -Match 'size=10;width=42:'
        }
    }

    Context 'ConvertTo-XKCDTerminalImage Sixel Tests' {

        BeforeAll {
            $ImageBytes = [byte[]](1..10)

            Mock -ModuleName $Module ConvertTo-XKCDSixel { 'FAKE-SIXEL-DATA' }
        }

        It 'Delegates to ConvertTo-XKCDSixel' {
            $Result = & $ModuleObj { Param($ImageBytes) ConvertTo-XKCDTerminalImage -ImageBytes $ImageBytes -Protocol 'Sixel' } $ImageBytes

            $Result | Should -Be 'FAKE-SIXEL-DATA'
        }

        It 'Does not override the default -MaxWidth without -HighQuality' {
            & $ModuleObj { Param($ImageBytes) ConvertTo-XKCDTerminalImage -ImageBytes $ImageBytes -Protocol 'Sixel' } $ImageBytes

            Should -Invoke -CommandName ConvertTo-XKCDSixel -ModuleName $Module -Times 1 -Exactly -ParameterFilter {
                -not $PSBoundParameters.ContainsKey('MaxWidth')
            }
        }

        It 'Raises -MaxWidth to 925 when -HighQuality is specified' {
            & $ModuleObj { Param($ImageBytes) ConvertTo-XKCDTerminalImage -ImageBytes $ImageBytes -Protocol 'Sixel' -HighQuality } $ImageBytes

            Should -Invoke -CommandName ConvertTo-XKCDSixel -ModuleName $Module -Times 1 -Exactly -ParameterFilter {
                $MaxWidth -eq 925
            }
        }
    }

    Context 'ConvertTo-XKCDTerminalImage Detected Protocol Tests' {

        BeforeAll {
            $esc = [char]27
            $ImageBytes = [byte[]](1..10)

            Mock -ModuleName $Module Get-XKCDTerminalGraphicsProtocol { 'Kitty' }
        }

        It 'Defaults to the detected terminal graphics protocol when none is specified' {
            $Result = & $ModuleObj { Param($ImageBytes) ConvertTo-XKCDTerminalImage -ImageBytes $ImageBytes } $ImageBytes

            $Result | Should -Match ([regex]::Escape("$esc") + '_Ga=T,f=100,m=0;')
        }
    }

    Context 'ConvertTo-XKCDTerminalImage Unsupported Protocol Tests' {

        BeforeAll {
            $ImageBytes = [byte[]](1..10)

            Mock -ModuleName $Module Get-XKCDTerminalGraphicsProtocol { $null }
        }

        It 'Throws when no graphics protocol is detected or specified' {
            {
                & $ModuleObj { Param($ImageBytes) ConvertTo-XKCDTerminalImage -ImageBytes $ImageBytes } $ImageBytes
            } | Should -Throw
        }
    }
}
