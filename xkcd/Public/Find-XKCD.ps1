Function Find-XKCD {
    <#
    .SYNOPSIS
        Retrieves the details of comics @ http://xkcd.com/ based on whether a specified search string appears
        in the title text.

    .DESCRIPTION
        The Find-XKCD cmdlet creates a local cache of the XKCD API comic data if one is not found to already
        exist. It also refreshes the local cache if it's found to be out of date. Comic searches are then
        performed against the local cache.

    .EXAMPLE
        PS> Find-XKCD -Query 'Spider'
        
    .LINK
        https://xkcd.com/json.html
    #>
    Param(
        [Parameter(Mandatory)]
        [string]
        $Query
    )
    
    $CachePath = Join-Path $PSScriptRoot 'XKCD.json'
    $Max = (Invoke-RestMethod http://xkcd.com/info.0.json).num

    if (-not (Test-Path $CachePath)) {
        Write-Warning 'Creating a local cache of the comic data. This might take a few minutes..'

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

    $AllComics | Where-Object { $_.Title -like "*$Query*" }
}


