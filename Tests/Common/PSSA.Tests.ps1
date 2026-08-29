# This runs all PSScriptAnalyzer rules as Pester tests to enable visibility when publishing test results
# Vars
$ScriptAnalyzerSettingsPath = Join-Path -Path $env:BHProjectPath -ChildPath 'PSScriptAnalyzerSettings.psd1'
$analysis = Invoke-ScriptAnalyzer -Path $env:BHModulePath -Recurse -Settings $ScriptAnalyzerSettingsPath

# Bundle each rule together with its own failures (pre-computed here, at Discovery time) so the -ForEach
# below has everything it needs via $_ alone -- calling Invoke-ScriptAnalyzer itself from inside a BeforeAll
# trips a Pester bug (https://github.com/pester/Pester/issues/2669), so it can't be computed there instead.
$scriptAnalyzerRules = Get-ScriptAnalyzerRule | ForEach-Object {
    [pscustomobject]@{
        Rule     = $_.RuleName
        Failures = @($analysis | Where-Object RuleName -EQ $_.RuleName)
    }
}

Describe 'Testing against PSSA rules' {
    Context 'PSSA Standard Rules' {

        It 'Should pass <_.Rule>' -ForEach $scriptAnalyzerRules {
            $_.Failures.Count | Should -Be 0
        }
    }
}
