# Import-XKCDTerminalImage

## SYNOPSIS
Redisplays a comic's image from a file previously saved with Export-XKCDTerminalImage.

## SYNTAX

```
Import-XKCDTerminalImage [-Path] <String[]> [<CommonParameters>]
```

## DESCRIPTION
The Import-XKCDTerminalImage cmdlet reads a file saved by Export-XKCDTerminalImage and writes its saved
terminal graphics escape sequence straight to the console, without needing network access or having to
regenerate the image data again.

The saved file records which inline graphics protocol (Sixel, Kitty, or iTerm2) it was rendered for.
Import-XKCDTerminalImage warns you if that doesn't match the protocol detected for the terminal you're
importing it into, since the image may not display correctly in that case.

## EXAMPLES

### EXAMPLE 1
```
Import-XKCDTerminalImage -Path .\2000.xkcdterm.json
```

Displays the terminal image previously saved to '.\2000.xkcdterm.json'.

### EXAMPLE 2
```
Get-ChildItem C:\XKCD\*.xkcdterm.json | Import-XKCDTerminalImage
```

Displays every terminal image saved in C:\XKCD.

### EXAMPLE 3
```
Export-XKCDTerminalImage -Num 353 -PassThru | Import-XKCDTerminalImage
```

Exports comic number 353 and immediately redisplays it from the saved file.

## PARAMETERS

### -Path
Path to one or more files previously saved with Export-XKCDTerminalImage.
Accepts array and pipeline
input, including FileInfo objects (e.g.
from Get-ChildItem or Export-XKCDTerminalImage -PassThru).

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: FullName

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
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

