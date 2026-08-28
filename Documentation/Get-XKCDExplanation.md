# Get-XKCDExplanation

## SYNOPSIS
Gets the explanation of a comic from the explain xkcd wiki: https://www.explainxkcd.com/.

## SYNTAX

```
Get-XKCDExplanation [[-Num] <Int32[]>] [-Transcript] [-Discussion] [-Full] [-Show] [-HighQuality]
 [-ApiUrl <String>] [<CommonParameters>]
```

## DESCRIPTION
The Get-XKCDExplanation cmdlet uses the explain xkcd wiki's MediaWiki API to retrieve a comic's
"Explanation" and "Transcript" sections, and its reader "Discussion" (from its explain xkcd talk page),
returning them as plain text, with the wiki markup used by the site stripped out for readability.
All
three are always included on the returned object, as its Explanation, Transcript, and Discussion
properties.

Use -Transcript and/or -Discussion with -Show (or on Show-XKCDExplanation) to also display the
transcript and discussion alongside the explanation, or -Full to display all three -- each section
shown is given its own heading.
These switches only affect what's displayed; the returned object always
has all three.

By default, Get-XKCDExplanation returns the explanation of the latest available comic.
When you use the
-Num parameter you can specify one or more specific comics to return.

## EXAMPLES

### EXAMPLE 1
```
Get-XKCDExplanation
```

This command gets the explanation of the latest XKCD comic.

### EXAMPLE 2
```
Get-XKCDExplanation 2000
```

This command returns the explanation of the 2000th XKCD comic.

### EXAMPLE 3
```
Get-XKCD -Random | Get-XKCDExplanation
```

This command gets a random comic and then returns its explanation.

### EXAMPLE 4
```
(Get-XKCDExplanation 2000).Transcript
```

This command returns just the transcript of comic number 2000.
The Explanation, Transcript, and
Discussion properties are always populated, so no switches are needed to retrieve them.

### EXAMPLE 5
```
Get-XKCDExplanation -Num 1 -Full -Show
```

This command displays the title, image, explanation, transcript, and discussion of comic number 1
directly in the console, each under its own heading (image display requires your terminal to support
the Sixel, Kitty, or iTerm2 inline image protocol).
Unlike other parameter combinations, -Show does not
return the explanation object.

## PARAMETERS

### -Num
Gets the explanation of the specified comics.
Accepts array input.
By default the latest comic is used.

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
Use with -Show to also display the comic's "Transcript" section.
The returned object always includes
it regardless of this switch.
Defaults to the value saved with Set-XKCDDefault -Transcript, if any.

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
Use with -Show to also display the comic's reader "Discussion", from its explain xkcd talk page.
The
returned object always includes it regardless of this switch.
Defaults to the value saved with
Set-XKCDDefault -Discussion, if any.

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
Use with -Show to display all of the explanation, transcript, and discussion sections.
The returned
object always includes all three regardless of this switch.
Defaults to the value saved with
Set-XKCDDefault -Full, if any.

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

### -Show
Displays the comic's title, image, and retrieved sections in the console instead of returning the
explanation object.
Image display requires your terminal to support the Sixel, Kitty, or iTerm2
inline image graphics protocol.

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

### -HighQuality
Use with -Show to display the higher resolution (_2x) version of the image, where available.
Comics
that do not have a higher resolution version are displayed at the standard quality instead.
Defaults
to the value saved with Set-XKCDDefault -HighQuality, if any.

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

### -ApiUrl
The base URL of the explain xkcd wiki's MediaWiki API.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Https://www.explainxkcd.com/wiki/api.php
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

