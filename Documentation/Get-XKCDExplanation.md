# Get-XKCDExplanation

## SYNOPSIS
Gets the explanation of a comic from the explain xkcd wiki: https://www.explainxkcd.com/.

## SYNTAX

### Specific (Default)
```
Get-XKCDExplanation [-Open] [-Explanation] [-Transcript] [-Discussion] [-Full] [-Show] [-HighQuality]
 [-ApiUrl <String>] [[-Num] <Int32[]>] [-Force] [<CommonParameters>]
```

### Random
```
Get-XKCDExplanation [-Random] [-Min <Int32>] [-Max <Int32>] [-Open] [-Explanation] [-Transcript] [-Discussion]
 [-Full] [-Show] [-HighQuality] [-ApiUrl <String>] [-Force] [<CommonParameters>]
```

### Newest
```
Get-XKCDExplanation [-Newest <Int32>] [-Open] [-Explanation] [-Transcript] [-Discussion] [-Full] [-Show]
 [-HighQuality] [-ApiUrl <String>] [-Force] [<CommonParameters>]
```

## DESCRIPTION
The Get-XKCDExplanation cmdlet uses the explain xkcd wiki's MediaWiki API to retrieve a comic's
"Explanation" and "Transcript" sections, and its reader "Discussion" (from its explain xkcd talk page),
returning them as plain text, with the wiki markup used by the site stripped out for readability.
All
three are always included on the returned object, as its Explanation, Transcript, and Discussion
properties.

With -Show (or on Show-XKCDExplanation), -Explanation, -Transcript, and -Discussion each display just
that one section -- e.g.
-Show -Transcript on its own displays just the transcript, not the explanation.
Combine them to display more than one, or use -Full to always display all three.
Each displayed section
is given its own heading.
These switches only affect what's displayed; the returned object always has
all three.

With -Show, -Explanation, -Transcript, and -Discussion (without -Full) display text sections only,
without fetching or showing the comic image -- the title and a link to the explanation are still shown.
Use -Full with -Show to always display the comic image alongside every section.

By default, Get-XKCDExplanation returns the explanation of the latest available comic.
Use -Random to
get a random comic instead (optionally within a -Min/-Max range), or -Newest to get the specified
number of most recent comics.
Use the -Num parameter to specify one or more specific comics to return.

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
Get-XKCDExplanation -Random -Min 100 -Max 150
```

This command returns the explanation of a random comic numbered between 100 and 150.

### EXAMPLE 5
```
Get-XKCDExplanation -Newest 5
```

This command returns the explanation of the latest 5 comics.

### EXAMPLE 6
```
(Get-XKCDExplanation 2000).Transcript
```

This command returns just the transcript of comic number 2000.
The Explanation, Transcript, and
Discussion properties are always populated, so no switches are needed to retrieve them.

### EXAMPLE 7
```
Get-XKCDExplanation -Num 1 -Full -Show
```

This command displays the title, image, explanation, transcript, and discussion of comic number 1
directly in the console, each under its own heading (image display requires your terminal to support
the Sixel, Kitty, or iTerm2 inline image protocol).
Unlike other parameter combinations, -Show does not
return the explanation object.

### EXAMPLE 8
```
Get-XKCDExplanation -Num 1 -Explanation -Show
```

This command displays just the explanation of comic number 1 as text, along with its title and a link,
without fetching or displaying the comic image.

### EXAMPLE 9
```
Get-XKCDExplanation -Open
```

This command returns the explanation of the latest comic and opens it in your default web browser.

## PARAMETERS

### -Random
Gets the explanation of a random comic.

```yaml
Type: SwitchParameter
Parameter Sets: Random
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Min
Use with -Random to define a lower bound range within which to return a comic.

```yaml
Type: Int32
Parameter Sets: Random
Aliases:

Required: False
Position: Named
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```

### -Max
Use with -Random to define an upper bound range within which to return a comic.
-Max is the latest comic number by default.

```yaml
Type: Int32
Parameter Sets: Random
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Newest
Gets the explanation of the specified number of the most recent comics.

```yaml
Type: Int32
Parameter Sets: Newest
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Open
Opens the comic/s in your default web browser.

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

### -Explanation
Use with -Show to display the comic's "Explanation" section.
Combine with -Transcript and/or
-Discussion to display more than one section.
The returned object always includes it regardless of
this switch.
Defaults to the value saved with Set-XKCDDefault -Explanation, if any.

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
Use with -Show to display the comic's "Transcript" section.
Combine with -Explanation and/or
-Discussion to display more than one section.
The returned object always includes it regardless of
this switch.
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
Use with -Show to display the comic's reader "Discussion", from its explain xkcd talk page.
Combine
with -Explanation and/or -Transcript to display more than one section.
The returned object always
includes it regardless of this switch.
Defaults to the value saved with Set-XKCDDefault -Discussion,
if any.

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

### -Num
Gets the explanation of the specified comics.
Accepts array input.
By default the latest comic is used.

```yaml
Type: Int32[]
Parameter Sets: Specific
Aliases:

Required: False
Position: 1
Default value: $Max
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Force
Bypass the confirmation check if you try to open more than 9 comics in your browser.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[https://www.explainxkcd.com/wiki/index.php/Main_Page](https://www.explainxkcd.com/wiki/index.php/Main_Page)

