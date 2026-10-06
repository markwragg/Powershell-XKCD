function Get-XKCDOfflineImageContent {
    <#
    .SYNOPSIS
        Returns the raw bytes of a comic's image from the local download path (previously saved there by
        Get-XKCD -Download), without making any network request. Returns nothing, with a warning, if the image
        hasn't been downloaded to that path yet.
    #>
    [cmdletbinding()]
    Param(
        # The comic object, used for its num and img properties (img is only used to work out the file
        # extension Get-XKCD -Download would have saved it with).
        [Parameter(Mandatory)]
        [pscustomobject]
        $Comic,

        # The local directory to look for the comic's previously downloaded image in.
        [Parameter(Mandatory)]
        [string]
        $Path
    )

    $Extension = [System.IO.Path]::GetExtension(([uri]$Comic.img).AbsolutePath)
    $ImageFile = Join-Path $Path "$($Comic.num)$Extension"

    if (Test-Path $ImageFile) {
        [System.IO.File]::ReadAllBytes((Resolve-Path $ImageFile).ProviderPath)
    }
    else {
        Write-Warning "Comic #$($Comic.num) has not been downloaded to '$Path'. Use -Download to download it first, then try -Offline again."
    }
}
