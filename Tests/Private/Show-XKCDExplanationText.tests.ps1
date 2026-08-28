if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major
$Root = "$PSScriptRoot/../.."
$Module = 'xkcd'

Get-Module $Module | Remove-Module -Force
Import-Module "$Root/$Module" -Force

$ModuleObj = Get-Module $Module

Function Get-XKCDCapturedOutput {
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

Describe "Unit Tests PS$PSVersion" {

    Context 'Show-XKCDExplanationText Tests' {

        $Explanation = [pscustomobject]@{
            Num         = 1000
            Title       = 'A Test Comic'
            Url         = 'https://www.explainxkcd.com/wiki/index.php/1000'
            Explanation = "First paragraph of the explanation.`n`nSecond paragraph of the explanation."
        }
        $ImageBytes = [byte[]](1..10)

        Mock -ModuleName $Module Show-XKCDImage { }

        $Output = Get-XKCDCapturedOutput {
            & $ModuleObj {
                Param($Explanation, $ImageBytes)
                Show-XKCDExplanationText -Explanation $Explanation -ImageBytes $ImageBytes
            } $Explanation $ImageBytes
        }

        It 'Writes the comic number and title' {
            $Output | Should Match '#1000: A Test Comic'
        }

        It 'Writes each paragraph of the explanation' {
            $Output | Should Match 'First paragraph of the explanation\.'
            $Output | Should Match 'Second paragraph of the explanation\.'
        }

        It 'Delegates image rendering to Show-XKCDImage' {
            Assert-MockCalled -ModuleName $Module Show-XKCDImage -Times 1 -Exactly
        }
    }

    Context 'Show-XKCDExplanationText Comic Meta Tests' {

        $Explanation = [pscustomobject]@{
            Num         = 1000
            Title       = 'A Test Comic'
            Url         = 'https://www.explainxkcd.com/wiki/index.php/1000'
            Explanation = 'The explanation text.'
        }
        $Comic = [pscustomobject]@{ num = 1000; year = '2017'; month = '1'; day = '16' }

        Mock -ModuleName $Module Show-XKCDImage { }

        $Output = Get-XKCDCapturedOutput {
            & $ModuleObj {
                Param($Explanation, $Comic)
                Show-XKCDExplanationText -Explanation $Explanation -Comic $Comic
            } $Explanation $Comic
        }

        It 'Writes the comic publish date and a hyperlink when a comic is supplied' {
            $Output | Should Match '16 January 2017'
            $Output | Should Match 'https://xkcd\.com/1000'
        }

        It 'Does not write a comic meta line when no comic is supplied' {
            $NoMetaOutput = Get-XKCDCapturedOutput {
                & $ModuleObj {
                    Param($Explanation)
                    Show-XKCDExplanationText -Explanation $Explanation
                } $Explanation
            }

            $NoMetaOutput | Should Not Match 'https://xkcd\.com/'
        }
    }

    Context 'Show-XKCDExplanationText Explanation Link Tests' {

        $Explanation = [pscustomobject]@{
            Num         = 1000
            Title       = 'A Test Comic'
            Url         = 'https://www.explainxkcd.com/wiki/index.php/1000'
            Explanation = 'The explanation text.'
        }

        Mock -ModuleName $Module Show-XKCDImage { }

        $Output = Get-XKCDCapturedOutput {
            & $ModuleObj {
                Param($Explanation)
                Show-XKCDExplanationText -Explanation $Explanation
            } $Explanation
        }

        It 'Writes a hyperlink to the explanation page under the title' {
            $Output | Should Match "$([char]27)\]8;;https://www\.explainxkcd\.com/wiki/index\.php/1000$([char]27)\\https://www\.explainxkcd\.com/wiki/index\.php/1000$([char]27)\]8;;$([char]27)\\"
        }
    }

    Context 'Show-XKCDExplanationText Bold and Italic Tests' {

        $Explanation = [pscustomobject]@{
            Num         = 1000
            Title       = 'A Test Comic'
            Url         = 'https://www.explainxkcd.com/wiki/index.php/1000'
            Explanation = 'This is **bold**, *italic*, and ***both*** text.'
        }

        Mock -ModuleName $Module Show-XKCDImage { }

        $Output = Get-XKCDCapturedOutput {
            & $ModuleObj {
                Param($Explanation)
                Show-XKCDExplanationText -Explanation $Explanation
            } $Explanation
        }

        It 'Renders bold text without the surrounding asterisks' {
            $Output | Should Match "$([char]27)\[1mbold$([char]27)\[0m"
        }

        It 'Renders italic text without the surrounding asterisks' {
            $Output | Should Match "$([char]27)\[3mitalic$([char]27)\[0m"
        }

        It 'Renders bold-italic text without the surrounding asterisks' {
            $Output | Should Match "$([char]27)\[1;3mboth$([char]27)\[0m"
        }

        It 'Leaves no stray asterisks in the output' {
            $Output | Should Not Match '\*'
        }
    }

    Context 'Show-XKCDExplanationText Italicised Link Tests' {

        # Regression test: a link sitting directly inside italic/bold markup (e.g. wikitext
        # "''[[what if? (blog)|what if?]]''") must not have its own hyperlink escape codes corrupted by the
        # italic/bold highlighting running first -- the "[" in "<esc>[3m" was previously misread as the start of
        # a second, bogus "[text](url)" link, producing garbled output like "3m[what if?" instead of a link.
        $Explanation = [pscustomobject]@{
            Num         = 1000
            Title       = 'A Test Comic'
            Url         = 'https://www.explainxkcd.com/wiki/index.php/1000'
            Explanation = "In Randall's *[what if?](https://www.explainxkcd.com/wiki/index.php/what_if%3F_(blog))* blog."
        }

        Mock -ModuleName $Module Show-XKCDImage { }

        $Output = Get-XKCDCapturedOutput {
            & $ModuleObj {
                Param($Explanation)
                Show-XKCDExplanationText -Explanation $Explanation
            } $Explanation
        }

        It 'Renders the link with its display text intact, wrapped in italics' {
            $Output | Should Match "$([char]27)\[3m$([char]27)\[4;94m$([char]27)\]8;;https://www\.explainxkcd\.com/wiki/index\.php/what_if%3F_\(blog\)$([char]27)\\what if\?$([char]27)\]8;;$([char]27)\\$([char]27)\[0m$([char]27)\[0m"
        }

        It 'Does not leak escape code fragments as visible text' {
            $Output | Should Not Match '3m\[what if'
        }
    }

    Context 'Show-XKCDExplanationText Code and Link Tests' {

        $Explanation = [pscustomobject]@{
            Num         = 1000
            Title       = 'A Test Comic'
            Url         = 'https://www.explainxkcd.com/wiki/index.php/1000'
            Explanation = 'Run `print("hi")` and see https://example.com/docs for details.'
        }

        Mock -ModuleName $Module Show-XKCDImage { }

        $Output = Get-XKCDCapturedOutput {
            & $ModuleObj {
                Param($Explanation)
                Show-XKCDExplanationText -Explanation $Explanation
            } $Explanation
        }

        It 'Highlights backtick-wrapped code without the surrounding backticks' {
            $Output | Should Match "$([char]27)\[92mprint\(`"hi`"\)$([char]27)\[0m"
            $Output | Should Not Match '`'
        }

        It 'Turns a plain url into a clickable hyperlink' {
            $Output | Should Match "$([char]27)\]8;;https://example\.com/docs$([char]27)\\https://example\.com/docs$([char]27)\]8;;$([char]27)\\"
        }
    }

    Context 'Show-XKCDExplanationText Markdown Link Tests' {

        $Explanation = [pscustomobject]@{
            Num         = 1000
            Title       = 'A Test Comic'
            Url         = 'https://www.explainxkcd.com/wiki/index.php/1000'
            Explanation = 'See the [xkcd wiki](https://www.explainxkcd.com/) for more.'
        }

        Mock -ModuleName $Module Show-XKCDImage { }

        $Output = Get-XKCDCapturedOutput {
            & $ModuleObj {
                Param($Explanation)
                Show-XKCDExplanationText -Explanation $Explanation
            } $Explanation
        }

        It 'Makes the display words themselves the clickable hyperlink' {
            $Output | Should Match "$([char]27)\]8;;https://www\.explainxkcd\.com/$([char]27)\\xkcd wiki$([char]27)\]8;;$([char]27)\\"
        }

        It 'Does not print the raw url as visible text' {
            $Output | Should Not Match '\]\(https://www\.explainxkcd\.com/\)'
        }
    }

    Context 'Show-XKCDExplanationText Parenthesised Url Tests' {

        # Regression test: a url containing its own parentheses (e.g. a Wikipedia disambiguation page like
        # "Installer_(OS_X)#Installer_package") must be matched in full -- previously the url capture stopped at
        # the url's own first closing paren, truncating the hyperlink and leaking the rest as plain text.
        $Explanation = [pscustomobject]@{
            Num         = 1000
            Title       = 'A Test Comic'
            Url         = 'https://www.explainxkcd.com/wiki/index.php/1000'
            Explanation = 'Download a [.pkg](https://en.wikipedia.org/wiki/Installer_(OS_X)#Installer_package) file.'
        }

        Mock -ModuleName $Module Show-XKCDImage { }

        $Output = Get-XKCDCapturedOutput {
            & $ModuleObj {
                Param($Explanation)
                Show-XKCDExplanationText -Explanation $Explanation
            } $Explanation
        }

        It 'Includes the full url, parentheses and all, as the hyperlink target' {
            $Output | Should Match "$([char]27)\]8;;https://en\.wikipedia\.org/wiki/Installer_\(OS_X\)#Installer_package$([char]27)\\\.pkg$([char]27)\]8;;$([char]27)\\"
        }

        It 'Does not leak the trailing part of the url as plain text' {
            $Output | Should Not Match '#Installer_package\)'
        }
    }

    Context 'Show-XKCDExplanationText Visible-Length Wrapping Tests' {

        # Regression test: word-wrapping must be based on visible width, not raw string length -- otherwise a
        # short hyperlinked word (which carries dozens of invisible ANSI/OSC8 characters) looks "too long" to
        # the wrapper and forces a line break immediately before it, even though it renders as just a few
        # characters and easily fits on the current line.
        $Explanation = [pscustomobject]@{
            Num         = 1000
            Title       = 'A Test Comic'
            Url         = 'https://www.explainxkcd.com/wiki/index.php/1000'
            Explanation = 'You just download a [.exe](https://en.wikipedia.org/wiki/.exe) or a [.pkg](https://en.wikipedia.org/wiki/Installer_(OS_X)) file.'
        }

        Mock -ModuleName $Module Show-XKCDImage { }

        $Output = Get-XKCDCapturedOutput {
            & $ModuleObj {
                Param($Explanation)
                Show-XKCDExplanationText -Explanation $Explanation
            } $Explanation
        }

        It 'Does not break the line immediately before a short hyperlinked word' {
            ($Output -split "`r?`n") | Where-Object { $_ -eq 'You just download a' } | Should BeNullOrEmpty
        }
    }

    Context 'Show-XKCDExplanationText Adjacent Code and Url Tests' {

        # Regression test: a url ending right at a closing backtick (e.g. `curl http://x.com/`) must not have
        # the backtick swallowed into the url match, which previously left the code span unclosed and corrupted
        # the pairing of every code span later in the same paragraph.
        $Explanation = [pscustomobject]@{
            Num         = 1000
            Title       = 'A Test Comic'
            Url         = 'https://www.explainxkcd.com/wiki/index.php/1000'
            Explanation = 'Run `curl http://example.com/` then `echo done`.'
        }

        Mock -ModuleName $Module Show-XKCDImage { }

        $Output = Get-XKCDCapturedOutput {
            & $ModuleObj {
                Param($Explanation)
                Show-XKCDExplanationText -Explanation $Explanation
            } $Explanation
        }

        It 'Correctly closes the code span containing the url' {
            $Output | Should Match "$([char]27)\]8;;http://example\.com/$([char]27)\\http://example\.com/$([char]27)\]8;;$([char]27)\\$([char]27)\[0m"
        }

        It 'Correctly highlights the later, unrelated code span' {
            $Output | Should Match "$([char]27)\[92mecho done$([char]27)\[0m"
        }

        It 'Leaves no stray backticks in the output' {
            $Output | Should Not Match '`'
        }
    }

    Context 'Show-XKCDExplanationText Multi-Section Tests' {

        $Explanation = [pscustomobject]@{
            Num         = 1000
            Title       = 'A Test Comic'
            Url         = 'https://www.explainxkcd.com/wiki/index.php/1000'
            Explanation = 'The explanation text.'
            Transcript  = 'The transcript text.'
            Discussion  = ''
        }

        Mock -ModuleName $Module Show-XKCDImage { }

        $Output = Get-XKCDCapturedOutput {
            & $ModuleObj {
                Param($Explanation)
                Show-XKCDExplanationText -Explanation $Explanation
            } $Explanation
        }

        It 'Writes a heading and the text for each populated section' {
            $Output | Should Match 'Explanation[\s\S]*The explanation text\.'
            $Output | Should Match 'Transcript[\s\S]*The transcript text\.'
        }

        It 'Writes a placeholder message for a requested but empty section' {
            $Output | Should Match 'Discussion[\s\S]*No discussion is available yet\.'
        }
    }

    Context 'Show-XKCDExplanationText Single-Section Tests' {

        $Explanation = [pscustomobject]@{
            Num         = 1000
            Title       = 'A Test Comic'
            Url         = 'https://www.explainxkcd.com/wiki/index.php/1000'
            Explanation = 'The explanation text.'
        }

        Mock -ModuleName $Module Show-XKCDImage { }

        It 'Does not write a section heading when only the explanation is present' {
            $Output = Get-XKCDCapturedOutput {
                & $ModuleObj {
                    Param($Explanation)
                    Show-XKCDExplanationText -Explanation $Explanation
                } $Explanation
            }

            ($Output -split "`r?`n") -notcontains "$([char]27)[1mExplanation$([char]27)[0m" | Should Be $true
        }
    }

    Context 'Show-XKCDExplanationText Without Image Tests' {

        $Explanation = [pscustomobject]@{
            Num         = 1
            Title       = 'Barrel - Part 1'
            Url         = 'https://www.explainxkcd.com/wiki/index.php/1'
            Explanation = 'Some explanation text.'
        }

        Mock -ModuleName $Module Show-XKCDImage { }

        It 'Does not attempt to render an image when none is supplied' {
            Get-XKCDCapturedOutput {
                & $ModuleObj {
                    Param($Explanation)
                    Show-XKCDExplanationText -Explanation $Explanation
                } $Explanation
            } | Out-Null

            Assert-MockCalled -ModuleName $Module Show-XKCDImage -Times 0 -Exactly
        }
    }

    Context 'Show-XKCDExplanationText Error Handling Tests' {

        $Explanation = [pscustomobject]@{
            Num         = 1
            Title       = 'Barrel - Part 1'
            Url         = 'https://www.explainxkcd.com/wiki/index.php/1'
            Explanation = 'Some explanation text.'
        }
        $ImageBytes = [byte[]](1..10)

        Mock -ModuleName $Module Show-XKCDImage { throw 'Simulated rendering failure' }

        It 'Warns instead of throwing when rendering fails' {
            {
                Get-XKCDCapturedOutput {
                    & $ModuleObj {
                        Param($Explanation, $ImageBytes)
                        Show-XKCDExplanationText -Explanation $Explanation -ImageBytes $ImageBytes -WarningAction SilentlyContinue
                    } $Explanation $ImageBytes
                }
            } | Should Not Throw
        }
    }
}
