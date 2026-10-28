function Show-XKCDAdminConsole {
    <#
    .SYNOPSIS
        Start-XKCD's secret easter egg: press ` (backtick) while browsing to drop into a fake admin console
        that presents the local comic archive (XKCD.json) as a navigable filesystem, mounted at
        /<year>/<month>/<num>.json. Runs its own read-eval-print loop (via Invoke-XKCDAdminCommand) until the
        user exits, optionally returning a comic number to jump to (from "open"/"view").
    #>
    [cmdletbinding()]
    Param(
        # Path to the comic data cache to browse -- the same file used by -Offline, browsed here regardless
        # of whether the current Start-XKCD session is actually running in -Offline mode.
        [Parameter(Mandatory)]
        [string]
        $CachePath,

        # A pre-selected seasonal emoji to flank the banner with (see Get-XKCDBanner), so Start-XKCD can show
        # the same one across redraws for the rest of the session instead of re-randomizing on every frame.
        # Pass $null (or omit) to pick a new random one for the current month.
        [string]
        $Seasonal
    )

    $esc = [char]27
    $Green = "$esc[1;92m"
    $Blue = "$esc[1;94m"
    $Reset = "$esc[0m"
    $NewLine = [Environment]::NewLine

    try {
        [Console]::Clear()
    }
    catch {
        Write-Verbose 'Unable to clear the console (e.g. output redirected); continuing without clearing.'
    }

    $BannerParams = if ($PSBoundParameters.ContainsKey('Seasonal')) { @{ Seasonal = $Seasonal } } else { @{} }
    $Banner = Get-XKCDBanner @BannerParams
    foreach ($BannerLine in $Banner.Lines) {
        [Console]::Out.Write("${Green}$BannerLine${Reset}$NewLine")
    }
    [Console]::Out.Write("${esc}[2m$($Banner.Tagline)${Reset}$NewLine")
    [Console]::Out.Write($NewLine)

    [Console]::Out.Write("${Green}Connecting to the xkcd mainframe...${Reset}$NewLine")
    [Console]::Out.Write("${Green}Access granted.${Reset}$NewLine")
    [Console]::Out.Write($NewLine)
    [Console]::Out.Write("You've found the secret XKCD admin console.$NewLine")
    [Console]::Out.Write("The local comic archive is mounted at / -- browse it like a filesystem: /<year>/<month>/<num>.json$NewLine")
    [Console]::Out.Write("Type 'help' for a list of commands, or 'exit' to return to the comic.$NewLine")
    [Console]::Out.Write($NewLine)

    $Comic = @()
    try {
        $Comic = @(Get-XKCDOfflineComic -CachePath $CachePath -ErrorAction Stop)
    }
    catch {
        [Console]::Out.Write("mount: ${CachePath}: No such file or directory$NewLine")
        [Console]::Out.Write("(Run Update-XKCDCache first to create a local archive to browse.)$NewLine")
        [Console]::Out.Write($NewLine)
    }

    $Path = @()

    while ($true) {
        $PathDisplay = if ($Path.Count -eq 0) { '/' } else { '/' + ($Path -join '/') }
        [Console]::Out.Write("${Green}root@xkcd${Reset}:${Blue}$PathDisplay${Reset}# ")

        $Line = Read-XKCDConsoleLine
        if ($null -eq $Line) { return $null }

        $Result = Invoke-XKCDAdminCommand -Comic $Comic -Path $Path -Line $Line

        foreach ($OutputLine in $Result.Output) {
            [Console]::Out.Write("$OutputLine$NewLine")
        }

        $Path = $Result.Path

        if ($Result.Exit) { return $Result.Jump }
    }
}
