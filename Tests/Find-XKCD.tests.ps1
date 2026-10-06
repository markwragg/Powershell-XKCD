if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Unit Tests PS$PSVersion" {

    BeforeAll {
        $Root = "$PSScriptRoot/../"
        $Module = 'xkcd'

        Get-Module $Module | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module "$Root/$Module" -Force
    }

    Context 'Parameter Input Tests' {

        It 'Find-XKCD -Query requires an input' {
            { Find-XKCD -Query } | Should -Throw
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
            $Default = Find-XKCD -Query 'Spiders'
        }

        It 'Find-XKCD returns a PSCustomObject' {
            $Default | Should -BeOfType 'System.Management.Automation.PSCustomObject'
        }

        It "Find-XKCD returns 4 comics" {
            $Default.count | Should -Be 4
        }

        It "Find-XKCD tags each result with a 'query' NoteProperty matching the search term" {
            $Default | ForEach-Object { $_.query | Should -Be 'Spiders' }
        }

        It 'Find-XKCD returns a html_img property containing just an img tag for the comic' {
            $Comic = $Default | Select-Object -First 1
            $Comic.html_img | Should -Not -Match '<a '
            $Comic.html_img | Should -Match '<img '
        }

        It 'Find-XKCD returns a html property wrapping the same img tag in a link to the comic' {
            $Comic = $Default | Select-Object -First 1
            $Comic.html | Should -Be "<a href=`"https://xkcd.com/$($Comic.num)`">$($Comic.html_img)</a>"
        }
    }

    Context 'Pipeline Input Tests' {

        BeforeAll {
            $Piped = 'Spiders' | Find-XKCD
            $Multiple = 'Spiders', 'Robots' | Find-XKCD
        }

        It 'Find-XKCD accepts the query via the pipeline' {
            $Piped.count | Should -Be 4
        }

        It 'Find-XKCD accepts multiple queries via the pipeline' {
            @($Multiple | Where-Object query -eq 'Spiders').Count | Should -Be 4
            @($Multiple | Where-Object query -eq 'Robots').Count | Should -Be 1
        }
    }

    Context 'FullSearch Tests' {

        BeforeAll {
            $TitleOnly = Find-XKCD -Query 'guitar'
            $FullSearch = Find-XKCD -Query 'guitar' -FullSearch
        }

        It 'Find-XKCD without -FullSearch only matches against the title' {
            @($TitleOnly).Count | Should -Be 1
        }

        It 'Find-XKCD -FullSearch matches against the whole comic object, not just the title' {
            @($FullSearch).Count | Should -Be 10
        }

        It "Find-XKCD -FullSearch still tags each result with a 'query' NoteProperty" {
            $FullSearch | ForEach-Object { $_.query | Should -Be 'guitar' }
        }
    }

    Context 'Query Array Tests' {

        It 'Find-XKCD -Query accepts an array and OR-combines the terms in a single call' {
            $Result = Find-XKCD -Query 'romance', 'math'
            @($Result).Count | Should -Be 9
        }

        It 'Find-XKCD -Query array tags each result with the specific term it matched, not the full list' {
            $Result = Find-XKCD -Query 'romance', 'math'

            ($Result | Where-Object num -eq 919).query | Should -Be 'romance'
            ($Result | Where-Object num -eq 410).query | Should -Be 'math'
        }

        It 'Find-XKCD -Query array tags a comic matching more than one term with all of them' {
            $Result = Find-XKCD -Query 'Time', 'Machine'

            ($Result | Where-Object num -eq 716).query | Should -Be 'Time, Machine'
        }

        It 'Find-XKCD does not throw when the same comic matches more than one piped query' {
            # Comic 716 ("Time Machine") matches both terms
            { 'Time', 'Machine' | Find-XKCD -ErrorAction Stop } | Should -Not -Throw
        }
    }

    Context 'Or Parameter Tests' {

        It 'Find-XKCD -Or matches comics that contain either the -Query or -Or term' {
            $Result = Find-XKCD -Query 'Spiders' -Or 'romance'
            @($Result).Count | Should -Be 5
        }
    }

    Context 'And Parameter Tests' {

        It 'Find-XKCD -And only matches comics that contain every term' {
            $Result = Find-XKCD -Query 'Time' -And 'Machine'
            @($Result).Count | Should -Be 3
            $Result | ForEach-Object {
                $_.title | Should -BeLike '*Time*'
                $_.title | Should -BeLike '*Machine*'
            }
        }

        It "Find-XKCD -And includes its term(s) in the 'query' tag, alongside the matched -Query/-Or term(s)" {
            $Result = Find-XKCD -Query 'Time' -And 'Machine'

            $Result | ForEach-Object { $_.query | Should -Be 'Time, Machine' }
        }
    }

    Context 'Not Parameter Tests' {

        It 'Find-XKCD -Not excludes comics that contain the given term' {
            $Result = Find-XKCD -Query 'Time' -Not 'Machine'

            $Result | ForEach-Object { $_.title | Should -Not -BeLike '*Machine*' }
        }

        It 'Find-XKCD -Not and -And on the same term together account for every -Query match exactly once' {
            $TimeOnly = Find-XKCD -Query 'Time'
            $TimeNotMachine = Find-XKCD -Query 'Time' -Not 'Machine'
            $TimeAndMachine = Find-XKCD -Query 'Time' -And 'Machine'

            (@($TimeNotMachine).Count + @($TimeAndMachine).Count) | Should -Be @($TimeOnly).Count
        }

        It 'Find-XKCD -Not excludes a comic matching ANY of several terms' {
            $Result = Find-XKCD -Query 'Time' -Not 'Machine', 'Capsule'

            $Result | ForEach-Object {
                $_.title | Should -Not -BeLike '*Machine*'
                $_.title | Should -Not -BeLike '*Capsule*'
            }
        }

        It "Find-XKCD -Not still tags each result with the -Query/-Or term it matched" {
            $Result = Find-XKCD -Query 'Time' -Not 'Machine'

            $Result | Select-Object -First 1 -ExpandProperty query | Should -Be 'Time'
        }

        It 'Find-XKCD -And and -Not can be combined' {
            # Comic 3251 ("Time Machine Conversation") matches -And but is excluded by -Not
            $Result = Find-XKCD -Query 'Time' -And 'Machine' -Not 'Conversation'

            @($Result | Where-Object num -eq 3251).Count | Should -Be 0
            $Result | ForEach-Object {
                $_.title | Should -BeLike '*Time*'
                $_.title | Should -BeLike '*Machine*'
                $_.title | Should -Not -BeLike '*Conversation*'
            }
        }
    }

    Context 'Year/Month/Day Parameter Tests' {

        It 'Find-XKCD -Year restricts matches to that year' {
            $Result = Find-XKCD -Query 'Spider' -Year 2016
            @($Result).Count | Should -Be 1
            $Result.num | Should -Be 1747
        }

        It 'Find-XKCD -Year excludes matches from other years' {
            $Result = Find-XKCD -Query 'Spider' -Year 2099
            $Result | Should -BeNullOrEmpty
        }

        It 'Find-XKCD -Month and -Day further restrict matches, alongside -Year' {
            $Result = Find-XKCD -Query 'Spider' -Year 2016 -Month 10 -Day 17
            $Result.num | Should -Be 1747
        }

        It 'Find-XKCD -Month rejects a value outside 1-12' {
            { Find-XKCD -Query 'Spider' -Month 13 } | Should -Throw
        }

        It 'Find-XKCD -Day rejects a value outside 1-31' {
            { Find-XKCD -Query 'Spider' -Day 32 } | Should -Throw
        }
    }

    Context 'SkipCacheRefresh Parameter Tests' {

        It 'Find-XKCD calls Update-XKCDCache by default' {
            Mock Update-XKCDCache {} -ModuleName $Module

            Find-XKCD -Query 'Spiders' | Out-Null

            Should -Invoke Update-XKCDCache -ModuleName $Module -Times 1 -Exactly
        }

        It 'Find-XKCD -SkipCacheRefresh does not call Update-XKCDCache' {
            Mock Update-XKCDCache {} -ModuleName $Module

            Find-XKCD -Query 'Spiders' -SkipCacheRefresh | Out-Null

            Should -Invoke Update-XKCDCache -ModuleName $Module -Times 0 -Exactly
        }

        It 'Find-XKCD -SkipCacheRefresh still returns results from the existing cache' {
            $Result = Find-XKCD -Query 'Spiders' -SkipCacheRefresh

            @($Result).Count | Should -Be 4
        }
    }

    Context 'Offline Parameter Tests' {

        It 'Find-XKCD -Offline does not call Update-XKCDCache' {
            Mock Update-XKCDCache {} -ModuleName $Module

            Find-XKCD -Query 'Spiders' -Offline | Out-Null

            Should -Invoke Update-XKCDCache -ModuleName $Module -Times 0 -Exactly
        }

        It 'Find-XKCD -Offline still returns results from the existing cache' {
            $Result = Find-XKCD -Query 'Spiders' -Offline

            @($Result).Count | Should -Be 4
        }
    }

    Context 'Raw Parameter Tests' {

        It 'Find-XKCD -Raw does not add the date, html_img or html properties' {
            $Comic = Find-XKCD -Query 'Spiders' -Raw | Select-Object -First 1

            $Comic.PSObject.Properties.Name | Should -Not -Contain 'date'
            $Comic.PSObject.Properties.Name | Should -Not -Contain 'html_img'
            $Comic.PSObject.Properties.Name | Should -Not -Contain 'html'
        }

        It 'Find-XKCD -Raw does not tag the object with the XKCD.Comic/XKCD.Comic.Search type names' {
            $Comic = Find-XKCD -Query 'Spiders' -Raw | Select-Object -First 1

            $Comic.PSObject.TypeNames | Should -Not -Contain 'XKCD.Comic'
            $Comic.PSObject.TypeNames | Should -Not -Contain 'XKCD.Comic.Search'
        }

        It "Find-XKCD -Raw still tags each result with a 'query' NoteProperty" {
            $Comic = Find-XKCD -Query 'Spiders' -Raw | Select-Object -First 1

            $Comic.query | Should -Be 'Spiders'
        }

        It 'Find-XKCD -Raw still returns the comic''s own API properties' {
            $Comic = Find-XKCD -Query 'Spiders' -Raw | Select-Object -First 1

            $Comic.num | Should -Not -BeNullOrEmpty
            $Comic.title | Should -Not -BeNullOrEmpty
        }

        It 'Find-XKCD -Raw works alongside -Or/-And/-Not' {
            $Result = Find-XKCD -Query 'Time' -And 'Machine' -Not 'Conversation' -Raw

            @($Result).Count | Should -Be 2
            $Result | ForEach-Object { $_.PSObject.Properties.Name | Should -Not -Contain 'date' }
        }

        It 'Find-XKCD without -Raw still adds the date, html_img and html properties' {
            $Comic = Find-XKCD -Query 'Spiders' | Select-Object -First 1

            $Comic.PSObject.Properties.Name | Should -Contain 'date'
            $Comic.PSObject.Properties.Name | Should -Contain 'html_img'
            $Comic.PSObject.Properties.Name | Should -Contain 'html'
        }
    }
}
