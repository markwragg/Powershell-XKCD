# Powershell-XKCD
A PowerShell function for accessing the XKCD API to get the details of and (optionally) download the excellent webcomics @ http://xkcd.com.

##XKCD 
XKCD is a webcomic by Randall Munroe. Please respect the license of his work as described here: http://xkcd.com/license.html.

##Requirements
- The API provided by xkcd.com must be functional: https://xkcd.com/json.html
- This script requires PowerShell 3.0 or above.

##Usage Examples

`Get-XKCD`

By default the function will return a PowerShell object with the details of the latest webcomic. For example:

`Get-XKCD 1` or `Get-XKCD -num 1`

Specify the number of a specifc comic you want to access va the -num parameter (this is a positional parameter so it doesn't need to be explicitly used).

`Get-XKCD -Random` or `Get-XKCD -Random -Min 1 -Max 10`

Use the -Random switch to get a Random comic. Optionally specify Min and Max if you want to restrict the randomisation to a specific range of comic numbers.

`Get-XKCD -Newest 5`

Use the -Newest switch to get a specified number of the newest comics. Note this cannot be used with -Random (and vice versa).

`Get-XKCD 1,5,10` or `10..20 | Get-XKCD`

The number paramater accepts array input and pipeline input, so you can use either to return a specific selection in one hit.

`Get-XKCD -Download` or `Get-XKCD 1337 -Download -Path C:\XKCD`

Use the -Download switch to download the image/s of the returned comics. Optionally specify a path to download to, by default it uses the current directory. Note you can use -Download and -Path with any of the other parameters.

`1..10 | % { Get-XKCD -Random -min 1 -max 100 | select num,img } | FT -AutoSize`

This calls Get-XKCD 10 times in a foreach loop, returning the number and image URL of 10 random comics from the first 100 comics and presenting them as an autosized table.

## Contributions

Code contrbutions and pull requests are welcomed. Please note this function is also intended to represent a (hopefully) best practice example of a cmdlet which respects the pipeline and an example of how to utilise Parameter Sets to provide a dynamic set of functionality.
