function Show-XKCDTuiFrame {
    <#
    .SYNOPSIS
        Renders a full-screen frame for Start-XKCD: the XKCD banner, the comic's title, the control bar, its
        date/link, its image (centered, where available), its alt text, and the control bar again -- clearing
        the console first.
    #>
    [cmdletbinding()]
    Param(
        # The comic object returned by the xkcd API (must have num, title, and alt properties).
        [Parameter(Mandatory)]
        [pscustomobject]
        $Comic,

        # The raw bytes of the comic's image (e.g. PNG or JPEG). Omit to render the frame without an image,
        # e.g. because it couldn't be obtained.
        [byte[]]
        $ImageBytes,

        # Indicates that $ImageBytes is a higher resolution (_2x) source image, so it's rendered at a
        # correspondingly higher quality rather than downscaled to the standard size.
        [switch]
        $HighQuality,

        # The console width to center and wrap content to.
        [int]
        $Width = 80,

        # A warning or notice to display in place of (or alongside) the image, e.g. because the image
        # couldn't be obtained, or a requested quality wasn't available. Rendered as part of the frame itself
        # rather than via Write-Warning, so it always appears in a consistent spot instead of possibly
        # showing up out of order relative to the rest of the frame.
        [string]
        $Warning
    )

    $esc = [char]27
    $reset = "$esc[0m"

    try {
        [Console]::Clear()
    }
    catch {
        Write-Verbose 'Unable to clear the console (e.g. output redirected); continuing without clearing.'
    }

    $Banner = Get-XKCDBanner

    Write-XKCDCenteredLine -Width $Width
    foreach ($Line in $Banner.Lines) {
        Write-XKCDCenteredLine -Width $Width -Text "$esc[1;93m$Line$reset"
    }
    Write-XKCDCenteredLine -Width $Width -Text "$esc[2m$($Banner.Tagline)$reset"
    Write-XKCDCenteredLine -Width $Width

    Write-XKCDCenteredLine -Width $Width -Text "$esc[1;4;96m#$($Comic.num): $($Comic.title)$reset"
    Write-XKCDCenteredLine -Width $Width

    $Controls = Get-XKCDControlsText
    Write-XKCDCenteredLine -Width $Width -Text "$esc[7m$Controls$reset"
    Write-XKCDCenteredLine -Width $Width

    Write-XKCDCenteredLine -Width $Width -Text "$esc[2m$(Get-XKCDComicMetaText -Comic $Comic)$reset"
    Write-XKCDCenteredLine -Width $Width

    if ($ImageBytes) {
        Show-XKCDTuiImage -ImageBytes $ImageBytes -HighQuality:$HighQuality -Width $Width
        Write-XKCDCenteredLine -Width $Width
    }

    if ($Warning) {
        Write-XKCDCenteredLine -Width $Width -Text "$esc[33m$Warning$reset"
        Write-XKCDCenteredLine -Width $Width
    }

    if ($Comic.alt) {
        $Words = $Comic.alt -split '\s+'
        $Lines = [System.Collections.Generic.List[string]]::new()
        $CurrentLine = ''
        $WrapWidth = [Math]::Min($Width - 4, 80)

        foreach ($Word in $Words) {
            if (-not $CurrentLine) {
                $CurrentLine = $Word
            }
            elseif (($CurrentLine.Length + 1 + $Word.Length) -le $WrapWidth) {
                $CurrentLine = "$CurrentLine $Word"
            }
            else {
                $Lines.Add($CurrentLine)
                $CurrentLine = $Word
            }
        }
        if ($CurrentLine) { $Lines.Add($CurrentLine) }

        foreach ($Line in $Lines) {
            Write-XKCDCenteredLine -Width $Width -Text "$esc[3m$Line$reset"
        }
        Write-XKCDCenteredLine -Width $Width
    }

    Write-XKCDCenteredLine -Width $Width -Text "$esc[7m$Controls$reset"
}
