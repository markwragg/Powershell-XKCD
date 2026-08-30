function Get-XKCDComicImageBytes {
    <#
    .SYNOPSIS
        Downloads a comic's image, falling back to standard quality (with a warning) if -HighQuality was
        requested but no higher resolution version is available for that comic.
    #>
    [cmdletbinding()]
    Param(
        # The comic object returned by the xkcd API, used for its img property.
        [Parameter(Mandatory)]
        [pscustomobject]
        $Comic,

        # Requests the higher resolution (_2x) version of the image, where available.
        [switch]
        $HighQuality
    )

    $ImageUrl = $Comic.img

    if ($HighQuality) {
        $Extension = [System.IO.Path]::GetExtension(([uri]$Comic.img).AbsolutePath)
        $ImageUrl = $Comic.img.Insert($Comic.img.LastIndexOf($Extension), '_2x')
    }

    try {
        (Invoke-WebRequest $ImageUrl -UseBasicParsing -ErrorAction Stop).Content
    }
    catch {
        if ($HighQuality) {
            Write-Warning "High quality image not available for comic $($Comic.num), using standard quality instead"
            (Invoke-WebRequest $Comic.img -UseBasicParsing).Content
        }
        else {
            throw
        }
    }
}
