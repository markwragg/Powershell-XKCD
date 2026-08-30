# Show-XKCDExplanation

## SYNOPSIS
Displays a comic's title, image, and explanation in the console.

## SYNTAX

```
Show-XKCDExplanation [[-Num] <Int32[]>] [-Explanation] [-Transcript] [-Discussion] [-Full] [-HighQuality]
 [<CommonParameters>]
```

## DESCRIPTION
The Show-XKCDExplanation cmdlet gets a comic's explanation from the explain xkcd wiki (via
Get-XKCDExplanation) and displays it in the console: the title above, the image (if your terminal
supports the Sixel, Kitty, or iTerm2 inline image graphics protocol), and the retrieved sections below.

By default, only the explanation is displayed.
Use -Explanation, -Transcript, and/or -Discussion to
choose exactly which section(s) to display instead -- e.g.
-Transcript on its own displays just the
transcript, not the explanation -- or use -Full to always display all three.
Each displayed section is
shown under its own heading.

By default, Show-XKCDExplanation also displays the comic itself (its title, image, and alt text) above
the section(s) shown.
Use -Explanation, -Transcript, and/or -Discussion (without -Full) to display text
sections only, without fetching or showing the comic image -- the title and a link to the explanation
are still shown.
Use -Full to always display the comic image alongside every section.

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

Displays the comic image, explanation, transcript, and reader discussion of comic number 2000, each
under its own heading.

### EXAMPLE 5
```
Show-XKCDExplanation 2000 -Explanation
```

Displays just the explanation of comic number 2000 as text, along with its title and a link, without
fetching or displaying the comic image.

### EXAMPLE 6
```
Show-XKCDExplanation 2000 -Discussion
```

Displays just the reader discussion of comic number 2000 as text, along with its title and a link,
without fetching or displaying the comic image or the explanation.

### EXAMPLE 7
```
Show-XKCDExplanation 2000 -Explanation -Discussion
```

Displays the explanation and reader discussion (but not the transcript) of comic number 2000 as text,
along with its title and a link, without fetching or displaying the comic image.

### EXAMPLE 8
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

### -Explanation
Displays the comic's "Explanation" section.
Combine with -Transcript and/or -Discussion to display more
than one section; on its own (without -Full), no comic image is fetched or displayed -- the title and
a link to the explanation are still shown.
Defaults to the value saved with Set-XKCDDefault
-Explanation, if any.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: (Get-XKCDDefaultValue -Name 'Explanation' -Value $false)
Accept pipeline input: False
Accept wildcard characters: False
```

### -Transcript
Displays the comic's "Transcript" section.
Combine with -Explanation and/or -Discussion to display more
than one section; on its own (without -Full), no comic image is fetched or displayed.
Defaults to the
value saved with Set-XKCDDefault -Transcript, if any.

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
Displays the comic's reader "Discussion", from its explain xkcd talk page.
Combine with -Explanation
and/or -Transcript to display more than one section; on its own (without -Full), no comic image is
fetched or displayed.
Defaults to the value saved with Set-XKCDDefault -Discussion, if any.

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

