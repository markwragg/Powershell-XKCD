# Test-XKCD

## SYNOPSIS
Checks whether any new comics have been published since the last time Test-XKCD was run.

## SYNTAX

### Default (Default)
```
Test-XKCD [-Quiet] [-Detailed] [-StatePath <String>] [<CommonParameters>]
```

### Num
```
Test-XKCD [-Num] <Int32> [<CommonParameters>]
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

Use -Num to instead test whether a specific numbered comic exists, returning $true or $false.

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
Test-XKCD -Num 999999
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

## PARAMETERS

### -Num
Tests whether the specified comic number exists, returning $true or $false.
When used, no other
parameters are considered.

```yaml
Type: Int32
Parameter Sets: Num
Aliases:

Required: True
Position: 1
Default value: 0
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
By default this is within the module path, unless a default has been saved with
Set-XKCDDefault -StatePath.

```yaml
Type: String
Parameter Sets: Default
Aliases:

Required: False
Position: Named
Default value: (Get-XKCDDefaultValue -Name 'StatePath' -Value (Join-Path $PSScriptRoot 'XKCD.state.json'))
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

