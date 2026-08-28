# Show-XKCD

## SYNOPSIS
Displays a comic's title, image, and alt text in the console.

## SYNTAX

```
Show-XKCD [[-Num] <Int32[]>] [-HighQuality] [-StatePath <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The Show-XKCD cmdlet gets and displays a comic in the console: the title above, the image (if your
terminal supports the Sixel, Kitty, or iTerm2 inline image graphics protocol), and the alt text below.

By default, Show-XKCD displays the latest available comic.
When you use the -Num parameter you can
specify one or more specific comics to display.

Each displayed comic updates a local record of the most recently viewed comic, used by Test-XKCD to
report how many new comics have been published since you last checked.

## EXAMPLES

### EXAMPLE 1
```
Show-XKCD
```

Displays the latest comic.

### EXAMPLE 2
```
Show-XKCD 2000
```

Displays comic number 2000.

### EXAMPLE 3
```
Get-XKCD -Random | Show-XKCD
```

Gets a random comic and displays it in the console.

### EXAMPLE 4
```
Find-XKCD -Query 'Spider' | Get-XKCD | Show-XKCD
```

Finds comics with 'Spider' in the title and displays each one in the console.

### EXAMPLE 5
```
Get-XKCD -Show
```

Shorthand equivalent of: Get-XKCD | Show-XKCD

## PARAMETERS

### -Num
Displays the specified comics.
Accepts array input.
By default the latest comic is displayed.

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

### -HighQuality
Displays the higher resolution (_2x) version of the image, where available.
Comics that do not have a
higher resolution version are displayed at the standard quality instead.
Defaults to the value saved
with Set-XKCDDefault -HighQuality, if any.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: (Get-XKCDDefaultValue -Name 'HighQuality' -Value $false)
Accept pipeline input: False
Accept wildcard characters: False
```

### -StatePath
Path to the file used to track the number of the most recently viewed comic (used by Test-XKCD).
By
default this is within the module path, unless a default has been saved with Set-XKCDDefault -StatePath.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: (Get-XKCDDefaultValue -Name 'StatePath' -Value (Join-Path $PSScriptRoot 'XKCD.state.json'))
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

