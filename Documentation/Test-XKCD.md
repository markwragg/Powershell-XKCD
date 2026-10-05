# Test-XKCD

## SYNOPSIS
Checks whether any new comics have been published since the last time Test-XKCD was run.

## SYNTAX

### Default (Default)
```
Test-XKCD [-Quiet] [-Detailed] [-StatePath <String>] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### Number
```
Test-XKCD [-Number] <Int32> [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### AddToProfile
```
Test-XKCD [-AddToProfile] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### RemoveFromProfile
```
Test-XKCD [-RemoveFromProfile] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The Test-XKCD cmdlet compares the latest comic number available from the XKCD API against a local
record of the most recently viewed comic (updated by Show-XKCD and Get-XKCD -Show), and reports
whether any new comics are available.
Test-XKCD only reads this record -- it never updates it.

By default it writes a friendly message to the console stating how many new comics are available and
the publish date of the latest one, if that date can be determined.
Use -Quiet to suppress this message
and instead return a boolean.
Use -Detailed to return a PSCustomObject describing how many new comics
are available, alongside the last viewed and latest comic numbers.

Use -Number to instead test whether a specific numbered comic exists, returning $true or $false.

Use -AddToProfile to add \`if (Test-XKCD -Quiet) { Test-XKCD }\` to your PowerShell profile (creating it,
and its containing directory, if either doesn't already exist), so new comics are reported automatically
whenever you open a new session.
Does nothing if that line is already present.
Use -RemoveFromProfile to
remove it again -- does nothing if the profile doesn't exist or doesn't contain that line.

## EXAMPLES

### EXAMPLE 1
```
Test-XKCD
```

Writes a friendly message to the console stating how many new comics are available (if any) and the
publish date of the latest one, where determinable.

### EXAMPLE 2
```
Test-XKCD -Quiet
```

Returns $true if new comics are available since the last check, otherwise $false, without writing a
message to the console.

### EXAMPLE 3
```
Test-XKCD -Detailed
```

Returns a PSCustomObject detailing whether new comics are available, how many, and the last viewed vs latest comic numbers.

### EXAMPLE 4
```
Test-XKCD -Number 999999
```

Returns $true if comic #999999 exists, otherwise $false.

### EXAMPLE 5
```
if (Test-XKCD -Quiet) { Test-XKCD }
```

If new comics are available, this will write a friendly message to the console stating how many new comics are available
(if any) and the publish date of the latest one, where determinable.

Add this to your PowerShell profile.ps1 to have it run automatically when you open a new session and prompt you only when new
comics are available.

### EXAMPLE 6
```
Test-XKCD -AddToProfile
```

Adds \`if (Test-XKCD -Quiet) { Test-XKCD }\` to your PowerShell profile, creating the profile file (and its
containing directory) if it doesn't already exist.
Does nothing if that line is already present.

### EXAMPLE 7
```
Test-XKCD -RemoveFromProfile
```

Removes \`if (Test-XKCD -Quiet) { Test-XKCD }\` from your PowerShell profile, if it's there.
Does nothing
if the profile doesn't exist or doesn't contain that line.

## PARAMETERS

### -Number
Tests whether the specified comic number exists, returning $true or $false.
When used, no other
parameters are considered.

```yaml
Type: Int32
Parameter Sets: Number
Aliases: Num

Required: True
Position: 1
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -AddToProfile
Adds \`if (Test-XKCD -Quiet) { Test-XKCD }\` to your PowerShell profile (creating it, and its containing
directory, if either doesn't already exist), so new comics are reported automatically whenever you
open a new session.
Does nothing if that line is already present.

```yaml
Type: SwitchParameter
Parameter Sets: AddToProfile
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -RemoveFromProfile
Removes \`if (Test-XKCD -Quiet) { Test-XKCD }\` (and, if present immediately above it, the comment
-AddToProfile adds) from your PowerShell profile.
Does nothing if the profile doesn't exist or doesn't
contain that line.

```yaml
Type: SwitchParameter
Parameter Sets: RemoveFromProfile
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Quiet
Suppresses the friendly console message and instead returns a boolean.

```yaml
Type: SwitchParameter
Parameter Sets: Default
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Detailed
Returns a detailed PSCustomObject describing how many new comics are available, instead of a boolean or console message.

```yaml
Type: SwitchParameter
Parameter Sets: Default
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -StatePath
Path to the file that tracks the number of the most recently viewed comic (written by Show-XKCD and
Get-XKCD -Show).
By default this is in the user's per-user data directory (~/.xkcd), unless a default
has been saved with Set-XKCDDefault -StatePath.

```yaml
Type: String
Parameter Sets: Default
Aliases:

Required: False
Position: Named
Default value: (Get-XKCDDefaultValue -Name 'StatePath' -Value (Get-XKCDUserDataPath -FileName 'XKCD.state.json' -LegacyDirectory $PSScriptRoot))
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

[https://xkcd.com/json.html](https://xkcd.com/json.html)

