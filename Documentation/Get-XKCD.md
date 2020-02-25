# Get-XKCD

## SYNOPSIS
Gets the details of the comics @ http://xkcd.com/.
Optionally can download the comic images.

## SYNTAX

### Specific (Default)
```
Get-XKCD [-Download] [-Open] [-Path <String>] [[-Num] <Int32[]>] [-Force] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### Random
```
Get-XKCD [-Random] [-Min <Int32>] [-Max <Int32>] [-Download] [-Open] [-Path <String>] [-Force] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### Newest
```
Get-XKCD [-Newest <Int32>] [-Download] [-Open] [-Path <String>] [-Force] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
The Get-XKCD cmdlet gets the details of one or more comics from the XKCD API: https://xkcd.com/json.html.
This includes title, number, image URL, alt text, day, month, year, news, safe_title and transcript.

By default, Get-XKCD returns the details of the latest available comic.
When you use the -num parameter
you can specify one or more specific comics to return.

## EXAMPLES

### EXAMPLE 1
```
Get-XKCD
```

This command gets the details of the latest XKCD comic from the API such as the title, number, image URL and alt text.

### EXAMPLE 2
```
Get-XKCD 42
```

This command returns the details of the 42nd XKCD comic.

### EXAMPLE 3
```
Get-XKCD -Random
```

This command returns the details of a random XKCD comic from the set of all available comics.

### EXAMPLE 4
```
Get-XKCD -Random -Min 100 -Max 150
```

This command returns a random comic that is numbered between 100 and 150.

### EXAMPLE 5
```
Get-XKCD -Newest 5
```

This command returns the details of the latest 5 comics.

### EXAMPLE 6
```
Get-XKCD -Download
```

This command returns the details of the latest comic and downloads the comic image to the current working directory.

### EXAMPLE 7
```
Get-XKCD (1..10) -Download -Path C:\Comics
```

This command returns the details of comic numbers 1 to 10 and downloads each comics image to C:\Comics.

### EXAMPLE 8
```
1..10 | % { Get-XKCD -Random | select num,img } | FT -AutoSize
```

This command returns the details of 10 random comics from the set of all comics and displays the number and image URL of those comics as an autosized table.

## PARAMETERS

### -Random
Gets a random comic.

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
Gets the specified number of the most recent comics.

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

### -Download
Downloads the images of all returned comics to the local computer.

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

### -Open
Opens the comic/s in your default web browser

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

### -Path
Use with -Download to specify a local directory to download to.
By default this is the current working directory.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $PWD
Accept pipeline input: False
Accept wildcard characters: False
```

### -Num
Gets the specified comics.
Accepts array input.

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

