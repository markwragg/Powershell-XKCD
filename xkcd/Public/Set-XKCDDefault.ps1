Function Set-XKCDDefault {
    <#
    .SYNOPSIS
        Sets default preferences used automatically by other cmdlets in this module, such as whether to use
        high quality images by default.

    .DESCRIPTION
        The Set-XKCDDefault cmdlet saves default preferences that are then used automatically by other cmdlets
        in this module, so you don't need to specify the same parameters every time. Explicitly specifying a
        parameter on a cmdlet (e.g. Get-XKCD -HighQuality:$false) always overrides the saved default.

        Only the preferences you specify are changed -- any others already saved are left as they are. Use
        -Reset to remove all saved preferences and restore the module's built-in behavior.

        Supported preferences:

        -HighQuality  Default for -HighQuality on Get-XKCD, Show-XKCD, Get-XKCDExplanation and Show-XKCDExplanation.
        -Path         Default download directory for Get-XKCD -Download.
        -FullSearch   Default for -FullSearch on Find-XKCD.
        -CachePath    Default comic data cache location for Update-XKCDCache, Get-XKCDCache and Find-XKCD.
        -StatePath    Default location of the most-recently-viewed record for Show-XKCD, Get-XKCD -Show and Test-XKCD.
        -Transcript   Default for -Transcript on Get-XKCDExplanation and Show-XKCDExplanation.
        -Discussion   Default for -Discussion on Get-XKCDExplanation and Show-XKCDExplanation.
        -Full         Default for -Full on Get-XKCDExplanation and Show-XKCDExplanation.

    .EXAMPLE
        Set-XKCDDefault -HighQuality

        Makes Get-XKCD, Show-XKCD, Get-XKCDExplanation and Show-XKCDExplanation use high quality images by default.

    .EXAMPLE
        Set-XKCDDefault -Path C:\XKCD

        Makes Get-XKCD -Download save images to C:\XKCD by default.

    .EXAMPLE
        Set-XKCDDefault -Full

        Makes Get-XKCDExplanation and Show-XKCDExplanation retrieve the explanation, transcript, and discussion by default.

    .EXAMPLE
        Set-XKCDDefault -HighQuality:$false

        Explicitly saves -HighQuality as disabled by default, overriding a previously saved value.

    .EXAMPLE
        Set-XKCDDefault -Reset

        Removes all saved default preferences.

    .LINK
        https://xkcd.com/json.html
    #>
    [cmdletbinding(SupportsShouldProcess)]
    Param(
        # Sets the default for -HighQuality, used by Get-XKCD, Show-XKCD, Get-XKCDExplanation and Show-XKCDExplanation.
        [switch]
        $HighQuality,

        # Sets the default download directory used by Get-XKCD -Download.
        [string]
        $Path,

        # Sets the default for -FullSearch, used by Find-XKCD.
        [switch]
        $FullSearch,

        # Sets the default comic data cache location used by Update-XKCDCache, Get-XKCDCache and Find-XKCD.
        [string]
        $CachePath,

        # Sets the default location of the most-recently-viewed record used by Show-XKCD, Get-XKCD -Show and Test-XKCD.
        [string]
        $StatePath,

        # Sets the default for -Transcript, used by Get-XKCDExplanation and Show-XKCDExplanation.
        [switch]
        $Transcript,

        # Sets the default for -Discussion, used by Get-XKCDExplanation and Show-XKCDExplanation.
        [switch]
        $Discussion,

        # Sets the default for -Full, used by Get-XKCDExplanation and Show-XKCDExplanation.
        [switch]
        $Full,

        # Removes all saved default preferences, restoring the module's built-in behavior.
        [switch]
        $Reset,

        # Path to the file used to store default preferences. By default this is within the module path.
        [string]
        $DefaultsPath = (Join-Path $PSScriptRoot 'XKCD.defaults.json')
    )

    if ($Reset) {
        if ((Test-Path $DefaultsPath) -and $PSCmdlet.ShouldProcess($DefaultsPath, 'Remove all saved default preferences')) {
            Remove-Item $DefaultsPath -Force
        }
        return [pscustomobject]@{}
    }

    $Current = Get-XKCDDefault -DefaultsPath $DefaultsPath

    if ($PSBoundParameters.ContainsKey('HighQuality')) { $Current | Add-Member -NotePropertyName HighQuality -NotePropertyValue ([bool]$HighQuality) -Force }
    if ($PSBoundParameters.ContainsKey('Path')) { $Current | Add-Member -NotePropertyName Path -NotePropertyValue $Path -Force }
    if ($PSBoundParameters.ContainsKey('FullSearch')) { $Current | Add-Member -NotePropertyName FullSearch -NotePropertyValue ([bool]$FullSearch) -Force }
    if ($PSBoundParameters.ContainsKey('CachePath')) { $Current | Add-Member -NotePropertyName CachePath -NotePropertyValue $CachePath -Force }
    if ($PSBoundParameters.ContainsKey('StatePath')) { $Current | Add-Member -NotePropertyName StatePath -NotePropertyValue $StatePath -Force }
    if ($PSBoundParameters.ContainsKey('Transcript')) { $Current | Add-Member -NotePropertyName Transcript -NotePropertyValue ([bool]$Transcript) -Force }
    if ($PSBoundParameters.ContainsKey('Discussion')) { $Current | Add-Member -NotePropertyName Discussion -NotePropertyValue ([bool]$Discussion) -Force }
    if ($PSBoundParameters.ContainsKey('Full')) { $Current | Add-Member -NotePropertyName Full -NotePropertyValue ([bool]$Full) -Force }

    $AnyPreferenceSpecified = 'HighQuality', 'Path', 'FullSearch', 'CachePath', 'StatePath', 'Transcript', 'Discussion', 'Full' | Where-Object { $PSBoundParameters.ContainsKey($_) }

    if ($AnyPreferenceSpecified -and $PSCmdlet.ShouldProcess($DefaultsPath, 'Save default preferences')) {
        $Current | ConvertTo-Json | Out-File $DefaultsPath -Force
    }

    $Current
}
