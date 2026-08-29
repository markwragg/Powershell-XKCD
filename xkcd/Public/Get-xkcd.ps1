function Get-XKCD {
    <#
    .SYNOPSIS
        Gets the details of the comics @ https://xkcd.com/. Optionally can download the comic images.

    .DESCRIPTION
        The Get-XKCD cmdlet gets the details of one or more comics from the XKCD API: https://xkcd.com/json.html.
        This includes title, number, image URL, alt text, day, month, year, news, safe_title and transcript.

        By default, Get-XKCD returns the details of the latest available comic. When you use the -num parameter
        you can specify one or more specific comics to return.

        When used with -Show, each displayed comic updates a local state file with two records: the highest-
        numbered comic you've ever viewed, used by Test-XKCD to report how many new comics have been published
        since you last checked; and the comic you most recently displayed in either direction, used by -Next and
        -Previous so you can page back and forth through comics sequentially. -Next returns nothing once you've
        reached the latest comic, and -Previous returns nothing once you've reached comic #1.

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
        Get-XKCD -Next

        This command returns the details of the comic after the one you most recently displayed with Show-XKCD or
        Get-XKCD -Show, as recorded in the state file. Returns nothing if you're already at the latest comic.

    .EXAMPLE
        Get-XKCD -Previous

        This command returns the details of the comic before the one you most recently displayed with Show-XKCD or
        Get-XKCD -Show, as recorded in the state file. Returns nothing if you're already at comic #1.

    .EXAMPLE
        Get-XKCD -Download

        This command returns the details of the latest comic and downloads the comic image to the current working directory.

    .EXAMPLE
        Get-XKCD (1..10) -Download -Path C:\Comics

        This command returns the details of comic numbers 1 to 10 and downloads each comics image to C:\Comics.

    .EXAMPLE
        Get-XKCD -Download -HighQuality

        This command returns the details of the latest comic and downloads the higher resolution (_2x) version of the
        image, if one is available. Older comics that do not have a higher resolution version are downloaded at the
        standard quality instead.

    .EXAMPLE
        Get-XKCD -Show

        This command displays the title, image, and alt text of the latest comic directly in the console (image
        display requires your terminal to support the Sixel, Kitty, or iTerm2 inline image protocol). Unlike other
        parameter combinations, -Show does not return the comic object.

    .EXAMPLE
        Get-XKCD -Explain

        This command displays the explanation of the latest comic directly in the console, via
        Show-XKCDExplanation. Unlike other parameter combinations, -Explain does not return the comic object.

    .EXAMPLE
        1..10 | % { Get-XKCD -Random | select num,img } | FT -AutoSize

        This command returns the details of 10 random comics from the set of all comics and displays the number and image URL of those comics as an autosized table.

    .LINK
        https://xkcd.com/json.html
    #>
    [cmdletbinding(DefaultParameterSetName = 'Specific', SupportsShouldProcess = $true)]
    Param (
        # Gets a random comic.
        [Parameter(ParameterSetName = 'Random', Mandatory)]
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

        # Gets the comic after the one most recently displayed with Show-XKCD or Get-XKCD -Show, as recorded in
        # the state file. Returns nothing if you're already at the latest comic.
        [Parameter(ParameterSetName = 'Next', Mandatory)]
        [switch]
        $Next,

        # Gets the comic before the one most recently displayed with Show-XKCD or Get-XKCD -Show, as recorded in
        # the state file. Returns nothing if you're already at comic #1.
        [Parameter(ParameterSetName = 'Previous', Mandatory)]
        [switch]
        $Previous,

        # Downloads the images of all returned comics to the local computer.
        [switch]
        $Download,

        # Opens the comic/s in your default web browser
        [switch]
        $Open,

        # Displays the comic's title, image, and alt text in the console instead of returning the comic object. Image
        # display requires your terminal to support the Sixel, Kitty, or iTerm2 inline image graphics protocol.
        [switch]
        $Show,

        # Displays the comic's explanation in the console via Show-XKCDExplanation, instead of returning the comic
        # object.
        [switch]
        $Explain,

        # Use with -Download to specify a local directory to download to. By default this is the current working
        # directory, unless a default has been saved with Set-XKCDDefault -Path.
        [string]
        $Path = (Get-XKCDDefaultValue -Name 'Path' -Value $PWD),

        # Use with -Download to download the higher resolution (_2x) version of the image, where available. Comics
        # that do not have a higher resolution version are downloaded at the standard quality instead. Defaults to
        # the value saved with Set-XKCDDefault -HighQuality, if any.
        [switch]
        $HighQuality = (Get-XKCDDefaultValue -Name 'HighQuality' -Value $false),

        # Use with -Show to specify the file used to track the number of the most recently viewed comic (used by
        # Test-XKCD). By default this is within the module path, unless a default has been saved with
        # Set-XKCDDefault -StatePath.
        [string]
        $StatePath = (Get-XKCDDefaultValue -Name 'StatePath' -Value (Join-Path $PSScriptRoot 'XKCD.state.json')),

        # Gets the specified comics. Accepts array input.
        [Parameter(ParameterSetName = 'Specific', ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [int[]]
        $Num = $Max,

        # Bypass the confirmation check if you try to open more than 9 comics in your browser.
        [switch]
        $Force
    )
    Begin {
        if (-not $Max) { $Max = (Invoke-RestMethod "https://xkcd.com/info.0.json").num }

        if ($Random) {
            $Num = Get-Random -min $Min -max $Max
        }
        elseif ($Newest) {
            $Num = (($Max - $Newest) + 1)..$Max
        }
        elseif ($Next) {
            $NextNum = (Get-XKCDLastReadComic -StatePath $StatePath) + 1
            if ($NextNum -le $Max) { $Num = $NextNum } else { $Num = @() }
        }
        elseif ($Previous) {
            $LastRead = Get-XKCDLastReadComic -StatePath $StatePath
            if ($LastRead -gt 1) { $Num = $LastRead - 1 } else { $Num = @() }
        }
        elseif (-not $Num) {
            $Num = $Max
        }
    }
    Process {
        $Num | ForEach-Object {
            $ID = $_
            $Comic = Invoke-RestMethod "https://xkcd.com/$ID/info.0.json"
            $Extension = [System.IO.Path]::GetExtension(([uri]$Comic.img).AbsolutePath)
            $ImageUrl = $Comic.img

            if ($Download -and $HighQuality) {
                $ImageUrl = $Comic.img.Insert($Comic.img.LastIndexOf($Extension), '_2x')
            }

            if ($Download -and $PSCmdlet.ShouldProcess($ImageUrl, "Save as ${ID}${Extension}")) {
                $OutFile = Join-Path $Path "${ID}${Extension}"
                try {
                    Invoke-WebRequest $ImageUrl -OutFile $OutFile -UseBasicParsing -ErrorAction Stop
                }
                catch {
                    if ($HighQuality) {
                        Write-Warning "High quality image not available for comic $ID, downloading standard quality instead"
                        Invoke-WebRequest $Comic.img -OutFile $OutFile -UseBasicParsing
                    }
                    else {
                        throw
                    }
                }
            }

            if ($Show) {
                Show-XKCD -Num $ID -HighQuality:$HighQuality -StatePath $StatePath
            }

            if ($Explain) {
                Show-XKCDExplanation -Num $ID -HighQuality:$HighQuality
            }

            if ($Open) {
                if ($Num.count -ge 10 -and -not $Force) {
                    if (-not $confirmation) { $confirmation = Read-Host "This will open $($Num.count) comics in your default browser. Are you sure you want to proceed? [y|n]" }
                }
                if ($confirmation -eq 'y' -or $Num.count -lt 10 -or $Force) {
                    Start-Process "https://xkcd.com/$ID"
                }
            }

            if (-not $Show -and -not $Explain) {
                return $Comic
            }
        }
    }
}