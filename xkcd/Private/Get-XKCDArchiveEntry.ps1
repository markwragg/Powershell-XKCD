function Get-XKCDArchiveEntry {
    <#
    .SYNOPSIS
        Returns the virtual filesystem entries at the given path within the comic archive, as presented by
        Start-XKCD's secret admin console (backtick) -- directories for /<year> and /<year>/<month>, and a
        "file" per comic (named "<num>.json") within a month.
    #>
    [cmdletbinding()]
    Param(
        # The full set of cached comics to browse (each must have num, title, year, month, and day properties).
        [object[]]
        $Comic = @(),

        # The current path, as an array of segments, e.g. @() for the root, @('2014'), or @('2014', '06').
        [string[]]
        $Path = @()
    )

    switch ($Path.Count) {
        0 {
            $Comic | Where-Object { $_.year } | Group-Object { [int]$_.year } | Sort-Object { [int]$_.Name } | ForEach-Object {
                [pscustomobject]@{ Name = $_.Name; Type = 'Directory' }
            }
        }
        1 {
            $Year = $Path[0]
            $Comic | Where-Object { $_.year -eq $Year } | Group-Object { [int]$_.month } | Sort-Object { [int]$_.Name } | ForEach-Object {
                [pscustomobject]@{ Name = ('{0:D2}' -f [int]$_.Name); Type = 'Directory' }
            }
        }
        2 {
            $Year, $Month = $Path
            $Comic | Where-Object { $_.year -eq $Year -and [int]$_.month -eq [int]$Month } | Sort-Object { [int]$_.num } | ForEach-Object {
                [pscustomobject]@{ Name = "$($_.num).json"; Type = 'File'; Comic = $_ }
            }
        }
        default { @() }
    }
}
