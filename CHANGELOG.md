# Change Log

## !Deploy

* `Find-XKCD` now accepts `-Query` from the pipeline and supports multiple queries in one call.
* Adds a `-FullSearch` switch to `Find-XKCD` to match against the whole comic object instead of just the title.
* `Find-XKCD` now tags each result with a `query` NoteProperty matching the search term, so results can be grouped or filtered by query.
* All XKCD API and web requests now use HTTPS.

## [1.5.0] - 2026-08-27

* Adds a new `Show-XKCD` cmdlet which displays a comic's title, image, and alt text directly in the console. The image is rendered inline if your terminal supports the Sixel, Kitty, or iTerm2 graphics protocol.
* Adds a `-Show` switch to `Get-XKCD` as a shorthand for `Get-XKCD | Show-XKCD`. Note that when `-Show` is used the comic object is not returned.
* `-HighQuality` now also applies when using `-Show` or `Show-XKCD`, displaying the higher resolution (_2x) version of the image where available.

## [1.4.82] - 2026-08-27

* Implements `-HighQuality` switch to download the high quality version of the image where available per Issue [#8](https://github.com/markwragg/Powershell-XKCD/issues/8). Thanks [@nlsdg](https://github.com/nlsdg)!
* Fixes download of image with incorrect extension per Issue [#9](https://github.com/markwragg/Powershell-XKCD/issues/9). Thanks [@nlsdg](https://github.com/nlsdg)!

## [1.4.81] - 2020-02-25

* Test deployment.

## [1.4.78] - 2019-03-26

* Adds a new `Update-XKCDCache` cmdlet to refresh the local comic cache used by `Find-XKCD`, including a `-CachePath` parameter and `-WhatIf`/`-Confirm` support. `Find-XKCD` now delegates its cache handling to it and also gains its own `-CachePath` parameter.

## [1.4.76] - 2019-03-26

* `Get-XKCD -Open` now prompts for confirmation before opening 10 or more comics in your browser; adds a `-Force` switch to bypass the prompt.

## [1.4.73] - 2019-03-25

* Adds an `-Open` switch to `Get-XKCD` to open the returned comic(s) in your default web browser.
* `Find-XKCD` results can now be piped directly into `Get-XKCD -Open`, e.g. `Find-XKCD -Query 'Spider' | Get-XKCD -Open`.

## [1.4.70] - 2019-03-21

* Adds a new `Find-XKCD` cmdlet, which searches comic titles against a local cache of the XKCD API (built automatically on first use, and refreshed if out of date), per Issue [#2](https://github.com/markwragg/Powershell-XKCD/issues/2).

## [1.4.67] - 2018-09-18

* `Get-XKCD`: `-Max` is now only resolved (which requires an extra API call) when actually needed, rather than on every invocation.
* `Get-XKCD`: `-Num` now also accepts values from the pipeline by property name.

## [1.4.66] - 2018-09-17

* Fixes module loading on non-Windows platforms (PowerShell Core) by using cross-platform path separators when importing functions.

## [1.4.52] - 2018-04-10

* Fixes the module manifest to correctly declare `RootModule`, which could otherwise prevent the module from loading correctly.

## [1.4.5] - 2017-01-21

* Initial release. Adds the `Get-XKCD` cmdlet to retrieve comic details from the XKCD API, with `-Random` (`-Min`/`-Max`), `-Newest`, and `-Num` parameter sets, plus a `-Download` switch (with `-Path`) to save the comic image locally.
