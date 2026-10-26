function Get-XKCDImageSize {
    <#
    .SYNOPSIS
        Returns the pixel width/height of an image. Reads PNG dimensions directly from the file header (fast,
        and works on every OS); for other formats (e.g. JPEG, used by xkcd's earliest comics), falls back to
        System.Drawing on Windows. Returns $null if the dimensions can't be determined.
    #>
    [cmdletbinding()]
    Param(
        # The raw bytes of the image to measure (e.g. PNG or JPEG).
        [Parameter(Mandatory)]
        [byte[]]
        $ImageBytes
    )

    $IsPng = $ImageBytes.Length -ge 24 -and $ImageBytes[0] -eq 137 -and $ImageBytes[1] -eq 80 -and $ImageBytes[2] -eq 78 -and $ImageBytes[3] -eq 71

    if ($IsPng) {
        # The IHDR chunk is always first, immediately after the 8-byte signature and its own 8-byte chunk
        # header (4-byte length + 4-byte type), and its first two 4-byte big-endian fields are width/height.
        $Width = ([int]$ImageBytes[16] -shl 24) -bor ([int]$ImageBytes[17] -shl 16) -bor ([int]$ImageBytes[18] -shl 8) -bor [int]$ImageBytes[19]
        $Height = ([int]$ImageBytes[20] -shl 24) -bor ([int]$ImageBytes[21] -shl 16) -bor ([int]$ImageBytes[22] -shl 8) -bor [int]$ImageBytes[23]

        return [pscustomobject]@{ Width = $Width; Height = $Height }
    }

    # System.Drawing.Common is Windows-only from .NET 6 onwards, so non-PNG images (effectively just the
    # JPEGs used by xkcd's earliest comics) have no cross-platform way to measure here.
    if (-not (Test-Path Variable:Global:IsWindows) -or $IsWindows) {
        try {
            Add-Type -AssemblyName System.Drawing
            $Stream = [System.IO.MemoryStream]::new($ImageBytes)
            try {
                $Image = [System.Drawing.Image]::FromStream($Stream)
                try {
                    return [pscustomobject]@{ Width = $Image.Width; Height = $Image.Height }
                }
                finally {
                    $Image.Dispose()
                }
            }
            finally {
                $Stream.Dispose()
            }
        }
        catch {
            return $null
        }
    }

    $null
}
