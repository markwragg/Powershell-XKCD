# Find-XKCD

## SYNOPSIS
Retrieves the details of comics @ http://xkcd.com/ based on whether a specified search string appears
in the title text.

## SYNTAX

```
Find-XKCD [-Query] <String> [[-CachePath] <String>] [<CommonParameters>]
```

## DESCRIPTION
The Find-XKCD cmdlet creates a local cache of the XKCD API comic data if one is not found to already
exist.
It also refreshes the local cache if it's found to be out of date.
Comic searches are then
performed against the local cache.

## EXAMPLES

### EXAMPLE 1
```
Find-XKCD -Query 'Spider' | Format-Table
```

Returns any comics with the word 'Spider' in the title as a table.

### EXAMPLE 2
```
Find-XKCD -Query 'Spider' | Get-XKCD -Open
```

Returns any comics with the word 'Spider' in the title and then pipes the result to Get-XKCD which opens
them in the default browser.

## PARAMETERS

### -Query
The search string to find

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CachePath
Path to where comic data is cached

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: (Join-Path $PSScriptRoot 'XKCD.json')
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

