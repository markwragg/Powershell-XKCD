# Find-XKCD

## SYNOPSIS
Retrieves the details of comics @ https://xkcd.com/ based on whether a specified search string appears
in the title text.

## SYNTAX

```
Find-XKCD [-Query] <String> [-FullSearch] [-CachePath <String>] [<CommonParameters>]
```

## DESCRIPTION
The Find-XKCD cmdlet creates a local cache of the XKCD API comic data if one is not found to already
exist.
It also refreshes the local cache if it's found to be out of date.
Comic searches are then
performed against the local cache.

The query used is appended to the resulting comic objects as a NoteProperty called 'query'.
This allows you to group or filter the results by the search term.

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

### EXAMPLE 3
```
Find-XKCD -Query 'Spider' | Get-XKCD -Show
```

Returns any comics with the word 'Spider' in the title and then pipes the result to Get-XKCD which shows
them in the terminal, if supported.

### EXAMPLE 4
```
'romance','math' | Find-XKCD | Group query
```

Returns any comics with the word 'romance' or 'math' in the title and then groups the results by the search term.

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
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -FullSearch
Search the full text of the comic data, not just the title

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
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
Position: Named
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

