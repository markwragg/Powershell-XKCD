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

        By default, Export-XKCDTerminalImage exports the latest available comic. When you use the -Num
        parameter you can specify one or more specific comics to export.

    .EXAMPLE
        Export-XKCDTerminalImage

        Exports the latest comic to the current working directory, e.g. as '.\2000.xkcdterm.json'.

    .EXAMPLE
        Export-XKCDTerminalImage -Num 353 -Path C:\XKCD

        Exports comic number 353 to C:\XKCD, as 'C:\XKCD\353.xkcdterm.json'.

    .EXAMPLE
        Get-XKCD -Newest 5 | Export-XKCDTerminalImage -Path C:\XKCD

        Exports the 5 most recent comics to C:\XKCD.

    .EXAMPLE
        Export-XKCDTerminalImage -Num 353 -PassThru | Import-XKCDTerminalImage

        Exports comic number 353 and immediately redisplays it from the saved file.

    .EXAMPLE
        Export-XKCDTerminalImage -Num 353 -Force

        Re-exports comic number 353, overwriting '.\353.xkcdterm.json' if it already exists. Without -Force,
        Export-XKCDTerminalImage throws rather than overwrite an existing file.

    .LINK
        https://xkcd.com/json.html
    #>
    [cmdletbinding(SupportsShouldProcess)]
    Param(
        # Exports the specified comics. Accepts array input. By default the latest comic is exported.
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [int[]]
        $Num,

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
        $Force
    )

    Begin {
        if (-not $Num) {
            $Num = (Invoke-RestMethod 'https://xkcd.com/info.0.json').num
        }
    }

    Process {
        $Num | ForEach-Object {
            $Comic = Get-XKCD -Num $_
            $OutFile = Join-Path $Path "$($Comic.num).xkcdterm.json"

            if ((Test-Path $OutFile) -and -not $Force) {
                throw "A terminal image for comic #$($Comic.num) already exists at '$OutFile'. Use -Force to overwrite it."
            }

            $ImageBytes = Get-XKCDComicImageBytes -Comic $Comic -HighQuality:$HighQuality

            $Protocol = Get-XKCDTerminalGraphicsProtocol

            if (-not $Protocol) {
                Write-Warning "Your terminal does not appear to support inline image display (Sixel, Kitty, or iTerm2 graphics protocols), so comic #$($Comic.num) could not be exported."
                return
            }

            try {
                $TerminalImage = ConvertTo-XKCDTerminalImage -ImageBytes $ImageBytes -Protocol $Protocol
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
