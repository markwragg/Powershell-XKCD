if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Unit Tests PS$PSVersion" {

    BeforeAll {
        $Root = "$PSScriptRoot/../.."
        $Module = 'xkcd'

        Get-Module $Module | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module "$Root/$Module" -Force

        $ModuleObj = Get-Module $Module
        $Comic = [pscustomobject]@{ num = 1786; title = 'Home Organization'; alt = 'Also, do not forget to check your blind spot.'; year = '2017'; month = '1'; day = '16' }
        $ImageBytes = [byte[]](1..10)

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

    Context 'Show-XKCDTuiFrame Content Tests' {

        BeforeAll {
            Mock -ModuleName $Module Show-XKCDTuiImage { }

            $Output = Get-XKCDCapturedOutput {
                & $ModuleObj {
                    Param($Comic, $ImageBytes)
                    Show-XKCDTuiFrame -Comic $Comic -ImageBytes $ImageBytes -Width 100
                } $Comic $ImageBytes
            }
        }

        It 'Includes the ASCII art banner' {
            $Output | Should -Match 'XKCD|#   #'
        }

        It 'Includes the comic number and title' {
            $Output | Should -Match '#1786: Home Organization'
        }

        It 'Includes the publish date and a hyperlink to the comic' {
            $Output | Should -Match '16 January 2017'
            $Output | Should -Match 'https://xkcd\.com/1786'
        }

        It 'Includes the wrapped alt text' {
            ($Output -split '\r?\n' -join ' ') -replace '\s+', ' ' | Should -Match ([regex]::Escape($Comic.alt))
        }

        It 'Includes the control bar, with every control' {
            $Output | Should -Match '\[G\]o to'
            $Output | Should -Match '\[F\]irst'
            $Output | Should -Match '\[P\]revious'
            $Output | Should -Match '\[R\]andom'
            $Output | Should -Match '\[N\]ext'
            $Output | Should -Match '\[L\]ast'
            $Output | Should -Match '\[Q\]uit'
        }

        It 'Shows the control bar both above and below the image' {
            ([regex]::Matches($Output, '\[P\]revious')).Count | Should -Be 2
        }

        It 'Renders the image via Show-XKCDTuiImage' {
            Get-XKCDCapturedOutput {
                & $ModuleObj {
                    Param($Comic, $ImageBytes)
                    Show-XKCDTuiFrame -Comic $Comic -ImageBytes $ImageBytes -Width 100
                } $Comic $ImageBytes
            } | Out-Null

            Should -Invoke -CommandName Show-XKCDTuiImage -ModuleName $Module -Times 1 -Exactly
        }

        It 'Passes a -CacheKey derived from the comic number and -HighQuality through to Show-XKCDTuiImage' {
            Get-XKCDCapturedOutput {
                & $ModuleObj {
                    Param($Comic, $ImageBytes)
                    Show-XKCDTuiFrame -Comic $Comic -ImageBytes $ImageBytes -Width 100 -HighQuality -Cache @{}
                } $Comic $ImageBytes
            } | Out-Null

            Should -Invoke -CommandName Show-XKCDTuiImage -ModuleName $Module -Times 1 -Exactly -ParameterFilter {
                $CacheKey -eq '1786|True' -and $Cache -is [hashtable]
            }
        }
    }

    Context 'Show-XKCDTuiFrame Without An Image Tests' {

        It 'Does not attempt to render an image when none is supplied' {
            Mock -ModuleName $Module Show-XKCDTuiImage { }

            Get-XKCDCapturedOutput {
                & $ModuleObj { Param($Comic) Show-XKCDTuiFrame -Comic $Comic -Width 100 } $Comic
            } | Out-Null

            Should -Invoke -CommandName Show-XKCDTuiImage -ModuleName $Module -Times 0 -Exactly
        }

        It 'Still displays the title and footer without an image' {
            Mock -ModuleName $Module Show-XKCDTuiImage { }

            $Output = Get-XKCDCapturedOutput {
                & $ModuleObj { Param($Comic) Show-XKCDTuiFrame -Comic $Comic -Width 100 } $Comic
            }

            $Output | Should -Match '#1786: Home Organization'
            $Output | Should -Match '\[Q\]uit'
        }
    }
}
