Function Get-XKCDComicMetaText {
    <#
    .SYNOPSIS
        Builds the dimmed "publish date - hyperlink" line shown under a comic's title in the console.
    #>
    [cmdletbinding()]
    Param(
        # The comic object returned by the xkcd API (must have a num property, and may have year, month, and day).
        [Parameter(Mandatory)]
        [pscustomobject]
        $Comic
    )

    $esc = [char]27

    $DateText = $null
    if ($Comic.year -and $Comic.month -and $Comic.day) {
        try {
            $Date = Get-Date -Year ([int]$Comic.year) -Month ([int]$Comic.month) -Day ([int]$Comic.day) -ErrorAction Stop
            $DateText = $Date.ToString('d MMMM yyyy')
        }
        catch {
            $DateText = $null
        }
    }

    $ComicUrl = "https://xkcd.com/$($Comic.num)"
    $Hyperlink = "$esc]8;;$ComicUrl$esc\$ComicUrl$esc]8;;$esc\"

    if ($DateText) { "$DateText - $Hyperlink" } else { $Hyperlink }
}
