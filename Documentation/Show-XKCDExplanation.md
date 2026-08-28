# Show-XKCDExplanation

## SYNOPSIS
Displays a comic's title, image, and explanation in the console.

## SYNTAX

```
Show-XKCDExplanation [[-Num] <Int32[]>] [-Transcript] [-Discussion] [-Full] [-HighQuality] [<CommonParameters>]
```

## DESCRIPTION
The Show-XKCDExplanation cmdlet gets a comic's explanation from the explain xkcd wiki (via
Get-XKCDExplanation) and displays it in the console: the title above, the image (if your terminal
supports the Sixel, Kitty, or iTerm2 inline image graphics protocol), and the retrieved sections below.

Use -Transcript and/or -Discussion to also display the comic's transcript and reader discussion, or
-Full to display all three.
When more than one section is displayed, each is shown under its own
heading.

By default, Show-XKCDExplanation displays the explanation of the latest available comic.
When you use
the -Num parameter you can specify one or more specific comics to display.

## EXAMPLES

### EXAMPLE 1
```
Show-XKCDExplanation
```

Displays the explanation of the latest comic.

### EXAMPLE 2
```
Show-XKCDExplanation 2000
```

Displays the explanation of comic number 2000.

### EXAMPLE 3
```
Get-XKCD -Random | Show-XKCDExplanation
```

Gets a random comic and displays its explanation in the console.

### EXAMPLE 4
```
Show-XKCDExplanation 2000 -Full
```

Displays the explanation, transcript, and reader discussion of comic number 2000, each under its own heading.

### EXAMPLE 5
```
Get-XKCDExplanation -Show
```

Shorthand equivalent of: Get-XKCDExplanation | Show-XKCDExplanation

## PARAMETERS

### -Num
Displays the explanation of the specified comics.
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

### -Transcript
Also displays the comic's "Transcript" section.
Defaults to the value saved with
Set-XKCDDefault -Transcript, if any.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: (Get-XKCDDefaultValue -Name 'Transcript' -Value $false)
Accept pipeline input: False
Accept wildcard characters: False
```

### -Discussion
Also displays the comic's reader "Discussion", from its explain xkcd talk page.
Defaults to the value
saved with Set-XKCDDefault -Discussion, if any.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: (Get-XKCDDefaultValue -Name 'Discussion' -Value $false)
Accept pipeline input: False
Accept wildcard characters: False
```

### -Full
Displays all of the explanation, transcript, and discussion sections.
Defaults to the value saved
with Set-XKCDDefault -Full, if any.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: (Get-XKCDDefaultValue -Name 'Full' -Value $false)
Accept pipeline input: False
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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[https://www.explainxkcd.com/wiki/index.php/Main_Page](https://www.explainxkcd.com/wiki/index.php/Main_Page)

