function Export-XKCDTerminalImage {
    <#
    .SYNOPSIS
        Renders a comic using the current terminal's inline image graphics protocol (Sixel, Kitty, or iTerm2)
        and saves the result to a file, so it can be redisplayed later with Import-XKCDTerminalImage.

    .DESCRIPTION
        The Export-XKCDTerminalImage cmdlet gets a comic and renders it exactly as Show-XKCD would -- using
        whichever inline graphics protocol your terminal supports -- but instead of writing the result to the
        console, it saves it to a file. That file can later be redisplayed instantly with
        Import-XKCDTerminalImage or Show-XKCD -Path, without needing network access or having to regenerate the
        image data again (which for Sixel in particular can take a while for large images).

        The saved file includes every field returned by Get-XKCD for the comic (num, title, alt, img, and so
        on), alongside the rendered image, so it can also be used as a self-contained, offline copy of the
        comic's full details.

        Because the saved file contains a protocol-specific escape sequence, it's only guaranteed to display
        correctly again in a terminal that supports the same graphics protocol it was exported with. The saved
        file records which protocol that was, and Import-XKCDTerminalImage and Show-XKCD -Path warn you if it
        doesn't match the protocol detected for the terminal you're importing it into.

        By default, Export-XKCDTerminalImage exports the latest available comic. When you use the -Number
        parameter (aliased as -Num) you can specify one or more specific comics to export.

        Use -Offline to get comic data from the local cache (created/refreshed by Update-XKCDCache) and render
        the comic's image from a copy previously saved with Get-XKCD -Download, instead of fetching either from
        the xkcd API -- this also governs which comic -Offline considers "latest" when -Number isn't specified.
        If the comic's image hasn't been downloaded to -DownloadPath yet, a warning is shown asking you to use
        -Download first, and that comic is skipped. Defaults to the value saved with Set-XKCDDefault -Offline,
        if any.

    .EXAMPLE
        Export-XKCDTerminalImage

        Exports the latest comic to the current working directory, e.g. as '.\2000.xkcdterm.json'.

    .EXAMPLE
        Export-XKCDTerminalImage -Number 353 -Path C:\XKCD

        Exports comic number 353 to C:\XKCD, as 'C:\XKCD\353.xkcdterm.json'.

    .EXAMPLE
        Get-XKCD -Newest 5 | Export-XKCDTerminalImage -Path C:\XKCD

        Exports the 5 most recent comics to C:\XKCD.

    .EXAMPLE
        Export-XKCDTerminalImage -Number 353 -PassThru | Import-XKCDTerminalImage

        Exports comic number 353 and immediately redisplays it from the saved file.

    .EXAMPLE
        Export-XKCDTerminalImage -Number 353 -Force

        Re-exports comic number 353, overwriting '.\353.xkcdterm.json' if it already exists. Without -Force,
        Export-XKCDTerminalImage throws rather than overwrite an existing file.

    .EXAMPLE
        Export-XKCDTerminalImage -Number 353 -Offline -DownloadPath C:\XKCD

        Exports comic number 353 using its data from the local cache and its image from a copy previously
        saved to C:\XKCD with Get-XKCD -Download -Path C:\XKCD, without contacting the xkcd API.

    .LINK
        https://github.com/markwragg/Powershell-XKCD/wiki/Export-XKCDTerminalImage

    .LINK
        https://xkcd.com/json.html
    #>
    [cmdletbinding(SupportsShouldProcess)]
    Param(
        # Exports the specified comics. Accepts array input. By default the latest comic is exported.
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [Alias('Num')]
        [int[]]
        $Number,

        # Renders the higher resolution (_2x) version of the image, where available. Comics that do not have a
        # higher resolution version are rendered at the standard quality instead. Defaults to the value saved
        # with Set-XKCDDefault -HighQuality, if any.
        [switch]
        $HighQuality = (Get-XKCDDefaultValue -Name 'HighQuality' -Value $false),

        # The local directory to save the exported file(s) to. Each comic is saved as '<num>.xkcdterm.json'. By
        # default this is the current working directory, unless a default has been saved with
        # Set-XKCDDefault -Path.
        [string]
        $Path = (Get-XKCDDefaultValue -Name 'Path' -Value $PWD),

        # Returns a FileInfo object for each file saved, e.g. so it can be piped directly into
        # Import-XKCDTerminalImage.
        [switch]
        $PassThru,

        # Overwrites the destination file if it already exists. Without -Force, Export-XKCDTerminalImage throws
        # rather than overwrite an existing export.
        [switch]
        $Force,

        # Gets comic data from the local cache, and renders the comic's image from a copy previously saved
        # with Get-XKCD -Download, instead of fetching either from the xkcd API. Warns and skips the comic if
        # its image hasn't been downloaded to -DownloadPath yet. Defaults to the value saved with
        # Set-XKCDDefault -Offline, if any.
        [switch]
        $Offline = (Get-XKCDDefaultValue -Name 'Offline' -Value $false),

        # Use with -Offline to specify where comic data is cached. By default this is within the module path,
        # unless a default has been saved with Set-XKCDDefault -CachePath.
        [string]
        $CachePath = (Get-XKCDDefaultValue -Name 'CachePath' -Value (Join-Path $PSScriptRoot 'XKCD.json')),

        # Use with -Offline to specify the local directory to look for previously downloaded comic images in
        # (as saved by Get-XKCD -Download). By default this is the current working directory, unless a default
        # has been saved with Set-XKCDDefault -Path.
        [string]
        $DownloadPath = (Get-XKCDDefaultValue -Name 'Path' -Value $PWD)
    )

    Begin {
        if (-not $Number) {
            $Number = if ($Offline) {
                (Get-XKCDOfflineComic -CachePath $CachePath | Sort-Object num -Descending | Select-Object -First 1).num
            }
            else {
                (Invoke-RestMethod 'https://xkcd.com/info.0.json').num
            }
        }
    }

    Process {
        $Number | ForEach-Object {
            $Comic = Get-XKCD -Num $_ -NoStateUpdate -Offline:$Offline -CachePath $CachePath
            if (-not $Comic) { return }

            $OutFile = Join-Path $Path "$($Comic.num).xkcdterm.json"

            if ((Test-Path $OutFile) -and -not $Force) {
                throw "A terminal image for comic #$($Comic.num) already exists at '$OutFile'. Use -Force to overwrite it."
            }

            if ($Offline) {
                $ImageBytes = Get-XKCDOfflineImageContent -Comic $Comic -Path $DownloadPath
                if (-not $ImageBytes) { return }
            }
            else {
                $ImageBytes = Get-XKCDComicImageContent -Comic $Comic -HighQuality:$HighQuality
            }

            $Protocol = Get-XKCDTerminalGraphicsProtocol

            if (-not $Protocol) {
                Write-Warning "Your terminal does not appear to support inline image display (Sixel, Kitty, or iTerm2 graphics protocols), so comic #$($Comic.num) could not be exported."
                return
            }

            try {
                $TerminalImage = ConvertTo-XKCDTerminalImage -ImageBytes $ImageBytes -Protocol $Protocol -HighQuality:$HighQuality
            }
            catch {
                Write-Warning "Unable to render comic #$($Comic.num) as $($Protocol): $_"
                return
            }

            if ($PSCmdlet.ShouldProcess($OutFile, "Save the $Protocol terminal image for comic #$($Comic.num)")) {
                $Comic | Add-Member -NotePropertyName Protocol -NotePropertyValue $Protocol -Force
                $Comic | Add-Member -NotePropertyName Image -NotePropertyValue $TerminalImage -Force

                $Comic | ConvertTo-Json | Out-File $OutFile -Force

                if ($PassThru) { Get-Item $OutFile }
            }
        }
    }
}
