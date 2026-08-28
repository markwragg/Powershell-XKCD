if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major
$Root = "$PSScriptRoot/../.."
$Module = 'xkcd'

Get-Module $Module | Remove-Module -Force
Import-Module "$Root/$Module" -Force

$ModuleObj = Get-Module $Module

Function Convert-XKCDTestWikiText {
    Param([string]$WikiText)

    & $ModuleObj { Param($WikiText) ConvertTo-XKCDPlainText -WikiText $WikiText } $WikiText
}

Describe "Unit Tests PS$PSVersion" {

    Context 'Heading and Comment Tests' {

        It 'Removes the section heading line' {
            Convert-XKCDTestWikiText "==Explanation==`nSome text." | Should Be 'Some text.'
        }

        It 'Removes HTML comments' {
            Convert-XKCDTestWikiText 'Before <!-- a hidden note --> after.' | Should Be 'Before  after.'
        }
    }

    Context 'Link Tests' {

        It 'Converts a simple internal link to a Markdown-style link using its page name for both text and url' {
            Convert-XKCDTestWikiText 'See [[1889: xkcd Phone 6]] for details.' | Should Be 'See [1889: xkcd Phone 6](https://www.explainxkcd.com/wiki/index.php/1889%3A_xkcd_Phone_6) for details.'
        }

        It 'Converts a piped internal link to a Markdown-style link, using the display text and dropping the leading colon from the url' {
            Convert-XKCDTestWikiText 'The [[:Category:xkcd Phones|xkcd Phone series]] continues.' | Should Be 'The [xkcd Phone series](https://www.explainxkcd.com/wiki/index.php/Category%3Axkcd_Phones) continues.'
        }

        It 'Leaves a same-page anchor link as plain display text' {
            Convert-XKCDTestWikiText 'See [[#Trivia]] below.' | Should Be 'See #Trivia below.'
        }

        It 'Percent-encodes url-unsafe characters in an internal link target, e.g. "?"' {
            Convert-XKCDTestWikiText "In Randall's ''[[what if? (blog)|what if?]]'' blog" | Should Be 'In Randall''s *[what if?](https://www.explainxkcd.com/wiki/index.php/what_if%3F_(blog))* blog'
        }

        It 'Keeps a page/anchor split correctly encoded and un-encoded respectively' {
            Convert-XKCDTestWikiText '[[Some Page?#Some Anchor|text]]' | Should Be '[text](https://www.explainxkcd.com/wiki/index.php/Some_Page%3F#Some Anchor)'
        }

        It 'Converts an external link with display text to Markdown-style "[text](url)"' {
            Convert-XKCDTestWikiText 'Roughly [https://example.com/pixels 440 pixels per inch].' | Should Be 'Roughly [440 pixels per inch](https://example.com/pixels).'
        }

        It 'Converts a bare external link to just its url' {
            Convert-XKCDTestWikiText 'See [https://example.com] for more.' | Should Be 'See https://example.com for more.'
        }
    }

    Context 'Code Formatting Tests' {

        It 'Wraps inline <code> content in backticks' {
            Convert-XKCDTestWikiText 'Run <code>print("hi")</code> now.' | Should Be 'Run `print("hi")` now.'
        }

        It 'Wraps <pre> content in backticks' {
            Convert-XKCDTestWikiText 'See <pre>import antigravity</pre> here.' | Should Be 'See `import antigravity` here.'
        }

        It 'Wraps a space-indented preformatted line in backticks' {
            $Backtick = [char]96
            $Expected = "Run this:`n`n${Backtick}git clone https://example.com/repo${Backtick}`n`nThen build it."
            Convert-XKCDTestWikiText "Run this:`n`n git clone https://example.com/repo`n`nThen build it." | Should Be $Expected
        }
    }

    Context 'Template Tests' {

        It 'Converts a two-part {{w}} template to a Markdown-style Wikipedia link' {
            Convert-XKCDTestWikiText 'A {{w|Retina Display}} is sharp.' | Should Be 'A [Retina Display](https://en.wikipedia.org/wiki/Retina_Display) is sharp.'
        }

        It 'Converts a three-part {{w}} template to a Markdown-style Wikipedia link, using the page (with anchor) for the url and the last part for the display text' {
            Convert-XKCDTestWikiText 'From {{w|Grind#Typical_grinds|hollow grind}} edges.' | Should Be 'From [hollow grind](https://en.wikipedia.org/wiki/Grind#Typical_grinds) edges.'
        }

        It 'Converts a {{what if}} template with a title to a Markdown-style link to the what-if article' {
            Convert-XKCDTestWikiText 'See {{what if|128|Zippo Phone}} for more.' | Should Be 'See [Zippo Phone](https://what-if.xkcd.com/128/) for more.'
        }

        It 'Converts a {{what if}} template without a title to a Markdown-style link using a default display' {
            Convert-XKCDTestWikiText 'See {{what if|128}} for more.' | Should Be 'See [what if #128](https://what-if.xkcd.com/128/) for more.'
        }

        It 'Percent-encodes url-unsafe characters in a {{w}} template target, e.g. ":"' {
            Convert-XKCDTestWikiText 'See {{w|Wikipedia:Citation needed}}.' | Should Be 'See [Wikipedia:Citation needed](https://en.wikipedia.org/wiki/Wikipedia%3ACitation_needed).'
        }

        It 'Converts a single-part template to a bracketed lowercase note' {
            Convert-XKCDTestWikiText 'Unlikely to happen{{Citation needed}}.' | Should Be 'Unlikely to happen[citation needed].'
        }
    }

    Context 'Formatting Tests' {

        It 'Converts bold markup to Markdown-style "**text**"' {
            Convert-XKCDTestWikiText "This is '''important'''." | Should Be 'This is **important**.'
        }

        It 'Converts italic markup to Markdown-style "*text*"' {
            Convert-XKCDTestWikiText "This is ''emphasised''." | Should Be 'This is *emphasised*.'
        }

        It 'Converts bold-italic markup to Markdown-style "***text***"' {
            Convert-XKCDTestWikiText "This is '''''crucial'''''." | Should Be 'This is ***crucial***.'
        }

        It 'Converts a definition list term and description' {
            $Result = Convert-XKCDTestWikiText "; Dockless`n`n: Wireless charging."
            $Result | Should Match 'Dockless:'
            $Result | Should Match '  Wireless charging\.'
        }
    }

    Context 'Whitespace Tests' {

        It 'Collapses three or more blank lines down to one' {
            Convert-XKCDTestWikiText "Para one.`n`n`n`nPara two." | Should Be "Para one.`n`nPara two."
        }

        It 'Trims leading and trailing whitespace' {
            Convert-XKCDTestWikiText "`n`nHello.  `n`n" | Should Be 'Hello.'
        }
    }
}
