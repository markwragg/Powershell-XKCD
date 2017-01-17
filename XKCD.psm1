Function Get-XKCD{
    [cmdletbinding(DefaultParameterSetName=’Specific’)]
    Param (
        [Parameter(ParameterSetName=’Random’)][switch]$Random,
        [Parameter(ParameterSetName=’Random’)][int]$Min = 1,
        [Parameter(ParameterSetName=’Random’)][int]$Max = (Invoke-RestMethod "http://xkcd.com/info.0.json").num,        
        [Parameter(ParameterSetName=’Newest’)][int]$Newest,
        [switch]$Download,
        [ValidateScript({Test-Path $_ -PathType ‘Container’})] 
        [string]$Path = $PWD,
        [Parameter(ParameterSetName=’Specific’,ValueFromPipeline=$True,Position=0)][int[]]$Num = $Max     
    )
    Begin{
        If ($Random) { $Num = Get-Random -min $Min -max $Max }
        If ($Newest) { $Num = (($Max - $Newest) + 1)..$Max }
    }
    Process{
        $Num | ForEach-Object { 
            $Comic = Invoke-RestMethod "http://xkcd.com/$_/info.0.json"
            $Comic

            If ($Download) { Invoke-WebRequest $Comic.img -OutFile $(Join-Path $Path "$_.jpg") }
        }
    }
}
