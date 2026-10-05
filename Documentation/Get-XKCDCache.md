# Get-XKCDCache

## SYNOPSIS
Returns the details of comics @ https://xkcd.com/ from the local cache.

## SYNTAX

```
Get-XKCDCache [[-Number] <Int32[]>] [-Year <Int32[]>] [-Month <Int32[]>] [-Day <Int32[]>] [-CachePath <String>]
 [-Raw] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Get-XKCDCache cmdlet returns comic data straight from the local cache, without querying the XKCD API
for each individual comic.
This makes it a much faster way to retrieve the details of comics that have
already been cached, and lets you use Where-Object, Sort-Object, Group-Object etc.
to query the whole set
of comics at once.

Unlike Find-XKCD, this cmdlet does not create or refresh the cache itself.
It only checks whether the
cache exists and is up to date, and warns you to run Update-XKCDCache if it isn't.

Each returned comic also has a 'date' property (a \[datetime\] combining day/month/year, so results can be
sorted or filtered by date), and 'html_img'/'html' properties, computed from those properties, for
embedding the comic in HTML output -- 'html_img' is just the \<img\> tag, and 'html' wraps that same tag in
a link to the comic's page on xkcd.com.
Comics are tagged with the 'XKCD.Comic' type name, so they pick
up the same curated list/table views as Get-XKCD -- a single comic as a list, several as a table.
Use
-Raw to omit these and get each comic exactly as cached.

## EXAMPLES

### EXAMPLE 1
```
Get-XKCDCache
```

Returns every comic in the local cache.

### EXAMPLE 2
```
Get-XKCDCache -Number 4,5,6
```

Returns comics 4, 5 and 6 from the local cache.

### EXAMPLE 3
```
4,5,6 | Get-XKCDCache
```

Returns comics 4, 5 and 6 from the local cache, specified via the pipeline.

### EXAMPLE 4
```
Get-XKCDCache | Where-Object year -eq 2010
```

Returns every comic published in 2010, by filtering the full local cache.

### EXAMPLE 5
```
Get-XKCDCache -Year 2010
```

Returns every comic published in 2010, equivalent to the previous example but filtered within the cache
instead of by Where-Object.

### EXAMPLE 6
```
Get-XKCDCache -Month 10 -Day 31
```

Returns every comic published on October 31st, of any year.

### EXAMPLE 7
```
Get-XKCDCache | Sort-Object -Property { $_.title.Length } -Descending | Select-Object -First 1 title
```

Returns the comic with the longest title.

### EXAMPLE 8
```
Get-XKCDCache -Raw
```

Returns every cached comic exactly as cached, without the 'date', 'html_img' or 'html' properties
Get-XKCDCache normally adds, and without the 'XKCD.Comic' type name that drives its table/list formatting.

## PARAMETERS

### -Number
Returns only the specified comic numbers from the cache.
Accepts array and pipeline input.
By default every
cached comic is returned.

```yaml
Type: Int32[]
Parameter Sets: (All)
Aliases: Num

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Year
Returns only comics published in the specified year(s).
By default comics from every year are returned.

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
Returns only comics published in the specified month(s) (1-12).
By default comics from every month are
returned.

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
Returns only comics published on the specified day(s) of the month.
By default comics from every day
are returned.

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

### -Raw
Returns each comic object exactly as cached, without the 'date', 'html_img' or 'html' properties
Get-XKCDCache normally adds, and without the 'XKCD.Comic' type name that drives its table/list
formatting.

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

[https://github.com/markwragg/Powershell-XKCD/wiki/Get-XKCDCache](https://github.com/markwragg/Powershell-XKCD/wiki/Get-XKCDCache)

[https://xkcd.com/json.html](https://xkcd.com/json.html)

