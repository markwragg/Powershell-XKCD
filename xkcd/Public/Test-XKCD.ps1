function Test-XKCD {
    <#
    .SYNOPSIS
        Checks whether any new comics have been published since the last time Test-XKCD was run.

    .DESCRIPTION
        The Test-XKCD cmdlet compares the latest comic number available from the XKCD API against a local
        record of the most recently viewed comic (updated by Show-XKCD and Get-XKCD -Show), and reports
        whether any new comics are available. Test-XKCD only reads this record -- it never updates it.

        By default it writes a friendly message to the console stating how many new comics are available and
        the publish date of the latest one, if that date can be determined. Use -Quiet to suppress this message
        and instead return a boolean. Use -Detailed to return a PSCustomObject describing how many new comics
        are available, alongside the last viewed and latest comic numbers.

        Use -Num to instead test whether a specific numbered comic exists, returning $true or $false.

        Use -AddToProfile to add `if (Test-XKCD -Quiet) { Test-XKCD }` to your PowerShell profile (creating it,
        and its containing directory, if either doesn't already exist), so new comics are reported automatically
        whenever you open a new session. Does nothing if that line is already present. Use -RemoveFromProfile to
        remove it again -- does nothing if the profile doesn't exist or doesn't contain that line.

    .EXAMPLE
        Test-XKCD

        Writes a friendly message to the console stating how many new comics are available (if any) and the
        publish date of the latest one, where determinable.

    .EXAMPLE
        Test-XKCD -Quiet

        Returns $true if new comics are available since the last check, otherwise $false, without writing a
        message to the console.

    .EXAMPLE
        Test-XKCD -Detailed

        Returns a PSCustomObject detailing whether new comics are available, how many, and the last viewed vs latest comic numbers.

    .EXAMPLE
        Test-XKCD -Num 999999

        Returns $true if comic #999999 exists, otherwise $false.

    .EXAMPLE
        if (Test-XKCD -Quiet) { Test-XKCD }

        If new comics are available, this will write a friendly message to the console stating how many new comics are available
        (if any) and the publish date of the latest one, where determinable.

        Add this to your PowerShell profile.ps1 to have it run automatically when you open a new session and prompt you only when new
        comics are available.

    .EXAMPLE
        Test-XKCD -AddToProfile

        Adds `if (Test-XKCD -Quiet) { Test-XKCD }` to your PowerShell profile, creating the profile file (and its
        containing directory) if it doesn't already exist. Does nothing if that line is already present.

    .EXAMPLE
        Test-XKCD -RemoveFromProfile

        Removes `if (Test-XKCD -Quiet) { Test-XKCD }` from your PowerShell profile, if it's there. Does nothing
        if the profile doesn't exist or doesn't contain that line.

    .LINK
        https://xkcd.com/json.html
    #>
    [cmdletbinding(DefaultParameterSetName = 'Default', SupportsShouldProcess)]
    Param(
        # Tests whether the specified comic number exists, returning $true or $false. When used, no other
        # parameters are considered.
        [Parameter(ParameterSetName = 'Num', Mandatory, Position = 0)]
        [Alias('Number')]
        [int]
        $Num,

        # Adds `if (Test-XKCD -Quiet) { Test-XKCD }` to your PowerShell profile (creating it, and its containing
        # directory, if either doesn't already exist), so new comics are reported automatically whenever you
        # open a new session. Does nothing if that line is already present.
        [Parameter(ParameterSetName = 'AddToProfile', Mandatory)]
        [switch]
        $AddToProfile,

        # Removes `if (Test-XKCD -Quiet) { Test-XKCD }` (and, if present immediately above it, the comment
        # -AddToProfile adds) from your PowerShell profile. Does nothing if the profile doesn't exist or doesn't
        # contain that line.
        [Parameter(ParameterSetName = 'RemoveFromProfile', Mandatory)]
        [switch]
        $RemoveFromProfile,

        # Suppresses the friendly console message and instead returns a boolean.
        [Parameter(ParameterSetName = 'Default')]
        [switch]
        $Quiet,

        # Returns a detailed PSCustomObject describing how many new comics are available, instead of a boolean or console message.
        [Parameter(ParameterSetName = 'Default')]
        [switch]
        $Detailed,

        # Path to the file that tracks the number of the most recently viewed comic (written by Show-XKCD and
        # Get-XKCD -Show). By default this is in the user's per-user data directory (~/.xkcd), unless a default
        # has been saved with Set-XKCDDefault -StatePath.
        [Parameter(ParameterSetName = 'Default')]
        [string]
        $StatePath = (Get-XKCDDefaultValue -Name 'StatePath' -Value (Get-XKCDUserDataPath -FileName 'XKCD.state.json' -LegacyDirectory $PSScriptRoot))
    )

    if ($AddToProfile -or $RemoveFromProfile) {
        $Line = 'if (Test-XKCD -Quiet) { Test-XKCD }'
        $Comment = '# Added by Test-XKCD -AddToProfile: notify about new XKCD comics on every new session'

        # -SimpleMatch already treats -Pattern as a literal string, not a regex -- escaping it first (e.g. via
        # [regex]::Escape) would be wrong here, since the literal backslashes that adds are then searched for
        # as-is and never match.
        $AlreadyPresent = (Test-Path $PROFILE) -and (Select-String -Path $PROFILE -Pattern $Line -SimpleMatch -Quiet)

        if ($AddToProfile) {
            if ($AlreadyPresent) {
                return "'$Line' is already present in '$PROFILE'. No changes made."
            }

            if ($PSCmdlet.ShouldProcess($PROFILE, "Add '$Line'")) {
                $ProfileDirectory = Split-Path $PROFILE -Parent
                if (-not (Test-Path $ProfileDirectory)) {
                    New-Item -ItemType Directory -Path $ProfileDirectory -Force | Out-Null
                }
                if (-not (Test-Path $PROFILE)) {
                    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
                }

                Add-Content -Path $PROFILE -Value @('', $Comment, $Line)
                "Added '$Line' to '$PROFILE'."
            }
            return
        }

        # $RemoveFromProfile
        if (-not $AlreadyPresent) {
            return "'$Line' was not found in '$PROFILE'. No changes made."
        }

        if ($PSCmdlet.ShouldProcess($PROFILE, "Remove '$Line'")) {
            $Content = @(Get-Content -Path $PROFILE)

            # Walk backwards, dropping each matching line and, if -AddToProfile's own comment (and the blank
            # line before it) immediately precede it, those too -- so removal cleanly undoes what -AddToProfile
            # added, but a matching line added some other way just has itself removed.
            $LinesToRemove = [System.Collections.Generic.HashSet[int]]::new()
            for ($i = $Content.Count - 1; $i -ge 0; $i--) {
                if ($Content[$i].Trim() -ne $Line) { continue }
                [void]$LinesToRemove.Add($i)

                if ($i -gt 0 -and $Content[$i - 1].Trim() -eq $Comment) {
                    [void]$LinesToRemove.Add($i - 1)

                    if ($i -gt 1 -and $Content[$i - 2].Trim() -eq '') {
                        [void]$LinesToRemove.Add($i - 2)
                    }
                }
            }

            $NewContent = @( for ($i = 0; $i -lt $Content.Count; $i++) { if (-not $LinesToRemove.Contains($i)) { $Content[$i] } } )
            Set-Content -Path $PROFILE -Value $NewContent
            "Removed '$Line' from '$PROFILE'."
        }
        return
    }

    if ($PSCmdlet.ParameterSetName -eq 'Num') {
        try {
            Invoke-RestMethod "https://xkcd.com/$Num/info.0.json" -ErrorAction Stop | Out-Null
            return $true
        }
        catch {
            return $false
        }
    }

    $LatestComic = Invoke-RestMethod 'https://xkcd.com/info.0.json'
    $Latest = $LatestComic.num

    $LastViewed = Get-XKCDLastViewedComic -StatePath $StatePath
    if (-not (Test-Path $StatePath)) {
        Write-Verbose "No local record of previously viewed comics found at '$StatePath'. Treating all comics up to #$Latest as new."
    }

    $NewComicCount = [math]::Max(0, $Latest - $LastViewed)
    $HasNewComics = $NewComicCount -gt 0

    if ($Detailed) {
        [pscustomobject]@{
            HasNewComics  = $HasNewComics
            NewComicCount = $NewComicCount
            LastViewed    = $LastViewed
            LatestComic   = $Latest
        }
    }
    elseif ($Quiet) {
        $HasNewComics
    }
    else {
        $LatestDate = $null
        if ($LatestComic.year -and $LatestComic.month -and $LatestComic.day) {
            try {
                $LatestDate = Get-Date -Year ([int]$LatestComic.year) -Month ([int]$LatestComic.month) -Day ([int]$LatestComic.day) -ErrorAction Stop
            }
            catch {
                $LatestDate = $null
            }
        }
        $DateText = if ($LatestDate) { ", published $($LatestDate.ToString('d MMMM yyyy'))" } else { '' }

        if ($HasNewComics) {
            $ComicWord = if ($NewComicCount -eq 1) { 'comic' } else { 'comics' }
            "$NewComicCount new XKCD $ComicWord available! The latest is #$Latest$DateText."
        }
        else {
            "No new XKCD comics available. You're up to date with #$Latest$DateText."
        }
    }
}
