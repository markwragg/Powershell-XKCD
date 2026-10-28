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
        $Warning,

        # A hashtable used to re-use a previously rendered terminal image rather than rendering it again --
        # used by Start-XKCD so revisiting a comic already shown this session skips the (particularly slow,
        # for Sixel) re-render. Keyed internally by the comic's number plus -HighQuality. Omit to always
        # render the image fresh.
        [hashtable]
        $Cache,

        # A pre-selected seasonal emoji to flank the banner with (see Get-XKCDBanner), so Start-XKCD can show
        # the same one across redraws for the rest of the session instead of re-randomizing on every frame.
        # Pass $null (or omit) to pick a new random one for the current month.
        [string]
        $Seasonal
    )

    $esc = [char]27
    $reset = "$esc[0m"

    try {
        [Console]::Clear()
    }
    catch {
        Write-Verbose 'Unable to clear the console (e.g. output redirected); continuing without clearing.'
    }

    $BannerParams = if ($PSBoundParameters.ContainsKey('Seasonal')) { @{ Seasonal = $Seasonal } } else { @{} }
    $Banner = Get-XKCDBanner @BannerParams

    # In June (Pride Month), stripe the banner with the colours of the original 8-colour pride flag
    # instead of the usual solid yellow, one colour per line.
    $PrideColors = if ((Get-Date).Month -eq 6) {
        @(198, 202, 208, 220, 46, 45, 27, 128)
    }

    Write-XKCDCenteredLine -Width $Width
    for ($i = 0; $i -lt $Banner.Lines.Count; $i++) {
        $Line = $Banner.Lines[$i]
        $Color = if ($PrideColors) { "38;5;$($PrideColors[$i % $PrideColors.Count])" } else { '93' }
        Write-XKCDCenteredLine -Width $Width -Text "$esc[1;${Color}m$Line$reset"
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
        Show-XKCDTuiImage -ImageBytes $ImageBytes -HighQuality:$HighQuality -Width $Width -Cache $Cache -CacheKey "$($Comic.num)|$HighQuality"
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
