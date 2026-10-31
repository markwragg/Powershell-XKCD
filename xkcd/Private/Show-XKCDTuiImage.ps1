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
        $Width = 80,

        # A hashtable used to re-use a previously rendered terminal image rather than rendering it again --
        # used by Start-XKCD so revisiting a comic already shown this session (e.g. via P/N) skips the
        # conversion, which for Sixel in particular can take a while. Start-XKCD passes in the same
        # module-scoped cache Show-XKCDImage uses for Show-XKCD/Show-XKCDExplanation, so a comic already
        # rendered by one of those cmdlets (or vice versa) is re-used here too. Keyed by -CacheKey plus the
        # detected protocol, so switching terminals mid-session (unlikely, but cheap to guard against) can't
        # return a stale render for the wrong protocol. Omit (along with -CacheKey) to always render fresh.
        [hashtable]
        $Cache,

        # The key identifying this image within -Cache, e.g. the comic's number plus -HighQuality -- anything
        # that uniquely identifies $ImageBytes for the caller's purposes. Ignored if -Cache isn't supplied.
        [string]
        $CacheKey
    )

    $Protocol = Get-XKCDTerminalGraphicsProtocol

    if (-not $Protocol) {
        Write-Warning 'Your terminal does not appear to support inline image display (Sixel, Kitty, or iTerm2 graphics protocols), so the comic could not be shown.'
        return
    }

    $DisplayColumns = Get-XKCDTerminalImageColumnCount -ImageBytes $ImageBytes -Width $Width -HighQuality:$HighQuality
    $Padding = [Math]::Max(0, [int][Math]::Floor(($Width - $DisplayColumns) / 2))

    $FullCacheKey = if ($Cache -and $CacheKey) { "$CacheKey|$Protocol" }

    # A hashtable (rather than a plain variable) purely so the OnLargeImageWarning closure's mutation of
    # .Shown is visible back here afterwards -- GetNewClosure() snapshots variable *bindings*, so a
    # reassigned plain variable inside the closure wouldn't be, but a shared object's mutated contents are.
    $WarningState = @{ Shown = $false }

    if ($FullCacheKey -and $Cache.ContainsKey($FullCacheKey)) {
        $TerminalImage = $Cache[$FullCacheKey]
    }
    else {
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
            $CapturedWidth = $Width
            $TerminalImageParams.OnLargeImageWarning = {
                Param($Message)
                $Padding = [Math]::Max(0, [int][Math]::Floor(($CapturedWidth - $Message.Length) / 2))
                [Console]::Out.Write((' ' * $Padding) + "$([char]27)[33m$Message$([char]27)[0m")
                $WarningState.Shown = $true
            }.GetNewClosure()

            # Lets a pending keypress (e.g. paging to the next comic) abandon a slow Sixel conversion instead
            # of blocking behind it -- KeyAvailable only peeks, so whatever key is waiting is still there
            # afterwards for Start-XKCD's own blocking read to pick straight up. Wrapped in a try/catch since
            # it throws when there's no real console to check (e.g. output redirected, or under test).
            $TerminalImageParams.ShouldCancel = {
                try { [Console]::KeyAvailable } catch { $false }
            }

            $TerminalImage = ConvertTo-XKCDTerminalImage @TerminalImageParams -WarningAction SilentlyContinue
        }
        catch [System.OperationCanceledException] {
            return
        }
        catch {
            Write-Warning "Unable to render the comic as $($Protocol): $_"
            return
        }

        if ($FullCacheKey) { $Cache[$FullCacheKey] = $TerminalImage }
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
