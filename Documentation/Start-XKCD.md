# Start-XKCD

## SYNOPSIS
Opens a full-screen terminal interface for browsing XKCD comics -- a TUI parody of https://xkcd.com/.

## SYNTAX

### Specific (Default)
```
Start-XKCD [[-Number] <Int32>] [-HighQuality] [-StatePath <String>] [-Offline] [-CachePath <String>]
 [-DownloadPath <String>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Random
```
Start-XKCD [-Random] [-Minimum <Int32>] [-Maximum <Int32>] [-HighQuality] [-StatePath <String>] [-Offline]
 [-CachePath <String>] [-DownloadPath <String>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
The Start-XKCD cmdlet opens an interactive, full-screen view of a comic (its title, image, and alt
text, framed by an ASCII art "xkcd" banner, with a control bar shown both above and below the image)
and lets you browse the archive without leaving it:

- G prompts for a comic number to jump straight to.
- F displays the first comic (#1).
- P or the left arrow displays the previous comic (does nothing at comic #1).
- R displays a random comic from the full archive.
- N or the right arrow displays the next comic (does nothing once you reach the latest comic).
- L displays the latest comic.
- Q or Escape exits back to your normal console.

The image is only rendered if your terminal supports the Sixel, Kitty, or iTerm2 inline image graphics
protocol; otherwise you'll still see the rest and can keep browsing.
As with Show-XKCD, each comic you
view updates the local state file also used by Get-XKCD/Show-XKCD's -Next/-Previous and by Test-XKCD,
so stepping out of Start-XKCD leaves you exactly where Show-XKCD -Next would pick back up.

By default, Start-XKCD opens on the latest available comic.
Use -Number to open on a specific comic
instead (accepts pipeline input, e.g.
from Get-XKCD), or -Random to open on a random comic -- optionally
bounded by -Minimum/-Maximum (aliased -Min/-Max).

Use -Offline to browse using data from the local cache (created/refreshed by Update-XKCDCache) and
images previously saved with Get-XKCD -Download, instead of fetching either from the xkcd API -- this
also governs which comic counts as "latest" for the default starting comic, the right arrow boundary,
and R.
If a comic's image hasn't been downloaded to -DownloadPath yet, a warning is shown and that
comic's frame is displayed without an image, rather than stopping you from continuing to browse.
Defaults to the value saved with Set-XKCDDefault -Offline, if any.

## EXAMPLES

### EXAMPLE 1
```
Start-XKCD
```

Opens the interactive viewer on the latest comic.

### EXAMPLE 2
```
Start-XKCD 2000
```

Opens the interactive viewer on comic number 2000.

### EXAMPLE 3
```
Start-XKCD -Random
```

Opens the interactive viewer on a random comic from the full archive.

### EXAMPLE 4
```
Start-XKCD -Random -Minimum 100 -Maximum 150
```

Opens the interactive viewer on a random comic numbered between 100 and 150.

### EXAMPLE 5
```
Get-XKCD -Random | Start-XKCD
```

Opens the interactive viewer on a random comic retrieved via Get-XKCD, passed in via the pipeline.

### EXAMPLE 6
```
Start-XKCD -HighQuality
```

Opens the interactive viewer, rendering the higher resolution (_2x) version of each comic's image
where available.

### EXAMPLE 7
```
Start-XKCD -Offline
```

Opens the interactive viewer using the local cache and previously downloaded images, instead of
fetching either from the xkcd API.

## PARAMETERS

### -Number
Opens the interactive viewer on the specified comic.
By default it opens on the latest comic.
Accepts
pipeline input, e.g.
from Get-XKCD.

```yaml
Type: Int32
Parameter Sets: Specific
Aliases: Num

Required: False
Position: 1
Default value: 0
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Random
Opens the interactive viewer on a random comic from the full archive, optionally bounded by
-Minimum/-Maximum.

```yaml
Type: SwitchParameter
Parameter Sets: Random
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Minimum
Use with -Random to define a lower bound within which to pick a comic.
Defaults to 1.

```yaml
Type: Int32
Parameter Sets: Random
Aliases: Min

Required: False
Position: Named
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```

### -Maximum
Use with -Random to define an upper bound within which to pick a comic.
Defaults to the latest comic
number (or the latest cached comic number, with -Offline).

```yaml
Type: Int32
Parameter Sets: Random
Aliases: Max

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -HighQuality
Renders the higher resolution (_2x) version of each comic's image, where available.
Comics that do
not have a higher resolution version are rendered at the standard quality instead.
Defaults to the
value saved with Set-XKCDDefault -HighQuality, if any.

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
Path to the file used to track the number of the most recently viewed comic (used by Test-XKCD and
by Get-XKCD/Show-XKCD's -Next/-Previous).
By default this is in the user's per-user data directory
(~/.xkcd), unless a default has been saved with Set-XKCDDefault -StatePath.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: (Get-XKCDDefaultValue -Name 'StatePath' -Value (Get-XKCDUserDataPath -FileName 'XKCD.state.json' -LegacyDirectory $PSScriptRoot))
Accept pipeline input: False
Accept wildcard characters: False
```

### -Offline
Browses comic data from the local cache, and renders each comic's image from a copy previously
saved with Get-XKCD -Download, instead of fetching either from the xkcd API.
Shows a warning and
displays the comic without an image if it hasn't been downloaded to -DownloadPath yet.
Defaults to
the value saved with Set-XKCDDefault -Offline, if any.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: (Get-XKCDDefaultValue -Name 'Offline' -Value $false)
Accept pipeline input: False
Accept wildcard characters: False
```

### -CachePath
Use with -Offline to specify where comic data is cached.
By default this is within the module path,
unless a default has been saved with Set-XKCDDefault -CachePath.

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

### -DownloadPath
Use with -Offline to specify the local directory to look for previously downloaded comic images in
(as saved by Get-XKCD -Download).
By default this is the current working directory, unless a
default has been saved with Set-XKCDDefault -Path.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: (Get-XKCDDefaultValue -Name 'Path' -Value $PWD)
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

[https://github.com/markwragg/Powershell-XKCD/wiki/Start-XKCD](https://github.com/markwragg/Powershell-XKCD/wiki/Start-XKCD)

[https://xkcd.com/json.html](https://xkcd.com/json.html)

