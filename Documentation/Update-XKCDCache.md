# Update-XKCDCache

## SYNOPSIS
Updates the local cache of the XKCD API.

## SYNTAX

```
Update-XKCDCache [[-CachePath] <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The Update-XKCDCache cmdlet updates the local cahce of the XKCD comic API with any new data from the server.
The cahce is stored within the module script directory as XKCD.json.

## EXAMPLES

### EXAMPLE 1
```
Update-XKCDCache
```

Updates the local XKCD.json file with full data from the XKCD API.

## PARAMETERS

### -CachePath
Optional: Specify a path for where to create/update the XKCD cache.
By default this is within the module path.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: (Join-Path $PSScriptRoot 'XKCD.json')
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
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

