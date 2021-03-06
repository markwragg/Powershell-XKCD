﻿Function Get-XKCD {
    <#
    .SYNOPSIS
        Gets the details of the comics @ http://xkcd.com/. Optionally can download the comic images.

    .DESCRIPTION
        The Get-XKCD cmdlet gets the details of one or more comics from the XKCD API: https://xkcd.com/json.html.
        This includes title, number, image URL, alt text, day, month, year, news, safe_title and transcript.

        By default, Get-XKCD returns the details of the latest available comic. When you use the -num parameter
        you can specify one or more specific comics to return.

    .EXAMPLE
        Get-XKCD

        This command gets the details of the latest XKCD comic from the API such as the title, number, image URL and alt text.

    .EXAMPLE
        Get-XKCD 42

        This command returns the details of the 42nd XKCD comic.

    .EXAMPLE
        Get-XKCD -Random

        This command returns the details of a random XKCD comic from the set of all available comics.

    .EXAMPLE
        Get-XKCD -Random -Min 100 -Max 150

        This command returns a random comic that is numbered between 100 and 150.

    .EXAMPLE
        Get-XKCD -Newest 5

        This command returns the details of the latest 5 comics.

    .EXAMPLE
        Get-XKCD -Download

        This command returns the details of the latest comic and downloads the comic image to the current working directory.

    .EXAMPLE
        Get-XKCD (1..10) -Download -Path C:\Comics

        This command returns the details of comic numbers 1 to 10 and downloads each comics image to C:\Comics.

    .EXAMPLE
        1..10 | % { Get-XKCD -Random | select num,img } | FT -AutoSize

        This command returns the details of 10 random comics from the set of all comics and displays the number and image URL of those comics as an autosized table.

    .LINK
        https://xkcd.com/json.html
    #>
    [cmdletbinding(DefaultParameterSetName = 'Specific', SupportsShouldProcess = $true)]
    Param (
        # Gets a random comic.
        [Parameter(ParameterSetName = 'Random')]
        [switch]
        $Random,

        # Use with -Random to define a lower bound range within which to return a comic.
        [Parameter(ParameterSetName = 'Random')]
        [int]
        $Min = 1,

        # Use with -Random to define an upper bound range within which to return a comic. -Max is the latest comic number by default.
        [Parameter(ParameterSetName = 'Random')
        ][int]
        $Max,

        # Gets the specified number of the most recent comics.
        [Parameter(ParameterSetName = 'Newest')]
        [int]
        $Newest,

        # Downloads the images of all returned comics to the local computer.
        [switch]
        $Download,

        # Opens the comic/s in your default web browser
        [switch]
        $Open,

        # Use with -Download to specify a local directory to download to. By default this is the current working directory.
        [string]
        $Path = $PWD,

        # Gets the specified comics. Accepts array input.
        [Parameter(ParameterSetName = 'Specific', ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [int[]]
        $Num = $Max,

        # Bypass the confirmation check if you try to open more than 9 comics in your browser.
        [switch]
        $Force
    )
    Begin {
        If (-not $Max) { $Max = (Invoke-RestMethod "http://xkcd.com/info.0.json").num }
        If ($Random)   { $Num = Get-Random -min $Min -max $Max }
        If ($Newest)   { $Num = (($Max - $Newest) + 1)..$Max }
        If (-not $Num) { $Num = $Max }
    }
    Process {
        $Num | ForEach-Object {
            $Comic = Invoke-RestMethod "http://xkcd.com/$_/info.0.json"
            If ($Download -and $PSCmdlet.ShouldProcess($Comic.img, "Save as $_.jpg")) { 
                Invoke-WebRequest $Comic.img -OutFile $(Join-Path $Path "$_.jpg") 
            }
            if ($Open) {
                if ($Num.count -ge 10 -and -not $Force) {
                    if (-not $confirmation) { $confirmation = Read-Host "This will open $($Num.count) comics in your default browser. Are you sure you want to proceed? [y|n]" }
                }
                if ($confirmation -eq 'y' -or $Num.count -lt 10 -or $Force) {
                    Start-Process "http://xkcd.com/$_"
                }
            }
            Return $Comic
        }
    }
}