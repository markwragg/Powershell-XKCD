# Find-XKCD

## SYNOPSIS
Retrieves the details of comics @ https://xkcd.com/ based on whether a specified search string appears
in the title text (by default).
To search for a specified string in the full text of the comic data,
use the -FullSearch switch.

## SYNTAX

```
Find-XKCD [-Query] <String[]> [-Or <String[]>] [-And <String[]>] [-Not <String[]>] [-Year <Int32[]>]
 [-Month <Int32[]>] [-Day <Int32[]>] [-FullSearch] [-Raw] [-CachePath <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Find-XKCD cmdlet creates a local cache of the XKCD API comic data if one is not found to already
exist.
It also refreshes the local cache if it's found to be out of date.
Comic searches are then
performed against the local cache.

-Query accepts more than one search string.
A comic matches if it contains ANY of them, or any of the
-Or terms (-Query and -Or are simply two ways of building the same "match any of these" group -- -Or
exists so you can add alternatives without crowding the primary -Query list).
If -And is also given, a
comic must additionally contain ALL of those terms to match.
If -Not is also given, a comic must
additionally contain NONE of those terms to match, e.g.
\`Find-XKCD -Query 'Spider' -Not 'Man'\` returns
comics with 'Spider' in the title, excluding any that also have 'Man' in it.

Each resulting comic object is tagged with a NoteProperty called 'query' -- specifically, every term
that was actually part of why that comic matched: whichever -Query/-Or term(s) it matched (joined with
', ' if more than one), plus any -And terms (since all of those are required to be present, they're
always part of the reason it matched too).
-Not terms are never included, since they describe what must
be absent, not why a comic matched.

-Year, -Month and -Day further restrict matches to comics published in the given year(s), month(s)
(1-12) and/or day(s) of the month -- a comic must match one of each that's specified, alongside the
text search above, e.g.
\`Find-XKCD -Query 'Spider' -Year 2010,2011\` returns comics with 'Spider' in
the title published in 2010 or 2011.

Each returned comic also has a 'date' property (a \[datetime\] combining day/month/year, so results can be
sorted or filtered by date), and 'html_img'/'html' properties, computed from those properties, for
embedding the comic in HTML output -- 'html_img' is just the \<img\> tag, and 'html' wraps that same tag in
a link to the comic's page on xkcd.com.
Use -Raw to omit these and get each comic exactly as cached
(still tagged with 'query').

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

### EXAMPLE 5
```
Find-XKCD -Query 'Spider','Robot'
```

Returns any comics with the word 'Spider' OR 'Robot' in the title, in a single combined result set, each
tagged with whichever of the two it actually matched.
Piping the terms in separately instead
(\`'Spider','Robot' | Find-XKCD\`) returns the same comics tagged the same way, except a comic matching
both terms would appear twice (once per piped query) rather than once with 'query' set to 'Spider, Robot'.

### EXAMPLE 6
```
Find-XKCD -Query 'Time' -And 'Machine'
```

Returns any comics with both 'Time' AND 'Machine' in the title, each tagged with 'query' set to
'Time, Machine'.

### EXAMPLE 7
```
Find-XKCD -Query 'Spider' -Not 'Man'
```

Returns comics with 'Spider' in the title, excluding any that also have 'Man' in it.

### EXAMPLE 8
```
Find-XKCD -Query 'Spider' -Not 'Man','Egg'
```

Returns comics with 'Spider' in the title, excluding any that also have 'Man' OR 'Egg' in it.

### EXAMPLE 9
```
Find-XKCD -Query 'Spider' -Raw
```

Returns each matching comic exactly as cached, without the 'date', 'html_img' or 'html' properties
Find-XKCD normally adds (the 'query' property is still added).

### EXAMPLE 10
```
Find-XKCD -Query 'Spider' -Year 2010
```

Returns comics with 'Spider' in the title that were published in 2010.

### EXAMPLE 11
```
Find-XKCD -Query 'Spider' -Month 10 -Day 31
```

Returns comics with 'Spider' in the title that were published on October 31st of any year.

## PARAMETERS

### -Query
The search string(s) to find.
A comic matches if it contains any of these (or any of -Or).

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Or
Additional search string(s) to match, alongside -Query -- a comic matches if it contains any of
-Query OR any of these.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -And
Search string(s) that must ALL also be present for a comic to match, alongside -Query/-Or.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Not
Search string(s) that must NONE be present for a comic to match, alongside -Query/-Or/-And.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Year
Restricts matches to comics published in the specified year(s), alongside the text search.

```yaml
Type: Int32[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Month
Restricts matches to comics published in the specified month(s) (1-12), alongside the text search.

```yaml
Type: Int32[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Day
Restricts matches to comics published on the specified day(s) of the month, alongside the text search.

```yaml
Type: Int32[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FullSearch
Search the full text of the comic data, not just the title.
Defaults to the value saved with
Set-XKCDDefault -FullSearch, if any.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: (Get-XKCDDefaultValue -Name 'FullSearch' -Value $false)
Accept pipeline input: False
Accept wildcard characters: False
```

### -Raw
Returns each matching comic object exactly as cached, without the 'date', 'html_img' or 'html'
properties Find-XKCD normally adds, and without the 'XKCD.Comic'/'XKCD.Comic.Search' type names that
drive its table/list formatting.
The 'query' property is still added.

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

### -ProgressAction
{{Fill ProgressAction Description}}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

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

[https://github.com/markwragg/Powershell-XKCD/wiki/Find-XKCD](https://github.com/markwragg/Powershell-XKCD/wiki/Find-XKCD)

[https://xkcd.com/json.html](https://xkcd.com/json.html)

