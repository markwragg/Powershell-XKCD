# Set-XKCDDefault

## SYNOPSIS
Sets default preferences used automatically by other cmdlets in this module, such as whether to use
high quality images by default.

## SYNTAX

```
Set-XKCDDefault [-HighQuality] [[-Path] <String>] [-FullSearch] [[-CachePath] <String>] [[-StatePath] <String>]
 [-Explanation] [-Transcript] [-Discussion] [-Full] [-Reset] [[-DefaultsPath] <String>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
The Set-XKCDDefault cmdlet saves default preferences that are then used automatically by other cmdlets
in this module, so you don't need to specify the same parameters every time.
Explicitly specifying a
parameter on a cmdlet (e.g.
Get-XKCD -HighQuality:$false) always overrides the saved default.

Only the preferences you specify are changed -- any others already saved are left as they are.
Use
-Reset to remove all saved preferences and restore the module's built-in behavior.

Supported preferences:

-HighQuality  Default for -HighQuality on Get-XKCD, Show-XKCD, Get-XKCDExplanation, Show-XKCDExplanation and Export-XKCDTerminalImage.
-Path         Default download directory for Get-XKCD -Download, and default save directory for Export-XKCDTerminalImage.
-FullSearch   Default for -FullSearch on Find-XKCD.
-CachePath    Default comic data cache location for Update-XKCDCache, Get-XKCDCache and Find-XKCD.
-StatePath    Default location of the most-recently-viewed record for Show-XKCD, Get-XKCD -Show and Test-XKCD.
-Explanation  Default for -Explanation on Get-XKCDExplanation and Show-XKCDExplanation.
-Transcript   Default for -Transcript on Get-XKCDExplanation and Show-XKCDExplanation.
-Discussion   Default for -Discussion on Get-XKCDExplanation and Show-XKCDExplanation.
-Full         Default for -Full on Get-XKCDExplanation and Show-XKCDExplanation.

## EXAMPLES

### EXAMPLE 1
```
Set-XKCDDefault -HighQuality
```

Makes Get-XKCD, Show-XKCD, Get-XKCDExplanation and Show-XKCDExplanation use high quality images by default.

### EXAMPLE 2
```
Set-XKCDDefault -Path C:\XKCD
```

Makes Get-XKCD -Download save images to C:\XKCD by default.

### EXAMPLE 3
```
Set-XKCDDefault -Full
```

Makes Get-XKCDExplanation and Show-XKCDExplanation retrieve the explanation, transcript, and discussion by default.

### EXAMPLE 4
```
Set-XKCDDefault -HighQuality:$false
```

Explicitly saves -HighQuality as disabled by default, overriding a previously saved value.

### EXAMPLE 5
```
Set-XKCDDefault -Reset
```

Removes all saved default preferences.

## PARAMETERS

### -HighQuality
Sets the default for -HighQuality, used by Get-XKCD, Show-XKCD, Get-XKCDExplanation, Show-XKCDExplanation
and Export-XKCDTerminalImage.

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
Sets the default download directory used by Get-XKCD -Download, and the default save directory used by
Export-XKCDTerminalImage.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FullSearch
Sets the default for -FullSearch, used by Find-XKCD.

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
Sets the default comic data cache location used by Update-XKCDCache, Get-XKCDCache and Find-XKCD.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -StatePath
Sets the default location of the most-recently-viewed record used by Show-XKCD, Get-XKCD -Show and Test-XKCD.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Explanation
Sets the default for -Explanation, used by Get-XKCDExplanation and Show-XKCDExplanation.

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

### -Transcript
Sets the default for -Transcript, used by Get-XKCDExplanation and Show-XKCDExplanation.

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

### -Discussion
Sets the default for -Discussion, used by Get-XKCDExplanation and Show-XKCDExplanation.

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

### -Full
Sets the default for -Full, used by Get-XKCDExplanation and Show-XKCDExplanation.

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

### -Reset
Removes all saved default preferences, restoring the module's built-in behavior.

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

### -DefaultsPath
Path to the file used to store default preferences.
By default this is within the module path.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: (Join-Path $PSScriptRoot 'XKCD.defaults.json')
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

