function Update-XKCDLastReadState {
    <#
    .SYNOPSIS
        Updates the given state file's LastRead record to the specified comic number, used by Get-XKCD and
        Show-XKCD's -Next/-Previous to page back and forth through comics sequentially. Also raises LastViewed
        to match, if the comic is higher-numbered than the current high-water mark, used by Test-XKCD to report
        how many new comics have been published since you last checked. Does nothing if the state already
        reflects this comic.
    #>
    [cmdletbinding(SupportsShouldProcess)]
    Param(
        # The comic number most recently displayed or retrieved.
        [Parameter(Mandatory)]
        [int]
        $Num,

        # Path to the file used to track the number of the most recently viewed/read comic.
        [Parameter(Mandatory)]
        [string]
        $StatePath,

        # The calling cmdlet's $PSCmdlet, used to honor its -WhatIf/-Confirm state via ShouldProcess.
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCmdlet]
        $Cmdlet
    )

    $LastViewedComic = Get-XKCDLastViewedComic -StatePath $StatePath
    $LastReadComic = Get-XKCDLastReadComic -StatePath $StatePath
    $NewLastViewed = [math]::Max($LastViewedComic, $Num)

    if (($Num -ne $LastReadComic -or $NewLastViewed -ne $LastViewedComic) -and
        $Cmdlet.ShouldProcess($StatePath, "Update last read comic to #$Num")) {
        [pscustomobject]@{ LastViewed = $NewLastViewed; LastRead = $Num } | ConvertTo-Json | Out-File $StatePath -Force
    }
}
