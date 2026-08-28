# Get-XKCDDefault

## SYNOPSIS
Gets the default preferences saved by Set-XKCDDefault.

## SYNTAX

```
Get-XKCDDefault [[-DefaultsPath] <String>] [<CommonParameters>]
```

## DESCRIPTION
The Get-XKCDDefault cmdlet returns the default preferences currently saved by Set-XKCDDefault, such as
whether -HighQuality is used by default.
Preferences that haven't been saved are omitted -- each
cmdlet that honours a preference falls back to its own built-in behavior when one isn't saved here.

## EXAMPLES

### EXAMPLE 1
```
Get-XKCDDefault
```

Returns the currently saved default preferences.

## PARAMETERS

### -DefaultsPath
Path to the file used to store default preferences.
By default this is within the module path.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: (Join-Path $PSScriptRoot 'XKCD.defaults.json')
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

