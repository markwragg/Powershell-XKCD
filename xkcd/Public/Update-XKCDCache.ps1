Function Update-XKCDCache {
    <#
    .SYNOPSIS
        Updates the local cache of the XKCD API.

    .DESCRIPTION
        The Update-XKCDCache cmdlet updates the local cahce of the XKCD comic API with any new data from the server.
        The cahce is stored within the module script directory as XKCD.json.

    .PARAMETER CachePath
        Optional: Specify a path for where to create/update the XKCD cache. By default this is within the module path.

    .EXAMPLE
        Update-XKCDCache

        Updates the local XKCD.json file with full data from the XKCD API.

    .LINK
        https://xkcd.com/json.html
    #>
    [cmdletbinding(SupportsShouldProcess)]
    Param(
        [string]
        $CachePath = (Join-Path $PSScriptRoot 'XKCD.json')
    )

    $Max = (Invoke-RestMethod http://xkcd.com/info.0.json).num

    if (-not (Test-Path $CachePath)) {
        Write-Warning 'Local cache file not found. Recreating a local cache of the comic data. This might take a few minutes..'

        $AllComics = ForEach ($Comic in 1..$Max) {
            Write-Progress -Activity "Creating cache" -Status "Reading comic #$Comic" -PercentComplete (($Comic / $Max) * 100)
            Invoke-RestMethod "http://xkcd.com/$Comic/info.0.json"
        }
    
        $AllComics | ConvertTo-Json | Out-File $CachePath
    }
    Else {
        $AllComics = Get-Content $CachePath | ConvertFrom-Json
    }

    $LastComic = ($AllComics  | Sort-Object num -Descending | Select-Object -First 1).num

    If ($Max -gt $LastComic) {
        Write-Verbose 'Refreshing cache with latest comics'

        ForEach ($Comic in $LastComic..$Max) {
            Write-Progress -Activity "Refreshing cache" -Status "Reading comic #$Comic" -PercentComplete (($Comic / $Max) * 100)
            $AllComics += (Invoke-RestMethod "http://xkcd.com/$Comic/info.0.json")
        }

        $AllComics | ConvertTo-Json | Out-File $CachePath -Force
    }
}


