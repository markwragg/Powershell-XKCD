function Show-XKCDTuiImage {
    <#
    .SYNOPSIS
        Writes a comic's image to the console, horizontally centered, using whichever inline graphics protocol
        the terminal supports (Kitty, iTerm2, or Sixel). Does nothing but warn if none are detected.

    .DESCRIPTION
        Kitty and iTerm2 can be told exactly how many terminal columns to render an image into, so centering
        for those protocols is exact. Sixel has no equivalent control -- it always renders at the image's
        actual pixel size relative to the terminal's real (and unqueryable, from here) cell size -- so its
        padding is only an approximation, estimated from the image's own pixel width (after the same
        downscaling ConvertTo-XKCDSixel applies) and an assumed typical monospace cell width.
    #>
    [cmdletbinding()]
    Param(
        # The raw bytes of the image to display (e.g. PNG or JPEG).
        [Parameter(Mandatory)]
        [byte[]]
        $ImageBytes,

        # Indicates that $ImageBytes is a higher resolution (_2x) source image, so it should be rendered at a
        # correspondingly higher quality rather than downscaled to the standard size.
        [switch]
        $HighQuality,

        # The console width to center the image within.
        [int]
        $Width = 80
    )

    $Protocol = Get-XKCDTerminalGraphicsProtocol

    if (-not $Protocol) {
        Write-Warning 'Your terminal does not appear to support inline image display (Sixel, Kitty, or iTerm2 graphics protocols), so the comic could not be shown.'
        return
    }

    $DisplayColumns = Get-XKCDTerminalImageColumns -ImageBytes $ImageBytes -Width $Width -HighQuality:$HighQuality
    $Padding = [Math]::Max(0, [int][Math]::Floor(($Width - $DisplayColumns) / 2))

    try {
        $TerminalImageParams = @{
            ImageBytes  = $ImageBytes
            Protocol    = $Protocol
            HighQuality = $HighQuality
        }
        if ($Protocol -in 'Kitty', 'iTerm2') {
            $TerminalImageParams.Columns = $DisplayColumns
        }

        # ConvertTo-XKCDSixel's own large-image warning is written via the usual Write-Warning (suppressed
        # here so it doesn't also show up in its default, un-centered form) -- but since that only fires
        # *before* the slow conversion it warns about, the -OnLargeImageWarning callback is what actually
        # gets it on screen at that point, rather than only after the whole (slow) call below has returned.
        # Deliberately self-contained (no call out to Write-XKCDCenteredLine or any other module function):
        # .GetNewClosure() detaches the scriptblock's command resolution from the module, so a call to a
        # module-private function here would fail silently once invoked from inside ConvertTo-XKCDSixel.
        # Left without a trailing newline (cursor stays on this line) so the image, once ready, can overwrite
        # it in place below rather than leaving a stale "may take a while" notice sitting above the comic.
        # $WarningState is a hashtable (rather than a plain variable) purely so the closure's mutation of
        # .Shown is visible back here afterwards -- GetNewClosure() snapshots variable *bindings*, so a
        # reassigned plain variable inside the closure wouldn't be, but a shared object's mutated contents are.
        $CapturedWidth = $Width
        $WarningState = @{ Shown = $false }
        $TerminalImageParams.OnLargeImageWarning = {
            Param($Message)
            $Padding = [Math]::Max(0, [int][Math]::Floor(($CapturedWidth - $Message.Length) / 2))
            [Console]::Out.Write((' ' * $Padding) + "$([char]27)[33m$Message$([char]27)[0m")
            $WarningState.Shown = $true
        }.GetNewClosure()

        $TerminalImage = ConvertTo-XKCDTerminalImage @TerminalImageParams -WarningAction SilentlyContinue
    }
    catch {
        Write-Warning "Unable to render the comic as $($Protocol): $_"
        return
    }

    if ($WarningState.Shown) {
        # `\r` + erase-line returns to the start of that line and clears it, so the image replaces the
        # large-image notice in place instead of leaving it sitting above the comic.
        [Console]::Out.Write("`r$([char]27)[2K")
    }
    [Console]::Out.Write(' ' * $Padding)
    [Console]::Out.Write($TerminalImage)
    [Console]::Out.Write([Environment]::NewLine)
}
