# Change Log

## !Deploy

* `Get-XKCDExplanation` now only fetches the "Transcript" and "Discussion" sections (an extra API call each) when `-Transcript`, `-Discussion`, or `-Full` is specified, matching what `-Show` already displays -- the "Explanation" is still always retrieved. Sections that aren't requested are omitted from the returned object entirely, rather than being included empty. Previously all three were always fetched and returned regardless of the switches used.

## [1.6.1] - 2026-08-28

* `Show-XKCDExplanation` now displays the comic's alt text underneath its image, matching `Show-XKCD`.
* Adds an `-Explanation` switch to `Get-XKCDExplanation` and `Show-XKCDExplanation`. `-Explanation`, `-Transcript`, and `-Discussion` now each display exactly the section(s) requested -- e.g. `-Transcript` on its own displays just the transcript, not the explanation -- as text only, without fetching or showing the comic image; the title and a link to the explanation are still shown. Use `-Full` to always display all three sections alongside the comic image.
* The "Explanation" section heading is now always shown, even when it's the only section displayed.
* Adds `-Random` (`-Min`/`-Max`), `-Newest`, and `-Open`/`-Force` parameters to `Get-XKCDExplanation`, matching `Get-XKCD`.
* Adds an `-Explanation` preference to `Set-XKCDDefault`, alongside the existing `-Transcript`, `-Discussion`, and `-Full`.

## [1.6.0] - 2026-08-28

* Adds a new `Get-XKCDExplanation` cmdlet, which retrieves a comic's "Explanation", "Transcript", and reader "Discussion" (from its explain xkcd talk page) via the [explain xkcd](https://www.explainxkcd.com/) wiki's MediaWiki API, with wiki markup stripped for readability. All three are always included on the returned object.
* Adds a new `Show-XKCDExplanation` cmdlet (and a `-Show` switch on `Get-XKCDExplanation`) to display a comic's title, a hyperlink to its explain xkcd page, publish date, a hyperlink to it, image, and explanation in the console, with `-Transcript`, `-Discussion`, and `-Full` switches to also display the transcript and/or discussion, each under its own heading. Discussion messages show reply nesting as indentation and highlight each message's signature. Bold and italic text is rendered as such, code formatting in the explanation (including plain indented code samples) is highlighted, and links -- external, to other explain xkcd pages, and to Wikipedia/what-if.xkcd.com articles referenced via wiki templates -- are rendered as working hyperlinks on the linked words themselves, without printing the url.
* Adds a new `Test-XKCD` cmdlet to check how many new comics have been published since the last one viewed via `Show-XKCD` or `Get-XKCD -Show`, with `-Quiet`, `-Detailed`, and `-WhatIf` support.
* Adds new `Set-XKCDDefault` and `Get-XKCDDefault` cmdlets to save and inspect default preferences (`-HighQuality`, `-Path`, `-FullSearch`, `-CachePath`, `-StatePath`) used automatically by other cmdlets in the module, so common parameters no longer need repeating on every call.
* `Show-XKCD`'s title is now bold, underlined, and coloured for better visibility, and the console output now also includes the comic's publish date and a hyperlink to it on xkcd.com.

## [1.5.3] - 2026-08-27

* Fixes VS Code image detection: `WT_SESSION` (set by Windows Terminal) is now checked after `TERM_PROGRAM -eq 'vscode'` rather than before, since `WT_SESSION` can be inherited into VS Code's integrated terminal (e.g. when VS Code itself is launched from within a Windows Terminal session) and was previously suppressing the one-time "enable terminal.integrated.enableImages" warning.

## [1.5.2] - 2026-08-27

* Adds a new `Get-XKCDCache` cmdlet to query the local comic cache directly (optionally filtered by `-Num`), without hitting the XKCD API for each comic. It warns if the cache is missing or out of date rather than refreshing it automatically -- run `Update-XKCDCache` to do that.
* `Show-XKCD` and `Get-XKCD -Show` can now render images in VS Code's integrated terminal, which supports the Sixel protocol via its `terminal.integrated.enableImages` setting. A one-time warning is shown if that setting doesn't appear to be enabled. Fixes [#10]((https://github.com/markwragg/Powershell-XKCD/issues/10). Thanks [@GJPearl](https://github.com/GJPearl)!

## [1.5.1] - 2026-08-27

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
