# Export-XKCDTerminalImage

## SYNOPSIS
Renders a comic using the current terminal's inline image graphics protocol (Sixel, Kitty, or iTerm2)
and saves the result to a file, so it can be redisplayed later with Import-XKCDTerminalImage.

## SYNTAX

```
Export-XKCDTerminalImage [[-Num] <Int32[]>] [-HighQuality] [-Path <String>] [-PassThru] [-Force] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The Export-XKCDTerminalImage cmdlet gets a comic and renders it exactly as Show-XKCD would -- using
whichever inline graphics protocol your terminal supports -- but instead of writing the result to the
console, it saves it to a file.
That file can later be redisplayed instantly with
Import-XKCDTerminalImage or Show-XKCD -Path, without needing network access or having to regenerate the
image data again (which for Sixel in particular can take a while for large images).

The saved file includes every field returned by Get-XKCD for the comic (num, title, alt, img, and so
on), alongside the rendered image, so it can also be used as a self-contained, offline copy of the
comic's full details.

Because the saved file contains a protocol-specific escape sequence, it's only guaranteed to display
correctly again in a terminal that supports the same graphics protocol it was exported with.
The saved
file records which protocol that was, and Import-XKCDTerminalImage and Show-XKCD -Path warn you if it
doesn't match the protocol detected for the terminal you're importing it into.

By default, Export-XKCDTerminalImage exports the latest available comic.
When you use the -Num
parameter you can specify one or more specific comics to export.

## EXAMPLES

### EXAMPLE 1
```
Export-XKCDTerminalImage
```

Exports the latest comic to the current working directory, e.g.
as '.\2000.xkcdterm.json'.

### EXAMPLE 2
```
Export-XKCDTerminalImage -Num 353 -Path C:\XKCD
```

Exports comic number 353 to C:\XKCD, as 'C:\XKCD\353.xkcdterm.json'.

### EXAMPLE 3
```
Get-XKCD -Newest 5 | Export-XKCDTerminalImage -Path C:\XKCD
```

Exports the 5 most recent comics to C:\XKCD.

### EXAMPLE 4
```
Export-XKCDTerminalImage -Num 353 -PassThru | Import-XKCDTerminalImage
```

Exports comic number 353 and immediately redisplays it from the saved file.

### EXAMPLE 5
```
Export-XKCDTerminalImage -Num 353 -Force
```

Re-exports comic number 353, overwriting '.\353.xkcdterm.json' if it already exists.
Without -Force,
Export-XKCDTerminalImage throws rather than overwrite an existing file.

## PARAMETERS

### -Num
Exports the specified comics.
Accepts array input.
By default the latest comic is exported.

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
Renders the higher resolution (_2x) version of the image, where available.
Comics that do not have a
higher resolution version are rendered at the standard quality instead.
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

### -Path
The local directory to save the exported file(s) to.
Each comic is saved as '\<num\>.xkcdterm.json'.
By
default this is the current working directory, unless a default has been saved with
Set-XKCDDefault -Path.

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

### -PassThru
Returns a FileInfo object for each file saved, e.g.
so it can be piped directly into
Import-XKCDTerminalImage.

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

### -Force
Overwrites the destination file if it already exists.
Without -Force, Export-XKCDTerminalImage throws
rather than overwrite an existing export.

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

