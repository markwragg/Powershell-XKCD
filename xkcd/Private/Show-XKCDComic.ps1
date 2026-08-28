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
        $titleStyle = "$esc[1;4;96m"
        $dim = "$esc[2m"
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
        [Console]::Out.Write("$titleStyle#$($Comic.num): $($Comic.title)$reset")
        [Console]::Out.Write($newLine + $newLine)

        $MetaText = Get-XKCDComicMetaText -Comic $Comic

        [Console]::Out.Write("$dim$MetaText$reset")
        [Console]::Out.Write($newLine + $newLine)

        Show-XKCDComicImage -Comic $Comic -ImageBytes $ImageBytes -Width $width
    }
    catch {
        # Console access can fail in non-interactive/headless hosts (e.g. CI build agents) in ways that vary by
        # environment. Displaying a comic is inherently best-effort there, so degrade to a warning rather than throw.
        Write-Warning "Unable to display the comic in this console: $_"
    }
}
