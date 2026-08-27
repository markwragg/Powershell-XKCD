Function Show-XKCDComic {
    <#
    .SYNOPSIS
        Displays a comic's title above its image and its alt text below, formatted for the console.
    #>
    [cmdletbinding()]
    Param(
        # The comic object returned by the xkcd API (must have num, title, and alt properties).
        [Parameter(Mandatory)]
        [pscustomobject]
        $Comic,

        # The raw bytes of the comic image (e.g. PNG or JPEG).
        [Parameter(Mandatory)]
        [byte[]]
        $ImageBytes
    )

    try {
        $esc = [char]27
        $bold = "$esc[1m"
        $italic = "$esc[3m"
        $reset = "$esc[0m"
        $newLine = [Environment]::NewLine

        $width = 80
        try {
            if ([Console]::WindowWidth -gt 0) { $width = [Console]::WindowWidth }
        }
        catch {
            Write-Verbose 'No console window available (e.g. output redirected), falling back to the default width'
        }

        [Console]::Out.Write($newLine)
        [Console]::Out.Write("$bold#$($Comic.num): $($Comic.title)$reset")
        [Console]::Out.Write($newLine + $newLine)

        Show-XKCDImage -ImageBytes $ImageBytes

        $words = $Comic.alt -split '\s+'
        $lines = [System.Collections.Generic.List[string]]::new()
        $currentLine = ''

        foreach ($word in $words) {
            if (-not $currentLine) {
                $currentLine = $word
            }
            elseif (($currentLine.Length + 1 + $word.Length) -le $width) {
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
        [Console]::Out.Write($newLine + $newLine)
    }
    catch {
        # Console access can fail in non-interactive/headless hosts (e.g. CI build agents) in ways that vary by
        # environment. Displaying a comic is inherently best-effort there, so degrade to a warning rather than throw.
        Write-Warning "Unable to display the comic in this console: $_"
    }
}
