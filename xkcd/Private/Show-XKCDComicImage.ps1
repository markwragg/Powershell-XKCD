function Show-XKCDComicImage {
    <#
    .SYNOPSIS
        Displays a comic's image and its word-wrapped alt text below it, formatted for the console.
    #>
    [cmdletbinding(DefaultParameterSetName = 'Bytes')]
    Param(
        # The comic object returned by the xkcd API, used for its optional alt property. May be omitted if only
        # the image itself (with no alt text below it) should be shown.
        [pscustomobject]
        $Comic,

        # The raw bytes of the comic image (e.g. PNG or JPEG), rendered via Show-XKCDImage.
        [Parameter(Mandatory, ParameterSetName = 'Bytes')]
        [byte[]]
        $ImageBytes,

        # A previously rendered terminal graphics escape sequence (e.g. from Export-XKCDTerminalImage), written
        # to the console as-is instead of being rendered from raw image bytes.
        [Parameter(Mandatory, ParameterSetName = 'TerminalImage')]
        [string]
        $TerminalImage,

        # The console width to wrap the alt text to.
        [int]
        $Width = 80
    )

    $esc = [char]27
    $italic = "$esc[3m"
    $reset = "$esc[0m"
    $newLine = [Environment]::NewLine

    if ($PSCmdlet.ParameterSetName -eq 'TerminalImage') {
        [Console]::Out.Write($TerminalImage)
        [Console]::Out.Write($newLine)
    }
    else {
        Show-XKCDImage -ImageBytes $ImageBytes
    }

    if ($Comic.alt) {
        $words = $Comic.alt -split '\s+'
        $lines = [System.Collections.Generic.List[string]]::new()
        $currentLine = ''

        foreach ($word in $words) {
            if (-not $currentLine) {
                $currentLine = $word
            }
            elseif (($currentLine.Length + 1 + $word.Length) -le $Width) {
                $currentLine = "$currentLine $word"
            }
            else {
                $lines.Add($currentLine)
                $currentLine = $word
            }
        }
        if ($currentLine) { $lines.Add($currentLine) }

        [Console]::Out.Write($newLine)
        [Console]::Out.Write("$italic$($lines -join $newLine)$reset")
        [Console]::Out.Write($newLine)
    }

    [Console]::Out.Write($newLine)
}
