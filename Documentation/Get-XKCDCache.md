# Get-XKCDCache

## SYNOPSIS
Returns the details of comics @ https://xkcd.com/ from the local cache.

## SYNTAX

```
Get-XKCDCache [[-Num] <Int32[]>] [-CachePath <String>] [<CommonParameters>]
```

## DESCRIPTION
The Get-XKCDCache cmdlet returns comic data straight from the local cache, without querying the XKCD API
for each individual comic.
This makes it a much faster way to retrieve the details of comics that have
already been cached, and lets you use Where-Object, Sort-Object, Group-Object etc.
to query the whole set
of comics at once.

Unlike Find-XKCD, this cmdlet does not create or refresh the cache itself.
It only checks whether the
cache exists and is up to date, and warns you to run Update-XKCDCache if it isn't.

## EXAMPLES

### EXAMPLE 1
```
Get-XKCDCache
```

Returns every comic in the local cache.

### EXAMPLE 2
```
Get-XKCDCache -Num 4,5,6
```

Returns comics 4, 5 and 6 from the local cache.

### EXAMPLE 3
```
4,5,6 | Get-XKCDCache
```

Returns comics 4, 5 and 6 from the local cache, specified via the pipeline.

### EXAMPLE 4
```
Get-XKCDCache | Where-Object year -eq 2010
```

Returns every comic published in 2010, by filtering the full local cache.

### EXAMPLE 5
```
Get-XKCDCache | Sort-Object -Property { $_.title.Length } -Descending | Select-Object -First 1 title
```

Returns the comic with the longest title.

## PARAMETERS

### -Num
Returns only the specified comic numbers from the cache.
Accepts array and pipeline input.
By default every
cached comic is returned.

```yaml
Type: Int32[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -CachePath
Path to where comic data is cached.
By default this is within the module path, unless a default has
been saved with Set-XKCDDefault -CachePath.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: (Get-XKCDDefaultValue -Name 'CachePath' -Value (Join-Path $PSScriptRoot 'XKCD.json'))
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[https://xkcd.com/json.html](https://xkcd.com/json.html)

