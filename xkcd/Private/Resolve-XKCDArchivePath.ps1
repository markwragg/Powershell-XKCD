function Resolve-XKCDArchivePath {
    <#
    .SYNOPSIS
        Resolves a path typed into Start-XKCD's secret admin console (e.g. "..", "2014/06", or "/2014")
        against the comic archive, relative to the current path. Returns $null if any segment along the
        way doesn't exist as a directory.
    #>
    [cmdletbinding()]
    Param(
        # The full set of cached comics to browse.
        [object[]]
        $Comic = @(),

        # The path to resolve from, as an array of segments. Ignored if -Target is an absolute path (starts
        # with "/").
        [string[]]
        $CurrentPath = @(),

        # The path typed by the user, e.g. "..", "2014/06", or "/2014".
        [Parameter(Mandatory)]
        [string]
        $Target
    )

    # Built up procedurally (rather than "$Working = if (...) {...} else {...}") because assigning the
    # output of an if/else directly unrolls an empty List[string] into $null instead of keeping the
    # (empty) list instance -- same pitfall as returning @() from a function without the comma operator.
    $Working = [System.Collections.Generic.List[string]]::new()
    if (-not $Target.StartsWith('/')) {
        $Working.AddRange([string[]]$CurrentPath)
    }

    $Segments = $Target -split '/' | Where-Object { $_ -and $_ -ne '.' }

    foreach ($Segment in $Segments) {
        if ($Segment -eq '..') {
            if ($Working.Count -gt 0) { $Working.RemoveAt($Working.Count - 1) }
        }
        else {
            $Entries = Get-XKCDArchiveEntry -Comic $Comic -Path $Working.ToArray()
            $UnusedRef = 0
            $Match = $Entries | Where-Object {
                $_.Type -eq 'Directory' -and (
                    $_.Name -eq $Segment -or (
                        [int]::TryParse($_.Name, [ref]$UnusedRef) -and [int]::TryParse($Segment, [ref]$UnusedRef) -and [int]$_.Name -eq [int]$Segment
                    )
                )
            } | Select-Object -First 1

            if (-not $Match) { return $null }
            $Working.Add($Match.Name)
        }
    }

    [pscustomobject]@{ Path = $Working.ToArray() }
}
