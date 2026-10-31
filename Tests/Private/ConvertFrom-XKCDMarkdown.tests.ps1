if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Unit Tests PS$PSVersion" {

    BeforeAll {
        $Root = "$PSScriptRoot/../.."
        $Module = 'xkcd'

        Get-Module $Module | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module "$Root/$Module" -Force

        $ModuleObj = Get-Module $Module

        function Convert-XKCDTestMarkdown {
            Param([string]$Text)

            & $ModuleObj { Param($Text) ConvertFrom-XKCDMarkdown -Text $Text } $Text
        }
    }

    Context 'Link Tests' {

        It 'Converts a Markdown-style link to just its display text, dropping the url' {
            Convert-XKCDTestMarkdown 'See [camera obscura](https://en.wikipedia.org/wiki/camera_obscura) for details.' | Should -Be 'See camera obscura for details.'
        }

        It 'Handles a url containing one level of parentheses without cutting the link short' {
            Convert-XKCDTestMarkdown 'A [Sharpie](https://en.wikipedia.org/wiki/Sharpie_(marker)) pen.' | Should -Be 'A Sharpie pen.'
        }

        It 'Removes a bare url entirely' {
            Convert-XKCDTestMarkdown 'See https://example.com for more.' | Should -Be 'See for more.'
        }

        It 'Drops now-empty parens left behind by a removed bare url' {
            Convert-XKCDTestMarkdown 'A reference (https://example.com) exists.' | Should -Be 'A reference exists.'
        }

        It 'Drops now-empty brackets left behind by a removed bare url' {
            Convert-XKCDTestMarkdown 'Contact us [https://example.com] today.' | Should -Be 'Contact us today.'
        }
    }

    Context 'Formatting Tests' {

        It 'Strips bold markup, keeping the text' {
            Convert-XKCDTestMarkdown 'This is **important**.' | Should -Be 'This is important.'
        }

        It 'Strips italic markup, keeping the text' {
            Convert-XKCDTestMarkdown 'This is *emphasised*.' | Should -Be 'This is emphasised.'
        }

        It 'Strips bold-italic markup, keeping the text' {
            Convert-XKCDTestMarkdown 'This is ***crucial***.' | Should -Be 'This is crucial.'
        }

        It 'Strips inline code backticks, keeping the text' {
            Convert-XKCDTestMarkdown 'Run `print("hi")` now.' | Should -Be 'Run print("hi") now.'
        }
    }

    Context 'Whitespace Tests' {

        It 'Collapses doubled interior whitespace left behind by a removed url' {
            Convert-XKCDTestMarkdown 'See https://example.com here.' | Should -Be 'See here.'
        }

        It 'Preserves a nested line''s leading indentation (reply nesting depth) while still collapsing its interior whitespace' {
            Convert-XKCDTestMarkdown "Top-level reply.`n`n  Nested reply with https://example.com here." | Should -Be "Top-level reply.`n`n  Nested reply with here."
        }

        It 'Collapses three or more blank lines down to one' {
            Convert-XKCDTestMarkdown "Para one.`n`n`n`nPara two." | Should -Be "Para one.`n`nPara two."
        }

        It 'Trims leading and trailing whitespace' {
            Convert-XKCDTestMarkdown "`n`nHello.  `n`n" | Should -Be 'Hello.'
        }
    }

    Context 'Pipeline Tests' {

        It 'Accepts input from the pipeline' {
            & $ModuleObj { '**bold**' | ConvertFrom-XKCDMarkdown } | Should -Be 'bold'
        }

        It 'Accepts an empty string without throwing' {
            Convert-XKCDTestMarkdown '' | Should -Be ''
        }
    }
}
