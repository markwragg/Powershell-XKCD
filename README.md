# Powershell-XKCD

![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/9qnefark9fl1gctj?svg=true) ![Test Coverage](https://img.shields.io/badge/coverage-31%25-red.svg?build=1.4.55)

A PowerShell function for accessing the XKCD API to get the details of and (optionally) download the excellent webcomics @ http://xkcd.com.
## XKCD

XKCD is a webcomic by Randall Munroe. Please respect the license of his work as described here: http://xkcd.com/license.html.

## Requirements

- The API provided by xkcd.com must be functional: https://xkcd.com/json.html
- This script requires PowerShell 3.0 or above.

## Installation

This module is published in the PowerShell Gallery as [XKCD](https://www.powershellgallery.com/packages/XKCD/1.4.36.0) so if you have PowerShell 5 or the Package Management modules, it can be installed by entering the following in a PowerShell window:

```
Install-Module -Name XKCD
```

## Usage Examples

1) `Get-XKCD`

By default (and with no specified parameters) the function will return a PowerShell object with the details of the latest webcomic. For example:

```
month      : 1
num        : 1786
link       : 
year       : 2017
news       : 
safe_title : Trash
transcript : 
alt        : Plus, time's all weird in there, so most of it probably broke down and decomposed hundreds of years ago. Which reminds me, I've been meaning to get in touch 
             with Yucca Mountain to see if they're interested in a partnership.
img        : http://imgs.xkcd.com/comics/trash.png
title      : Trash
day        : 16
```

2) `Get-XKCD 1` or `Get-XKCD -num 1`

Specify the number of specifc comic/s you want to access via the -num parameter (this is a positional parameter so it doesn't need to be explicitly used).

3) `Get-XKCD -Random` or `Get-XKCD -Random -Min 1 -Max 10`

Use the -Random switch to get a Random comic. Optionally specify Min and Max if you want to restrict the randomisation to a specific range of comic numbers.

4) `Get-XKCD -Newest 5`

Use the -Newest switch to get a specified number of the newest comics. Note this cannot be used with -Random (and vice versa).

5) `Get-XKCD 1,5,10` or `10..20 | Get-XKCD`

The number paramater accepts array input and pipeline input, so you can use either to return a specific selection in one hit.

6) `Get-XKCD -Download` or `Get-XKCD 1337 -Download -Path C:\XKCD`

Use the -Download switch to download the image/s of the returned comics. Optionally specify a path to download to, by default it uses the current directory. Note you can use -Download and -Path with any of the other parameters.

7) `1..10 | % { Get-XKCD -Random -min 1 -max 100 | select num,img } | FT -AutoSize`

This calls Get-XKCD 10 times in a foreach loop, returning the number and image URL of 10 random comics from the first 100 comics and presenting them as an autosized table.

## Contributions

Code contrbutions and pull requests are welcomed. Please note this function is also intended to represent a (hopefully) best practice example of a cmdlet which respects the pipeline and an example of how to utilise Parameter Sets to provide a dynamic set of functionality.
