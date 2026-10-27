function Invoke-XKCDAdminCommand {
    <#
    .SYNOPSIS
        Parses and runs a single command line typed into Start-XKCD's secret admin console (backtick),
        against a virtual filesystem view of the comic archive -- /<year>/<month>/<num>.json. Pure
        input/output: takes the current path and a line of text, and returns what happened, without touching
        the console itself (so it can be unit tested without mocking any console I/O).

    .DESCRIPTION
        Supports: ls/dir, cd, pwd, cat, open/view, help, clear/cls, whoami, sudo, and exit/quit/q. Anything
        else is reported the same way an unrecognised command would be by a real shell.
    #>
    [cmdletbinding()]
    Param(
        # The full set of cached comics to browse.
        [object[]]
        $Comic = @(),

        # The current path, as an array of segments, e.g. @() for the root, @('2014'), or @('2014', '06').
        [string[]]
        $Path = @(),

        # The raw line of text typed at the prompt.
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]
        $Line
    )

    $Output = [System.Collections.Generic.List[string]]::new()
    $NewPath = $Path
    $Exit = $false
    $Jump = $null

    $Tokens = @($Line.Trim() -split '\s+' | Where-Object { $_ })

    if ($Tokens.Count -gt 0) {
        $Command = $Tokens[0].ToLowerInvariant()
        $Arg = if ($Tokens.Count -gt 1) { $Tokens[1] } else { $null }

        switch ($Command) {
            { $_ -in 'exit', 'quit', 'q' } {
                $Exit = $true
            }

            'help' {
                $Output.AddRange([string[]]@(
                        'ls              List the contents of the current directory'
                        'cd <dir>        Change directory (.. for up, / for root)'
                        'pwd             Print the current directory'
                        'cat <file>      Print a comic''s raw data'
                        'open <file>     Jump to viewing a comic and exit the console'
                        'clear           Clear the screen'
                        'exit            Return to the comic viewer'
                    ))
            }

            'pwd' {
                $Output.Add($(if ($Path.Count -eq 0) { '/' } else { '/' + ($Path -join '/') }))
            }

            { $_ -in 'clear', 'cls' } {
                try { [Console]::Clear() } catch { Write-Verbose 'Unable to clear the console (e.g. output redirected); continuing without clearing.' }
            }

            'whoami' {
                $Output.Add('root')
            }

            'sudo' {
                $Output.Add('You are already root. There is no higher power here.')
            }

            { $_ -in 'ls', 'dir' } {
                $ListPath = $Path
                if ($Arg) {
                    $Resolved = Resolve-XKCDArchivePath -Comic $Comic -CurrentPath $Path -Target $Arg
                    if ($null -eq $Resolved) {
                        $Output.Add("ls: ${Arg}: No such file or directory")
                        $ListPath = $null
                    }
                    else {
                        $ListPath = $Resolved.Path
                    }
                }

                if ($null -ne $ListPath) {
                    $Entries = @(Get-XKCDArchiveEntry -Comic $Comic -Path $ListPath)
                    if ($Entries.Count -eq 0) {
                        $Output.Add('(empty)')
                    }
                    else {
                        foreach ($Entry in $Entries) {
                            if ($Entry.Type -eq 'Directory') {
                                $Output.Add("$($Entry.Name)/")
                            }
                            else {
                                $Output.Add("$($Entry.Name)`t$($Entry.Comic.title)")
                            }
                        }
                    }
                }
            }

            'cd' {
                if (-not $Arg) {
                    $NewPath = @()
                }
                else {
                    $Resolved = Resolve-XKCDArchivePath -Comic $Comic -CurrentPath $Path -Target $Arg
                    if ($null -eq $Resolved) {
                        $Output.Add("cd: ${Arg}: No such file or directory")
                    }
                    else {
                        $NewPath = $Resolved.Path
                    }
                }
            }

            { $_ -in 'cat', 'open', 'view' } {
                if (-not $Arg) {
                    $Output.Add("${Command}: missing file operand")
                }
                else {
                    $File = Get-XKCDArchiveEntry -Comic $Comic -Path $Path | Where-Object {
                        $_.Type -eq 'File' -and ($_.Name -eq $Arg -or $_.Name -eq "$Arg.json")
                    } | Select-Object -First 1

                    if (-not $File) {
                        $Output.Add("${Command}: ${Arg}: No such file or directory")
                    }
                    elseif ($Command -eq 'cat') {
                        $Json = $File.Comic | Select-Object num, title, year, month, day, img, alt | ConvertTo-Json
                        $Output.AddRange([string[]]($Json -split "`r?`n"))
                    }
                    else {
                        $Output.Add("Jumping to comic #$($File.Comic.num)...")
                        $Jump = [int]$File.Comic.num
                        $Exit = $true
                    }
                }
            }

            default {
                $Output.Add("${Command}: command not found")
            }
        }
    }

    [pscustomobject]@{
        Output = $Output.ToArray()
        Path   = $NewPath
        Exit   = $Exit
        Jump   = $Jump
    }
}
