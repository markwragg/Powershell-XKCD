# Change Log

## [1.7.3] - 2026-09-01

* Fixes `-HighQuality` on `Show-XKCD`, `Show-XKCDExplanation`, and `Export-XKCDTerminalImage` having no visible effect in terminals using the Sixel graphics protocol -- the higher resolution `_2x` source image was fetched but then downscaled straight back to the same 640px cap used for standard quality, so it always displayed at the same size. Sixel rendering now uses an 800px cap when `-HighQuality` is specified, so the extra resolution is actually visible on screen. Kitty and iTerm2 were unaffected, as neither is downscaled to a fixed width.

## [1.7.2] - 2026-08-30

* Fixes the published module missing its comic cache (`XKCD.json`) since moving to publishing a single combined psm1 file.

## [1.7.1] - 2026-08-30

* Fixes the deploy pipeline so it actually publishes the combined single-file module built by the `CombineFunctionsAndStage` build task, rather than always silently falling back to the uncombined source. A psake `Properties` variable referenced in `deploy.psdeploy.ps1` was never visible there, since `Invoke-PSDeploy` dot-sources that file from inside PSDeploy's own module function scope, which module boundaries keep separate from psake's -- so every previous release was published from source regardless of whether `CombineFunctionsAndStage` had run.

## [1.7.0] - 2026-08-30

* Adds new `Export-XKCDTerminalImage` and `Import-XKCDTerminalImage` cmdlets. `Export-XKCDTerminalImage` renders a comic using whichever inline graphics protocol your terminal supports (Sixel, Kitty, or iTerm2) and saves it to a file -- alongside every field `Get-XKCD` returns for that comic -- so it can be redisplayed instantly later without needing network access or having to regenerate the image again (which for Sixel in particular can take a while for large images). Throws if the destination file already exists; use `-Force` to overwrite it. `Import-XKCDTerminalImage` writes the saved image from an exported file straight to the console, warning (but still displaying it) if the saved graphics protocol doesn't match the one detected for the current terminal.
* Adds a `-Path` parameter to `Show-XKCD` to display the full comic -- title, image, and alt text -- from a file previously saved with `Export-XKCDTerminalImage`, instead of fetching it from the xkcd API. Accepts pipeline input, including directly from `Export-XKCDTerminalImage -PassThru` or `Get-ChildItem`.

## [1.6.4] - 2026-08-29

* Adds an `-Explain` switch to `Get-XKCD`, to display a comic's explanation via `Show-XKCDExplanation` instead of returning the comic object, without needing to call `Show-XKCDExplanation` separately.

## [1.6.3] - 2026-08-29

* Adds `-Next` and `-Previous` parameters to `Get-XKCD` and `Show-XKCD`, to get/display the comic after or before the one most recently displayed (in either direction) via `Show-XKCD` or `Get-XKCD -Show`, as tracked in a new `LastRead` record in the state file -- kept separate from the `LastViewed` high-water mark `Test-XKCD` uses to report new comics, so paging backward with `-Previous` doesn't affect that count. Returns/displays nothing (rather than throwing) if there's no comic before #1 or after the latest comic.
* Comics rendered via the Sixel graphics protocol (used by `Show-XKCD`, `Get-XKCD -Show`, and `Show-XKCDExplanation`) now show a warning first if the image is large enough that rendering may take a noticeable while, since the per-pixel conversion cost scales with image size.
* Adds a `-Num` parameter to `Test-XKCD` to test whether a specific numbered comic exists, returning `$true` or `$false`, instead of checking for new comics against the local state file.

## [1.6.2] - 2026-08-29

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
